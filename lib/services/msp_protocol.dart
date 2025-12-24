import 'dart:typed_data';

class MSPPacket {
  final int commandId;
  final List<int> data;
  final bool isRequest; // true for request (<), false for response (>)
  
  MSPPacket({
    required this.commandId,
    List<int>? data,
    this.isRequest = true,
  }) : data = data ?? [];
  
  // Build request packet
  Uint8List toBytes() {
    final packet = <int>[];
    
    // Header
    packet.add(0x24); // '$'
    packet.add(0x4D); // 'M'
    packet.add(isRequest ? 0x3C : 0x3E); // '<' or '>'
    
    // Data size
    packet.add(data.length);
    
    // Command ID
    packet.add(commandId);
    
    // Data payload
    packet.addAll(data);
    
    // Calculate checksum
    int checksum = data.length ^ commandId;
    for (int byte in data) {
      checksum ^= byte;
    }
    packet.add(checksum);
    
    return Uint8List.fromList(packet);
  }
  
  // Parse response packet
  factory MSPPacket.fromBytes(Uint8List bytes) {
    if (bytes.length < 6) {
      throw Exception('Packet too short');
    }
    
    // Check header
    if (bytes[0] != 0x24 || bytes[1] != 0x4D) {
      throw Exception('Invalid packet header');
    }
    
    // Check direction (should be '>' for response)
    if (bytes[2] != 0x3E) {
      throw Exception('Invalid packet direction');
    }
    
    int dataSize = bytes[3];
    int commandId = bytes[4];
    
    if (bytes.length < 6 + dataSize) {
      throw Exception('Packet incomplete');
    }
    
    // Extract data
    List<int> data = bytes.sublist(5, 5 + dataSize).toList();
    
    // Verify checksum
    int checksum = bytes[5 + dataSize];
    int calcChecksum = dataSize ^ commandId;
    for (int byte in data) {
      calcChecksum ^= byte;
    }
    
    if (checksum != calcChecksum) {
      throw Exception('Checksum mismatch');
    }
    
    return MSPPacket(
      commandId: commandId,
      data: data,
      isRequest: false,
    );
  }
}

class MSPProtocol {
  // Build request packet
  static Uint8List buildRequest(int commandId, {List<int>? data}) {
    final packet = MSPPacket(
      commandId: commandId,
      data: data,
      isRequest: true,
    );
    return packet.toBytes();
  }
  
  // Parse response packet
  static MSPPacket? parseResponse(Uint8List bytes) {
    try {
      return MSPPacket.fromBytes(bytes);
    } catch (e) {
      return null;
    }
  }
  
  // Helper: Pack uint16 (little-endian)
  static List<int> packU16(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }
  
  // Helper: Pack int16 (little-endian, two's complement)
  static List<int> packS16(int value) {
    if (value < 0) {
      value = value + 0x10000;
    }
    return [value & 0xFF, (value >> 8) & 0xFF];
  }
  
  // Helper: Pack float (as int32 × 1000, little-endian)
  static List<int> packFloat(double value) {
    int scaled = (value * 1000).round();
    return [
      scaled & 0xFF,
      (scaled >> 8) & 0xFF,
      (scaled >> 16) & 0xFF,
      (scaled >> 24) & 0xFF,
    ];
  }
  
  // Helper: Unpack uint16 (little-endian)
  static int unpackU16(List<int> data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }
  
  // Helper: Unpack int16 (little-endian, two's complement)
  static int unpackS16(List<int> data, int offset) {
    int value = data[offset] | (data[offset + 1] << 8);
    if (value & 0x8000 != 0) {
      value = value - 0x10000;
    }
    return value;
  }
  
  // Helper: Unpack float (from int32 × 1000, little-endian)
  static double unpackFloat(List<int> data, int offset) {
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
}

