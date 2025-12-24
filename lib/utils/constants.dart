// MSP Command IDs
class MSPCommands {
  static const int mspIdent = 100;
  static const int mspStatus = 101;
  static const int mspRawImu = 102;
  static const int mspMotor = 104;
  static const int mspRc = 105;
  static const int mspAttitude = 108;
  static const int mspAnalog = 110; // Battery voltage and current (if supported)
  static const int mspPid = 112;
  static const int mspCompGyro = 200;
  static const int mspSetPid = 202;
  static const int mspAccCalibration = 205;
  static const int mspSetMotor = 214;
  static const int mspEscMin = 241;
  static const int mspEscMax = 242;
  static const int mspMotorTest = 243;
  static const int mspMotorStop = 244;
  static const int mspMotorStatus = 245;
  static const int mspCalShow = 246;
  static const int mspVersion = 247;
  static const int mspEepromWrite = 250;
  static const int mspReset = 68;
}

// Serial Port Configuration
class SerialConfig {
  static const int baudRate = 115200;
  static const int dataBits = 8;
  static const int stopBits = 1;
}

// Timeouts (milliseconds)
class Timeouts {
  static const int standardCommand = 1200;
  static const int calibration = 2000;
  static const int reset = 1000;
}

// Motor Configuration
class MotorConfig {
  static const int minValue = 0;
  static const int maxValue = 1000;
  static const int motorCount = 4;
}

// RC Channel Configuration
class RCConfig {
  static const int minValue = 1000;
  static const int centerValue = 1500;
  static const int maxValue = 2000;
}

