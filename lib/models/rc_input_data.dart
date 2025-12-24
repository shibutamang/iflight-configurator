class RCInputData {
  int roll;
  int pitch;
  int throttle;
  int yaw;
  int aux1;
  int aux2;
  bool signalValid;
  
  RCInputData({
    this.roll = 1500,
    this.pitch = 1500,
    this.throttle = 1000,
    this.yaw = 1500,
    this.aux1 = 1000,
    this.aux2 = 1500,
    this.signalValid = false,
  });
  
  // Parse from MSP_RC response (16 bytes)
  factory RCInputData.fromBytes(List<int> data) {
    if (data.length < 16) {
      return RCInputData(signalValid: false);
    }
    
    int unpackU16(int offset) {
      return data[offset] | (data[offset + 1] << 8);
    }
    
    int roll = unpackU16(0);
    int pitch = unpackU16(2);
    int throttle = unpackU16(4);
    int yaw = unpackU16(6);
    int aux1 = unpackU16(8);
    int aux2 = unpackU16(10);
    
    // Check if signal is valid (all zeros means no signal)
    bool valid = roll != 0 || pitch != 0 || throttle != 0 || yaw != 0;
    
    return RCInputData(
      roll: roll,
      pitch: pitch,
      throttle: throttle,
      yaw: yaw,
      aux1: aux1,
      aux2: aux2,
      signalValid: valid,
    );
  }
}

