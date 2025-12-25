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
  Timer? _attitudeTimer;
  Timer? _statusTimer;
  int _statusCounter = 0;
  
  FlightControllerState get state => _state;
  
  FlightControllerProvider(this._serialService, this._commandService) {
    _startStatusUpdates();
  }
  
  void _startStatusUpdates() {
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
      // Silently handle errors
    } finally {
      _isUpdatingAttitude = false;
    }
  }
  
  Future<void> _updateOtherStatus() async {
    if (_isUpdatingStatus) return;
    _isUpdatingStatus = true;
    
    try {
      final status = await _commandService.getStatus();
      if (status != null) {
        _state = _state.copyWith(
          isArmed: status['isArmed'] as bool,
          motorTestMode: status['motorTestMode'] as bool,
          cycleTime: status['cycleTime'] as int,
          i2cErrors: status['i2cErrors'] as int,
          gyroHealthy: status['gyroHealthy'] as bool? ?? true,
          accHealthy: status['accHealthy'] as bool? ?? false,
          baroHealthy: status['baroHealthy'] as bool? ?? false,
          magHealthy: status['magHealthy'] as bool? ?? false,
        );
      }
      
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
      // Silently handle errors
    } finally {
      _isUpdatingStatus = false;
    }
  }
  
  Future<bool> connect(String portName) async {
    bool success = await _serialService.connect(portName);
    if (success) {
      _state = _state.copyWith(isConnected: true);
      await Future.delayed(const Duration(milliseconds: 200));
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
      final version = await _commandService.getVersion();
      if (version != null) {
        _state = _state.copyWith(firmwareVersion: version);
      }
      
      final status = await _commandService.getStatus();
      if (status != null) {
        _state = _state.copyWith(
          isArmed: status['isArmed'] as bool,
          motorTestMode: status['motorTestMode'] as bool,
          cycleTime: status['cycleTime'] as int,
          i2cErrors: status['i2cErrors'] as int,
          gyroHealthy: status['gyroHealthy'] as bool? ?? true,
          accHealthy: status['accHealthy'] as bool? ?? false,
          baroHealthy: status['baroHealthy'] as bool? ?? false,
          magHealthy: status['magHealthy'] as bool? ?? false,
        );
      }
      
      final battery = await _commandService.getBattery();
      if (battery != null) {
        _state = _state.copyWith(
          batteryVoltage: battery['voltage'] as double? ?? 0.0,
          batteryPercentage: battery['percentage'] as int? ?? 0,
        );
      }
      
      final attitude = await _commandService.getAttitude();
      if (attitude != null) {
        _state = _state.copyWith(
          roll: attitude['roll']!,
          pitch: attitude['pitch']!,
          yaw: attitude['yaw']!,
        );
      }
      
      final pidConfig = await _commandService.getPIDConfig();
      if (pidConfig != null) {
        _state = _state.copyWith(pidConfig: pidConfig);
      }
      
      final rcData = await _commandService.getRCData();
      if (rcData != null) {
        _state = _state.copyWith(rcData: rcData);
      }
      
      final motorStatus = await _commandService.getMotorStatus();
      if (motorStatus != null) {
        _state = _state.copyWith(motorStatus: motorStatus);
      }
      
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
    // Pause polling during calibration
    _attitudeTimer?.cancel();
    _statusTimer?.cancel();
    
    // Wait a moment for any in-flight commands to complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    bool success = await _commandService.calibrateGyro();
    
    // Resume polling
    _startStatusUpdates();
    
    if (success) {
      await refreshAll();
    }
    return success;
  }

  Future<bool> calibrateAccel() async {
    // Pause polling during calibration
    _attitudeTimer?.cancel();
    _statusTimer?.cancel();
    
    // Wait a moment for any in-flight commands to complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    bool success = await _commandService.calibrateAccel();
    
    // Resume polling
    _startStatusUpdates();
    
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
