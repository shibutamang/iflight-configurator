class PIDConfig {
  double rollP;
  double rollI;
  double rollD;
  
  double pitchP;
  double pitchI;
  double pitchD;
  
  double yawP;
  double yawI;
  double yawD;
  
  PIDConfig({
    this.rollP = 0.5,
    this.rollI = 0.03,
    this.rollD = 0.02,
    this.pitchP = 0.5,
    this.pitchI = 0.03,
    this.pitchD = 0.02,
    this.yawP = 0.6,
    this.yawI = 0.02,
    this.yawD = 0.0,
  });
  
  PIDConfig copyWith({
    double? rollP,
    double? rollI,
    double? rollD,
    double? pitchP,
    double? pitchI,
    double? pitchD,
    double? yawP,
    double? yawI,
    double? yawD,
  }) {
    return PIDConfig(
      rollP: rollP ?? this.rollP,
      rollI: rollI ?? this.rollI,
      rollD: rollD ?? this.rollD,
      pitchP: pitchP ?? this.pitchP,
      pitchI: pitchI ?? this.pitchI,
      pitchD: pitchD ?? this.pitchD,
      yawP: yawP ?? this.yawP,
      yawI: yawI ?? this.yawI,
      yawD: yawD ?? this.yawD,
    );
  }
  
  // Parse from MSP_PID response (36 bytes)
  factory PIDConfig.fromBytes(List<int> data) {
    if (data.length < 36) {
      return PIDConfig();
    }
    
    double unpackFloat(int offset) {
      int value = data[offset] |
          (data[offset + 1] << 8) |
          (data[offset + 2] << 16) |
          (data[offset + 3] << 24);
      // Handle signed int32
      if (value & 0x80000000 != 0) {
        value = value - 0x100000000;
      }
      return value / 1000.0;
    }
    
    return PIDConfig(
      rollP: unpackFloat(0),
      rollI: unpackFloat(4),
      rollD: unpackFloat(8),
      pitchP: unpackFloat(12),
      pitchI: unpackFloat(16),
      pitchD: unpackFloat(20),
      yawP: unpackFloat(24),
      yawI: unpackFloat(28),
      yawD: unpackFloat(32),
    );
  }
  
  // Convert to bytes for MSP_SET_PID (36 bytes)
  List<int> toBytes() {
    List<int> result = [];
    
    void packFloat(double value) {
      int scaled = (value * 1000).round();
      result.add(scaled & 0xFF);
      result.add((scaled >> 8) & 0xFF);
      result.add((scaled >> 16) & 0xFF);
      result.add((scaled >> 24) & 0xFF);
    }
    
    packFloat(rollP);
    packFloat(rollI);
    packFloat(rollD);
    packFloat(pitchP);
    packFloat(pitchI);
    packFloat(pitchD);
    packFloat(yawP);
    packFloat(yawI);
    packFloat(yawD);
    
    return result;
  }
}

