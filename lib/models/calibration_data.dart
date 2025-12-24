class CalibrationData {
  int gyroX;
  int gyroY;
  int gyroZ;
  int accelX;
  int accelY;
  int accelZ;
  DateTime? lastCalibrated;
  
  CalibrationData({
    this.gyroX = 0,
    this.gyroY = 0,
    this.gyroZ = 0,
    this.accelX = 0,
    this.accelY = 0,
    this.accelZ = 0,
    this.lastCalibrated,
  });
  
  // Parse from MSP_CAL_SHOW response (12 bytes)
  factory CalibrationData.fromBytes(List<int> data) {
    if (data.length < 12) {
      return CalibrationData();
    }
    
    int unpackS16(int offset) {
      int value = data[offset] | (data[offset + 1] << 8);
      if (value & 0x8000 != 0) {
        value = value - 0x10000;
      }
      return value;
    }
    
    return CalibrationData(
      gyroX: unpackS16(0),
      gyroY: unpackS16(2),
      gyroZ: unpackS16(4),
      accelX: unpackS16(6),
      accelY: unpackS16(8),
      accelZ: unpackS16(10),
      lastCalibrated: DateTime.now(),
    );
  }
}

