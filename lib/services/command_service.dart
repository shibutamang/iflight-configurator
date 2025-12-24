import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/pid_config.dart';
import '../models/rc_input_data.dart';
import '../models/motor_status.dart';
import '../models/calibration_data.dart';
import '../services/serial_service.dart';
import '../services/msp_protocol.dart';
import '../utils/constants.dart';

class CommandService {
  final SerialService _serialService;
  final StreamController<MSPPacket> _responseController = StreamController<MSPPacket>.broadcast();
  
  Stream<MSPPacket> get responseStream => _responseController.stream;
  
  // Buffer for incomplete packets
  final List<int> _buffer = [];
  
  CommandService(this._serialService) {
    _serialService.dataStream.listen(_handleIncomingData);
  }
  
  String _bytesToHex(Uint8List data, {int max = 32}) {
    final int len = data.length;
    final Iterable<int> slice = len > max ? data.take(max) : data;
    final String hex = slice.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    return len > max ? '$hex ... (len=$len)' : hex;
  }

  void _handleIncomingData(Uint8List data) {
    _buffer.addAll(data);
    if (kDebugMode) {
      print('[MSP] RX raw (${data.length} bytes): ${_bytesToHex(data)}');
    }
    
    // Prevent buffer overflow - clear if too large (indicates corruption)
    if (_buffer.length > 1024) {
      if (kDebugMode) {
        print('Buffer overflow detected, clearing buffer');
      }
      _buffer.clear();
      return;
    }
    
    // Try to parse complete packets
    int maxIterations = 100; // Prevent infinite loops
    int iterations = 0;
    
    while (_buffer.isNotEmpty && iterations < maxIterations) {
      iterations++;
      
      // Look for packet start
      int startIndex = _buffer.indexOf(0x24); // '$'
      if (startIndex == -1) {
        _buffer.clear();
        break;
      }
      
      // Remove data before packet start
      if (startIndex > 0) {
        _buffer.removeRange(0, startIndex);
      }
      
      // Need at least 6 bytes for a valid packet
      if (_buffer.length < 6) {
        break;
      }
      
      // Check for valid header
      if (_buffer[0] != 0x24 || _buffer[1] != 0x4D || _buffer[2] != 0x3E) {
        _buffer.removeAt(0);
        continue;
      }
      
      int dataSize = _buffer[3];
      
      // Validate data size (MSP max is 64 bytes)
      if (dataSize > 64) {
        // Invalid packet, skip header byte
        _buffer.removeAt(0);
        continue;
      }
      
      int packetLength = 6 + dataSize; // header(3) + size(1) + cmd(1) + data + checksum(1)
      
      if (_buffer.length < packetLength) {
        // Wait for more data
        break;
      }
      
      // Extract complete packet
      Uint8List packetBytes = Uint8List.fromList(_buffer.sublist(0, packetLength));
      _buffer.removeRange(0, packetLength);
      
      // Parse packet
      try {
        MSPPacket? packet = MSPProtocol.parseResponse(packetBytes);
        if (packet != null) {
          if (kDebugMode) {
          print('[MSP] Parsed response cmd=${packet.commandId}, data=${packet.data.length} bytes');
          }
          _responseController.add(packet);
        }
      } catch (e) {
        // Invalid packet, continue to next
        if (kDebugMode) {
          print('Failed to parse packet: $e');
        }
        continue;
      }
    }
    
    if (iterations >= maxIterations && kDebugMode) {
      print('Max iterations reached in packet parsing');
    }
  }
  
  Future<MSPPacket?> _sendCommand(int commandId, {List<int>? data, int timeoutMs = Timeouts.standardCommand}) async {
    if (!_serialService.isConnected) {
      return null;
    }
    
    // Build request
    Uint8List packetData = MSPProtocol.buildRequest(commandId, data: data);
    if (kDebugMode) {
      print('[MSP] TX cmd=$commandId, bytes=${packetData.length}: ${_bytesToHex(packetData)}');
    }

    bool writeSuccess = await _serialService.write(packetData);
    if (!writeSuccess) {
      if (kDebugMode) {
        print('[MSP] Write failed for cmd=$commandId');
      }
      return null;
    }
    if (kDebugMode) {
      print('[MSP] Sent command: $commandId');
    }

    // Wait for response
    final completer = Completer<MSPPacket?>();
    StreamSubscription? subscription;
    Timer? timeoutTimer;

    subscription = responseStream.listen((packet) {
      if (packet.commandId == commandId) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(packet);
        }
      }
    });

    timeoutTimer = Timer(Duration(milliseconds: timeoutMs), () {
      subscription?.cancel();
      if (!completer.isCompleted) {
        if (kDebugMode) {
          print('[MSP] Timeout waiting for command: $commandId');
        }
        completer.complete(null);
      }
    });

    return completer.future;
  }
  
  // Status Commands
  Future<String?> getVersion() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspVersion);
    if (response == null || response.data.length < 3) {
      return null;
    }
    return '${response.data[0]}.${response.data[1]}.${response.data[2]}';
  }
  
  Future<Map<String, dynamic>?> getStatus() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspStatus);
    if (response == null || response.data.length < 10) {
      return null;
    }
    
    int cycleTime = MSPProtocol.unpackU16(response.data, 0);
    int i2cErrors = MSPProtocol.unpackU16(response.data, 2);
    int sensorFlags = MSPProtocol.unpackU16(response.data, 4);
    
    // Parse sensor flags (bits indicate sensor presence)
    bool accPresent = (sensorFlags & 0x01) != 0;
    bool baroPresent = (sensorFlags & 0x02) != 0;
    bool magPresent = (sensorFlags & 0x04) != 0;
    
    // System flags (uint32)
    int systemFlags = response.data[6] |
        (response.data[7] << 8) |
        (response.data[8] << 16) |
        (response.data[9] << 24);
    
    bool isArmed = (systemFlags & 0x01) != 0;
    bool motorTestMode = (systemFlags & 0x02) != 0;
    
    return {
      'cycleTime': cycleTime,
      'i2cErrors': i2cErrors,
      'sensorFlags': sensorFlags,
      'isArmed': isArmed,
      'motorTestMode': motorTestMode,
      // Parsed sensor health
      'accHealthy': accPresent,
      'baroHealthy': baroPresent,
      'magHealthy': magPresent,
      // Gyro is always assumed present (required for flight)
      'gyroHealthy': true,
    };
  }
  
  Future<Map<String, double>?> getAttitude() async {
    // Use fast timeout for real-time attitude data
    MSPPacket? response = await _sendCommand(
      MSPCommands.mspAttitude, 
      timeoutMs: Timeouts.fastCommand,
    );
    if (response == null || response.data.length < 6) {
      return null;
    }
    
    int roll = MSPProtocol.unpackS16(response.data, 0);
    int pitch = MSPProtocol.unpackS16(response.data, 2);
    int yaw = MSPProtocol.unpackS16(response.data, 4);
    
    return {
      'roll': roll / 10.0, // Convert from 1/10 degrees to degrees
      'pitch': pitch / 10.0,
      'yaw': yaw / 10.0,
    };
  }
  
  // Battery Commands
  Future<Map<String, dynamic>?> getBattery() async {
    // Try MSP_ANALOG (110) - standard MultiWii/Betaflight command
    MSPPacket? response = await _sendCommand(MSPCommands.mspAnalog);
    if (response == null) {
      return null;
    }
    
    // MSP_ANALOG typically returns: voltage (uint8_t * 0.1V), current (uint16_t * 0.01A)
    // But check data length to handle different formats
    if (response.data.length >= 1) {
      // Voltage is typically first byte as uint8_t representing 0.1V increments
      int voltageRaw = response.data[0];
      double voltage = voltageRaw * 0.1; // Convert to volts
      
      // Calculate percentage (assuming 3S LiPo: 12.6V = 100%, 9.0V = 0%)
      // This is a rough estimate - adjust based on your battery configuration
      int percentage = _calculateBatteryPercentage(voltage);
      
      return {
        'voltage': voltage,
        'percentage': percentage,
      };
    }
    
    return null;
  }
  
  // Helper to calculate battery percentage from voltage
  // Assumes LiPo: 4.2V per cell (full) to 3.0V per cell (empty)
  int _calculateBatteryPercentage(double voltage) {
    if (voltage <= 0) return 0;
    
    // Estimate cell count based on voltage
    int cells = (voltage / 4.2).ceil();
    if (cells < 1) cells = 1;
    if (cells > 6) cells = 6;
    
    // Full voltage per cell: 4.2V, Empty: 3.0V
    double fullVoltage = cells * 4.2;
    double emptyVoltage = cells * 3.0;
    
    if (voltage >= fullVoltage) return 100;
    if (voltage <= emptyVoltage) return 0;
    
    // Linear interpolation
    double percentage = ((voltage - emptyVoltage) / (fullVoltage - emptyVoltage)) * 100;
    return percentage.round().clamp(0, 100);
  }
  
  // PID Commands
  Future<PIDConfig?> getPIDConfig() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspPid);
    if (response == null || response.data.length < 36) {
      return null;
    }
    return PIDConfig.fromBytes(response.data);
  }
  
  Future<bool> setPIDConfig(PIDConfig config) async {
    List<int> data = config.toBytes();
    MSPPacket? response = await _sendCommand(MSPCommands.mspSetPid, data: data);
    return response != null;
  }
  
  // RC Commands
  Future<RCInputData?> getRCData() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspRc);
    if (response == null || response.data.length < 16) {
      return null;
    }
    return RCInputData.fromBytes(response.data);
  }
  
  // Motor Commands
  Future<MotorStatus?> getMotorStatus() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspMotorStatus);
    if (response == null || response.data.length < 9) {
      return null;
    }
    return MotorStatus.fromBytes(response.data);
  }
  
  Future<bool> enterMotorTest() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspMotorTest);
    return response != null;
  }
  
  Future<bool> exitMotorTest() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspMotorStop);
    return response != null;
  }
  
  Future<bool> setMotorValues(List<int> values) async {
    if (values.length != 4) {
      return false;
    }
    MotorStatus status = MotorStatus(motorValues: values);
    List<int> data = status.toBytes();
    MSPPacket? response = await _sendCommand(MSPCommands.mspSetMotor, data: data);
    return response != null;
  }
  
  // Calibration Commands
  Future<bool> calibrateGyro() async {
    MSPPacket? response = await _sendCommand(
      MSPCommands.mspCompGyro,
      timeoutMs: Timeouts.calibration,
    );
    return response != null;
  }
  
  Future<bool> calibrateAccel() async {
    MSPPacket? response = await _sendCommand(
      MSPCommands.mspAccCalibration,
      timeoutMs: Timeouts.calibration,
    );
    return response != null;
  }
  
  Future<CalibrationData?> getCalibrationData() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspCalShow);
    if (response == null || response.data.length < 12) {
      return null;
    }
    return CalibrationData.fromBytes(response.data);
  }
  
  // System Commands
  Future<bool> saveConfiguration() async {
    MSPPacket? response = await _sendCommand(MSPCommands.mspEepromWrite);
    return response != null;
  }
  
  Future<bool> reset() async {
    MSPPacket? response = await _sendCommand(
      MSPCommands.mspReset,
      timeoutMs: Timeouts.reset,
    );
    return response != null;
  }
  
  void dispose() {
    _responseController.close();
  }
}
