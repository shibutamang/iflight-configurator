import 'pid_config.dart';
import 'calibration_data.dart';
import 'rc_input_data.dart';
import 'motor_status.dart';

class FlightControllerState {
  bool isConnected;
  bool isArmed;
  String firmwareVersion;
  
  double roll; // degrees
  double pitch; // degrees
  double yaw; // degrees
  
  PIDConfig pidConfig;
  RCInputData rcData;
  MotorStatus motorStatus;
  CalibrationData calibration;
  
  int cycleTime; // microseconds
  int i2cErrors;
  bool motorTestMode;
  
  // Battery and system status
  double batteryVoltage; // volts
  int batteryPercentage; // 0-100
  double cpuLoad; // percentage
  int freeHeap; // bytes
  double cpuTemperature; // celsius
  
  // Sensor health status
  bool gyroHealthy;
  bool accHealthy;
  bool magHealthy; // magnetometer/compass
  bool baroHealthy; // barometer
  bool gpsHealthy;
  int gpsNumSat; // number of GPS satellites
  bool rangefinderHealthy; // sonar/lidar
  
  FlightControllerState({
    this.isConnected = false,
    this.isArmed = false,
    this.firmwareVersion = 'Unknown',
    this.roll = 0.0,
    this.pitch = 0.0,
    this.yaw = 0.0,
    PIDConfig? pidConfig,
    RCInputData? rcData,
    MotorStatus? motorStatus,
    CalibrationData? calibration,
    this.cycleTime = 0,
    this.i2cErrors = 0,
    this.motorTestMode = false,
    this.batteryVoltage = 0.0,
    this.batteryPercentage = 0,
    this.cpuLoad = 0.0,
    this.freeHeap = 0,
    this.cpuTemperature = 0.0,
    this.gyroHealthy = false,
    this.accHealthy = false,
    this.magHealthy = false,
    this.baroHealthy = false,
    this.gpsHealthy = false,
    this.gpsNumSat = 0,
    this.rangefinderHealthy = false,
  })  : pidConfig = pidConfig ?? PIDConfig(),
        rcData = rcData ?? RCInputData(),
        motorStatus = motorStatus ?? MotorStatus(),
        calibration = calibration ?? CalibrationData();
  
  FlightControllerState copyWith({
    bool? isConnected,
    bool? isArmed,
    String? firmwareVersion,
    double? roll,
    double? pitch,
    double? yaw,
    PIDConfig? pidConfig,
    RCInputData? rcData,
    MotorStatus? motorStatus,
    CalibrationData? calibration,
    int? cycleTime,
    int? i2cErrors,
    bool? motorTestMode,
    double? batteryVoltage,
    int? batteryPercentage,
    double? cpuLoad,
    int? freeHeap,
    double? cpuTemperature,
    bool? gyroHealthy,
    bool? accHealthy,
    bool? magHealthy,
    bool? baroHealthy,
    bool? gpsHealthy,
    int? gpsNumSat,
    bool? rangefinderHealthy,
  }) {
    return FlightControllerState(
      isConnected: isConnected ?? this.isConnected,
      isArmed: isArmed ?? this.isArmed,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      yaw: yaw ?? this.yaw,
      pidConfig: pidConfig ?? this.pidConfig,
      rcData: rcData ?? this.rcData,
      motorStatus: motorStatus ?? this.motorStatus,
      calibration: calibration ?? this.calibration,
      cycleTime: cycleTime ?? this.cycleTime,
      i2cErrors: i2cErrors ?? this.i2cErrors,
      motorTestMode: motorTestMode ?? this.motorTestMode,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      cpuLoad: cpuLoad ?? this.cpuLoad,
      freeHeap: freeHeap ?? this.freeHeap,
      cpuTemperature: cpuTemperature ?? this.cpuTemperature,
      gyroHealthy: gyroHealthy ?? this.gyroHealthy,
      accHealthy: accHealthy ?? this.accHealthy,
      magHealthy: magHealthy ?? this.magHealthy,
      baroHealthy: baroHealthy ?? this.baroHealthy,
      gpsHealthy: gpsHealthy ?? this.gpsHealthy,
      gpsNumSat: gpsNumSat ?? this.gpsNumSat,
      rangefinderHealthy: rangefinderHealthy ?? this.rangefinderHealthy,
    );
  }
}

