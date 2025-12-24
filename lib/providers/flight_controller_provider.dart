import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/flight_controller_state.dart';
import '../models/pid_config.dart';
import '../models/motor_status.dart';
import '../services/serial_service.dart';
import '../services/command_service.dart';

class FlightControllerProvider extends ChangeNotifier {
  final SerialService _serialService;
  final CommandService _commandService;
  
  FlightControllerState _state = FlightControllerState();
  StreamSubscription? _statusSubscription;
  Timer? _attitudeTimer;  // Fast timer for attitude (smooth animation)
  Timer? _statusTimer;    // Slower timer for other status
  int _statusCounter = 0;
  
  FlightControllerState get state => _state;
  
  FlightControllerProvider(this._serialService, this._commandService) {
    _startStatusUpdates();
  }
  
  void _startStatusUpdates() {
    // Listen to command responses
    _commandService.responseStream.listen((packet) {
      // Handle specific responses if needed
    });
    
    // Fast attitude updates for smooth animation (every 50ms = 20 FPS)
    _attitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_state.isConnected && !_isUpdatingAttitude) {
        _updateAttitude();
      }
    });
    
    // Slower status updates for other data (every 500ms)
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_state.isConnected && !_isUpdatingStatus) {
        _updateOtherStatus();
      }
    });
  }
  
  bool _isUpdatingAttitude = false;
  bool _isUpdatingStatus = false;
  
  // Fast attitude update - called frequently for smooth animation
  Future<void> _updateAttitude() async {
    if (_isUpdatingAttitude) return;
    _isUpdatingAttitude = true;
    
    try {
      final attitude = await _commandService.getAttitude();
      if (attitude != null) {
        _state = _state.copyWith(
          roll: attitude['roll']!,
          pitch: attitude['pitch']!,
          yaw: attitude['yaw']!,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating attitude: $e');
      }
    } finally {
      _isUpdatingAttitude = false;
    }
  }
  
  // Slower status update - called less frequently
  Future<void> _updateOtherStatus() async {
    if (_isUpdatingStatus) return;
    _isUpdatingStatus = true;
    
    try {
      // Get status (includes sensor health)
      final status = await _commandService.getStatus();
      if (status != null) {
        _state = _state.copyWith(
          isArmed: status['isArmed'] as bool,
          motorTestMode: status['motorTestMode'] as bool,
          cycleTime: status['cycleTime'] as int,
          i2cErrors: status['i2cErrors'] as int,
          // Sensor health
          gyroHealthy: status['gyroHealthy'] as bool? ?? true,
          accHealthy: status['accHealthy'] as bool? ?? false,
          baroHealthy: status['baroHealthy'] as bool? ?? false,
          magHealthy: status['magHealthy'] as bool? ?? false,
        );
      }
      
      // Get battery (less frequent - every 4 status updates = ~2 seconds)
      if (_statusCounter % 4 == 0) {
        final battery = await _commandService.getBattery();
        if (battery != null) {
          _state = _state.copyWith(
            batteryVoltage: battery['voltage'] as double? ?? 0.0,
            batteryPercentage: battery['percentage'] as int? ?? 0,
          );
        }
      }
      _statusCounter++;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating status: $e');
      }
    } finally {
      _isUpdatingStatus = false;
    }
  }
  
  Future<bool> connect(String portName) async {
    bool success = await _serialService.connect(portName);
    if (success) {
      _state = _state.copyWith(isConnected: true);
      
      // Wait a bit for serial connection to stabilize
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Get initial data
      await refreshAll();
      
      notifyListeners();
    }
    return success;
  }
  
  Future<void> disconnect() async {
    await _serialService.disconnect();
    _state = _state.copyWith(isConnected: false);
    notifyListeners();
  }
  
  Future<void> refreshAll() async {
    if (!_state.isConnected) return;
    
    try {
      if (kDebugMode) {
        print('Refreshing all data from FC...');
      }
      
      // Get version
      if (kDebugMode) {
        print('Requesting firmware version...');
      }
      final version = await _commandService.getVersion();
      if (version != null) {
        if (kDebugMode) {
          print('Got firmware version: $version');
        }
        _state = _state.copyWith(firmwareVersion: version);
      } else {
        if (kDebugMode) {
          print('Failed to get firmware version');
        }
      }
      
      // Get status (includes sensor health)
      final status = await _commandService.getStatus();
      if (status != null) {
        _state = _state.copyWith(
          isArmed: status['isArmed'] as bool,
          motorTestMode: status['motorTestMode'] as bool,
          cycleTime: status['cycleTime'] as int,
          i2cErrors: status['i2cErrors'] as int,
          // Sensor health
          gyroHealthy: status['gyroHealthy'] as bool? ?? true,
          accHealthy: status['accHealthy'] as bool? ?? false,
          baroHealthy: status['baroHealthy'] as bool? ?? false,
          magHealthy: status['magHealthy'] as bool? ?? false,
        );
      }
      
      // Get battery
      final battery = await _commandService.getBattery();
      if (battery != null) {
        _state = _state.copyWith(
          batteryVoltage: battery['voltage'] as double? ?? 0.0,
          batteryPercentage: battery['percentage'] as int? ?? 0,
        );
      }
      
      // Get attitude
      final attitude = await _commandService.getAttitude();
      if (attitude != null) {
        _state = _state.copyWith(
          roll: attitude['roll']!,
          pitch: attitude['pitch']!,
          yaw: attitude['yaw']!,
        );
      }
      
      // Get PID config
      final pidConfig = await _commandService.getPIDConfig();
      if (pidConfig != null) {
        _state = _state.copyWith(pidConfig: pidConfig);
      }
      
      // Get RC data
      final rcData = await _commandService.getRCData();
      if (rcData != null) {
        _state = _state.copyWith(rcData: rcData);
      }
      
      // Get motor status
      final motorStatus = await _commandService.getMotorStatus();
      if (motorStatus != null) {
        _state = _state.copyWith(motorStatus: motorStatus);
      }
      
      // Get calibration data
      final calibration = await _commandService.getCalibrationData();
      if (calibration != null) {
        _state = _state.copyWith(calibration: calibration);
      }
      
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
  
  Future<bool> updatePIDConfig(PIDConfig config) async {
    bool success = await _commandService.setPIDConfig(config);
    if (success) {
      _state = _state.copyWith(pidConfig: config);
      await _commandService.saveConfiguration();
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> enterMotorTest() async {
    if (_state.isArmed) {
      return false;
    }
    bool success = await _commandService.enterMotorTest();
    if (success) {
      _state = _state.copyWith(motorTestMode: true);
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> exitMotorTest() async {
    bool success = await _commandService.exitMotorTest();
    if (success) {
      _state = _state.copyWith(motorTestMode: false);
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> setMotorValues(List<int> values) async {
    if (!_state.motorTestMode) {
      return false;
    }
    bool success = await _commandService.setMotorValues(values);
    if (success) {
      _state = _state.copyWith(
        motorStatus: MotorStatus(motorValues: values, testModeEnabled: true),
      );
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> calibrateGyro() async {
    bool success = await _commandService.calibrateGyro();
    if (success) {
      await refreshAll();
    }
    return success;
  }
  
  Future<bool> calibrateAccel() async {
    bool success = await _commandService.calibrateAccel();
    if (success) {
      await refreshAll();
    }
    return success;
  }
  
  Future<void> refreshRCData() async {
    final rcData = await _commandService.getRCData();
    if (rcData != null) {
      _state = _state.copyWith(rcData: rcData);
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _attitudeTimer?.cancel();
    _statusTimer?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}

