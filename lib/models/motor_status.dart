class MotorStatus {
  List<int> motorValues; // 0-1000 for each motor
  bool testModeEnabled;
  
  MotorStatus({
    List<int>? motorValues,
    this.testModeEnabled = false,
  }) : motorValues = motorValues ?? [0, 0, 0, 0];
  
  // Parse from MSP_MOTOR_STATUS response (9 bytes)
  factory MotorStatus.fromBytes(List<int> data) {
    if (data.length < 9) {
      return MotorStatus();
    }
    
    int unpackU16(int offset) {
      return data[offset] | (data[offset + 1] << 8);
    }
    
    List<int> values = [
      unpackU16(0), // Motor 1
      unpackU16(2), // Motor 2
      unpackU16(4), // Motor 3
      unpackU16(6), // Motor 4
    ];
    
    bool enabled = data[8] == 1;
    
    return MotorStatus(
      motorValues: values,
      testModeEnabled: enabled,
    );
  }
  
  // Parse from MSP_MOTOR response (16 bytes)
  factory MotorStatus.fromMotorBytes(List<int> data) {
    if (data.length < 16) {
      return MotorStatus();
    }
    
    int unpackU16(int offset) {
      return data[offset] | (data[offset + 1] << 8);
    }
    
    List<int> values = [
      unpackU16(0), // Motor 1
      unpackU16(2), // Motor 2
      unpackU16(4), // Motor 3
      unpackU16(6), // Motor 4
    ];
    
    return MotorStatus(
      motorValues: values,
      testModeEnabled: false, // Unknown from this command
    );
  }
  
  // Convert to bytes for MSP_SET_MOTOR (16 bytes)
  List<int> toBytes() {
    List<int> result = [];
    
    void packU16(int value) {
      result.add(value & 0xFF);
      result.add((value >> 8) & 0xFF);
    }
    
    for (int i = 0; i < 4; i++) {
      packU16(i < motorValues.length ? motorValues[i] : 0);
    }
    
    // Motors 5-8 (always 0)
    for (int i = 0; i < 4; i++) {
      packU16(0);
    }
    
    return result;
  }
}

