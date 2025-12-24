# MSP Protocol Specification
## iFlight Controller Configurator Development Guide

**Version:** 1.0.0  
**Date:** 2024  
**Protocol:** MultiWii Serial Protocol (MSP) v1

---

## Table of Contents

1. [Protocol Overview](#protocol-overview)
2. [Packet Format](#packet-format)
3. [Data Encoding](#data-encoding)
4. [Command Reference](#command-reference)
5. [Usage Examples](#usage-examples)
6. [Error Handling](#error-handling)
7. [Implementation Notes](#implementation-notes)

---

## Protocol Overview

The iFlight Controller uses the MultiWii Serial Protocol (MSP) v1 for communication with configurator tools. This binary protocol provides efficient, reliable communication for:

- Reading flight controller status and sensor data
- Configuring PID gains
- Calibrating sensors (gyro, accelerometer)
- Motor testing and ESC configuration
- System control (save, reset)

### Communication Parameters

- **Baud Rate:** 115200
- **Data Bits:** 8
- **Stop Bits:** 1
- **Parity:** None
- **Flow Control:** None

### Protocol Characteristics

- Binary protocol (not text-based)
- Little-endian byte order
- Checksum validation for data integrity
- Request/response model
- Maximum data payload: 64 bytes

---

## Packet Format

### Request Packet (Configurator → Flight Controller)

```
Byte 0:  '$' (0x24) - Header 1
Byte 1:  'M' (0x4D) - Header 2
Byte 2:  '<' (0x3C) - Direction (incoming)
Byte 3:  <data_size> - Data payload length (0-64)
Byte 4:  <command_id> - Command ID
Byte 5+: <data> - Data payload (if any)
Last:    <checksum> - XOR checksum
```

### Response Packet (Flight Controller → Configurator)

```
Byte 0:  '$' (0x24) - Header 1
Byte 1:  'M' (0x4D) - Header 2
Byte 2:  '>' (0x3E) - Direction (outgoing)
Byte 3:  <data_size> - Data payload length (0-64)
Byte 4:  <command_id> - Command ID (same as request)
Byte 5+: <data> - Data payload (if any)
Last:    <checksum> - XOR checksum
```

### Checksum Calculation

The checksum is calculated as:
```
checksum = data_size XOR command_id XOR data[0] XOR data[1] XOR ... XOR data[n-1]
```

For commands with no data payload:
```
checksum = data_size XOR command_id
```

### Packet Parsing State Machine

1. **IDLE** - Waiting for '$' (0x24)
2. **HEADER_START** - Received '$', waiting for 'M' (0x4D)
3. **HEADER_M** - Received 'M', waiting for '<' (0x3C) or '>' (0x3E)
4. **HEADER_DIR** - Received direction, reading data size
5. **HEADER_SIZE** - Received data size, reading command ID
6. **HEADER_CMD** - Received command ID, reading data payload (if size > 0)
7. **CHECKSUM** - Received all data, validating checksum

---

## Data Encoding

All multi-byte values are encoded in **little-endian** format (least significant byte first).

### Data Types

| Type | Size | Encoding | Example |
|------|------|----------|---------|
| `uint8_t` | 1 byte | Direct | `0x42` → `[0x42]` |
| `int8_t` | 1 byte | Direct (two's complement) | `-1` → `[0xFF]` |
| `uint16_t` | 2 bytes | Little-endian | `0x1234` → `[0x34, 0x12]` |
| `int16_t` | 2 bytes | Little-endian (two's complement) | `-1000` → `[0x18, 0xFC]` |
| `uint32_t` | 4 bytes | Little-endian | `0x12345678` → `[0x78, 0x56, 0x34, 0x12]` |
| `int32_t` | 4 bytes | Little-endian (two's complement) | `-1000000` → `[0x40, 0x42, 0x0F, 0xFF]` |
| `float` | 4 bytes | Scaled int32 (×1000), little-endian | `1.234` → `[0xD2, 0x04, 0x00, 0x00]` |

### Float Encoding

Floating-point values are transmitted as 32-bit signed integers scaled by 1000:

- **Encoding:** `int32_t value = (int32_t)(float_value * 1000.0f)`
- **Decoding:** `float value = (float)int32_value / 1000.0f`
- **Example:** `1.234` → `1234` → `[0xD2, 0x04, 0x00, 0x00]`

---

## Command Reference

### Standard Commands

#### MSP_IDENT (100)

**Description:** Get flight controller identifier and version information.

**Request:**
- Data size: 0
- Command: 100

**Response:**
- Data size: 4
- Data format:
  ```
  Byte 0: MultiWii version (uint8_t)
  Byte 1: MultiWii sub-version (uint8_t)
  Byte 2: MultiWii type (uint8_t) - 0 = MultiWii
  Byte 3: Capability flags (uint8_t)
  ```

**Example Response:**
```
$M> 04 64 F0 01 00 00 95
     ^  ^  ^  ^  ^  ^  ^
     |  |  |  |  |  |  checksum
     |  |  |  |  |  data[3] = 0x00
     |  |  |  |  data[2] = 0x00
     |  |  |  data[1] = 0x01
     |  |  data[0] = 0xF0
     |  command = 100
     data_size = 4
```

---

#### MSP_STATUS (101)

**Description:** Get system status including cycle time, I2C errors, sensor flags, and system flags.

**Request:**
- Data size: 0
- Command: 101

**Response:**
- Data size: 10
- Data format:
  ```
  Bytes 0-1:   Cycle time (uint16_t) - microseconds
  Bytes 2-3:   I2C errors (uint16_t)
  Bytes 4-5:   Sensor flags (uint16_t)
                 Bit 0: ACC present
                 Bit 1: BARO present
                 Bit 2: MAG present
  Bytes 6-9:   System flags (uint32_t)
                 Bit 0: Armed
                 Bit 1: Motor test mode
                 Bits 2-31: Reserved
  ```

**Example Response:**
```
$M> 0A 65 E8 03 00 00 07 00 01 00 00 00 8A
     ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
     |  |  |  |  |  |  |  |  |  |  |  |  checksum
     |  |  |  |  |  |  |  |  |  |  flags (armed)
     |  |  |  |  |  |  |  |  |  sensor_flags
     |  |  |  |  |  |  |  |  i2c_errors
     |  |  |  |  |  |  |  cycle_time (1000 us)
     |  |  |  |  |  |  command = 101
     |  |  |  |  |  data_size = 10
```

---

#### MSP_ATTITUDE (108)

**Description:** Get current attitude (roll, pitch, yaw angles).

**Request:**
- Data size: 0
- Command: 108

**Response:**
- Data size: 6
- Data format:
  ```
  Bytes 0-1: Roll angle (int16_t) - in 1/10 degrees
  Bytes 2-3: Pitch angle (int16_t) - in 1/10 degrees
  Bytes 4-5: Yaw angle (int16_t) - in 1/10 degrees
  ```

**Example Response (Roll: 5.0°, Pitch: -2.5°, Yaw: 180.0°):**
```
$M> 06 6C 32 00 06 FF 40 0B 7D
     ^  ^  ^  ^  ^  ^  ^  ^  ^
     |  |  |  |  |  |  |  |  checksum
     |  |  |  |  |  |  |  yaw = 2880 (180.0° * 10)
     |  |  |  |  |  |  pitch = -25 (-2.5° * 10)
     |  |  |  |  |  roll = 50 (5.0° * 10)
     |  |  |  |  |  command = 108
     |  |  |  |  data_size = 6
```

---

#### MSP_RC (105)

**Description:** Get RC channel values.

**Request:**
- Data size: 0
- Command: 105

**Response:**
- Data size: 16
- Data format:
  ```
  Bytes 0-1:   Channel 0 - Roll (uint16_t) - microseconds (1000-2000)
  Bytes 2-3:   Channel 1 - Pitch (uint16_t)
  Bytes 4-5:   Channel 2 - Throttle (uint16_t)
  Bytes 6-7:   Channel 3 - Yaw (uint16_t)
  Bytes 8-9:   Channel 4 - AUX1 (uint16_t)
  Bytes 10-11: Channel 5 - AUX2 (uint16_t)
  Bytes 12-13: Channel 6 - AUX3 (uint16_t) - Not used (1500)
  Bytes 14-15: Channel 7 - AUX4 (uint16_t) - Not used (1500)
  ```

**Note:** If no RC signal is present, all channels return 0.

---

#### MSP_MOTOR (104)

**Description:** Get current motor output values.

**Request:**
- Data size: 0
- Command: 104

**Response:**
- Data size: 16
- Data format:
  ```
  Bytes 0-1:   Motor 1 (uint16_t) - 0-1000
  Bytes 2-3:   Motor 2 (uint16_t)
  Bytes 4-5:   Motor 3 (uint16_t)
  Bytes 6-7:   Motor 4 (uint16_t)
  Bytes 8-15:  Motors 5-8 (uint16_t each) - Always 0
  ```

**Motor Mapping:**
- Motor 1 → ESC Channel 1 (Front-Left)
- Motor 2 → ESC Channel 0 (Front-Right)
- Motor 3 → ESC Channel 3 (Back-Right)
- Motor 4 → ESC Channel 2 (Back-Left)

---

#### MSP_RAW_IMU (102)

**Description:** Get raw IMU sensor data.

**Request:**
- Data size: 0
- Command: 102

**Response:**
- Data size: 18
- Data format:
  ```
  Bytes 0-1:   Accelerometer X (int16_t) - raw sensor value
  Bytes 2-3:   Accelerometer Y (int16_t)
  Bytes 4-5:   Accelerometer Z (int16_t)
  Bytes 6-7:   Gyroscope X (int16_t) - raw sensor value
  Bytes 8-9:   Gyroscope Y (int16_t)
  Bytes 10-11: Gyroscope Z (int16_t)
  Bytes 12-13: Magnetometer X (int16_t) - Always 0 (not available)
  Bytes 14-15: Magnetometer Y (int16_t) - Always 0
  Bytes 16-17: Magnetometer Z (int16_t) - Always 0
  ```

---

#### MSP_PID (112)

**Description:** Get current PID gains for all axes.

**Request:**
- Data size: 0
- Command: 112

**Response:**
- Data size: 36
- Data format:
  ```
  Bytes 0-3:   Roll P (float as int32 × 1000)
  Bytes 4-7:   Roll I (float as int32 × 1000)
  Bytes 8-11:  Roll D (float as int32 × 1000)
  Bytes 12-15: Pitch P (float as int32 × 1000)
  Bytes 16-19: Pitch I (float as int32 × 1000)
  Bytes 20-23: Pitch D (float as int32 × 1000)
  Bytes 24-27: Yaw P (float as int32 × 1000)
  Bytes 28-31: Yaw I (float as int32 × 1000)
  Bytes 32-35: Yaw D (float as int32 × 1000)
  ```

**Example Response (Roll P=1.5, Roll I=0.1, Roll D=0.05):**
```
$M> 24 70 D2 05 00 00 64 00 00 00 32 00 00 00 ...
     ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
     |  |  |  |  |  |  |  |  |  |  |  Roll D = 50 (0.05 × 1000)
     |  |  |  |  |  |  |  |  |  |  Roll I = 100 (0.1 × 1000)
     |  |  |  |  |  |  |  |  |  Roll P = 1500 (1.5 × 1000)
     |  |  |  |  |  |  |  |  command = 112
     |  |  |  |  |  |  |  data_size = 36
```

---

#### MSP_SET_PID (202)

**Description:** Set PID gains for all axes.

**Request:**
- Data size: 36
- Command: 202
- Data format: Same as MSP_PID response

**Response:**
- Data size: 0 (ACK)

**Note:** Configuration is automatically saved to flash after setting PID values.

---

### Calibration Commands

#### MSP_COMP_GYRO (200)

**Description:** Calibrate gyroscope. Keep quadcopter still during calibration.

**Request:**
- Data size: 0
- Command: 200

**Response:**
- Data size: 0 (ACK on success)

**Note:** Calibration takes approximately 1 second. Configuration is automatically saved.

---

#### MSP_ACC_CALIBRATION (205)

**Description:** Calibrate accelerometer. Keep quadcopter level during calibration.

**Request:**
- Data size: 0
- Command: 205

**Response:**
- Data size: 0 (ACK on success)

**Note:** Configuration is automatically saved after calibration.

---

#### MSP_CAL_SHOW (246)

**Description:** Get calibration offset values.

**Request:**
- Data size: 0
- Command: 246

**Response:**
- Data size: 12
- Data format:
  ```
  Bytes 0-1:   Gyro offset X (int16_t)
  Bytes 2-3:   Gyro offset Y (int16_t)
  Bytes 4-5:   Gyro offset Z (int16_t)
  Bytes 6-7:   Accel offset X (int16_t)
  Bytes 8-9:   Accel offset Y (int16_t)
  Bytes 10-11: Accel offset Z (int16_t)
  ```

---

### Motor Control Commands

#### MSP_MOTOR_TEST (243)

**Description:** Enter motor test mode. Disarms the flight controller and enables direct motor control.

**Request:**
- Data size: 0
- Command: 243

**Response:**
- Data size: 0 (ACK on success)

**Prerequisites:**
- Flight controller must be disarmed
- Props should be removed for safety

**Note:** Motor test mode must be enabled before using MSP_SET_MOTOR.

---

#### MSP_MOTOR_STOP (244)

**Description:** Exit motor test mode and stop all motors.

**Request:**
- Data size: 0
- Command: 244

**Response:**
- Data size: 0 (ACK)

---

#### MSP_SET_MOTOR (214)

**Description:** Set motor output values directly. Only works in motor test mode.

**Request:**
- Data size: 16
- Command: 214
- Data format:
  ```
  Bytes 0-1:   Motor 1 (uint16_t) - 0-1000
  Bytes 2-3:   Motor 2 (uint16_t)
  Bytes 4-5:   Motor 3 (uint16_t)
  Bytes 6-7:   Motor 4 (uint16_t)
  Bytes 8-15:  Motors 5-8 (uint16_t) - Ignored
  ```

**Response:**
- Data size: 0 (ACK on success)

**Note:** Command is ignored if motor test mode is not active.

---

#### MSP_MOTOR_STATUS (245)

**Description:** Get current motor values and test mode status.

**Request:**
- Data size: 0
- Command: 245

**Response:**
- Data size: 9
- Data format:
  ```
  Bytes 0-1:   Motor 1 (uint16_t)
  Bytes 2-3:   Motor 2 (uint16_t)
  Bytes 4-5:   Motor 3 (uint16_t)
  Bytes 6-7:   Motor 4 (uint16_t)
  Byte 8:      Motor test mode (uint8_t) - 1 = enabled, 0 = disabled
  ```

---

### ESC Configuration Commands

#### MSP_ESC_MIN (241)

**Description:** Set ESC minimum pulse width.

**Request:**
- Data size: 2
- Command: 241
- Data format:
  ```
  Bytes 0-1: Minimum pulse width (uint16_t) - microseconds (500-1500)
  ```

**Response:**
- Data size: 0 (ACK on success)

**Note:** Configuration is automatically saved and applied to ESCs.

---

#### MSP_ESC_MAX (242)

**Description:** Set ESC maximum pulse width.

**Request:**
- Data size: 2
- Command: 242
- Data format:
  ```
  Bytes 0-1: Maximum pulse width (uint16_t) - microseconds (1500-2500)
  ```

**Response:**
- Data size: 0 (ACK on success)

**Note:** Configuration is automatically saved and applied to ESCs.

---

### System Commands

#### MSP_VERSION (247)

**Description:** Get firmware version.

**Request:**
- Data size: 0
- Command: 247

**Response:**
- Data size: 3
- Data format:
  ```
  Byte 0: Major version (uint8_t)
  Byte 1: Minor version (uint8_t)
  Byte 2: Patch version (uint8_t)
  ```

**Example Response (v1.0.0):**
```
$M> 03 F7 01 00 00 F5
     ^  ^  ^  ^  ^  ^
     |  |  |  |  |  checksum
     |  |  |  |  patch = 0
     |  |  |  minor = 0
     |  |  major = 1
     |  command = 247
     data_size = 3
```

---

#### MSP_EEPROM_WRITE (250)

**Description:** Save current configuration to flash memory.

**Request:**
- Data size: 0
- Command: 250

**Response:**
- Data size: 0 (ACK on success)

---

#### MSP_RESET (68)

**Description:** Reset the flight controller.

**Request:**
- Data size: 0
- Command: 68

**Response:**
- Data size: 0 (ACK)

**Note:** Flight controller will reset approximately 100ms after sending ACK.

---

## Usage Examples

### Example 1: Read Flight Controller Version

**Request:**
```
$M< 00 F7 00
```

**Response:**
```
$M> 03 F7 01 00 00 F5
```

**Parsing:**
- Version: 1.0.0

---

### Example 2: Read Attitude

**Request:**
```
$M< 00 6C 6C
```

**Response:**
```
$M> 06 6C 32 00 06 FF 40 0B 7D
```

**Parsing:**
- Roll: 50 (5.0°)
- Pitch: -25 (-2.5°)
- Yaw: 2880 (180.0°)

---

### Example 3: Set PID Gains

**Request (Set Roll P=1.5, Roll I=0.1, Roll D=0.05):**
```
$M< 24 CA D2 05 00 00 64 00 00 00 32 00 00 00 ...
    ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
    |  |  |  |  |  |  |  |  |  |  |  Roll D = 50
    |  |  |  |  |  |  |  |  |  |  Roll I = 100
    |  |  |  |  |  |  |  |  |  Roll P = 1500
    |  |  |  |  |  |  |  |  command = 202
    |  |  |  |  |  |  |  data_size = 36
```

**Response:**
```
$M> 00 CA CA
```

---

### Example 4: Motor Test Sequence

**Step 1: Enter Motor Test Mode**
```
Request:  $M< 00 F3 F3
Response: $M> 00 F3 F3
```

**Step 2: Set Motor 1 to 500 (50% throttle)**
```
Request:  $M< 10 D6 F4 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
Response: $M> 00 D6 D6
```

**Step 3: Stop All Motors**
```
Request:  $M< 00 F4 F4
Response: $M> 00 F4 F4
```

---

## Error Handling

### Checksum Errors

If a packet is received with an invalid checksum, it is silently discarded. The configurator should implement timeout handling for missing responses.

### Invalid Commands

Unknown commands receive an ACK response (data size 0) but no action is taken.

### Invalid Data

Commands with invalid data ranges or formats are ignored:
- **MSP_ESC_MIN:** Values outside 500-1500 are rejected
- **MSP_ESC_MAX:** Values outside 1500-2500 are rejected
- **MSP_SET_MOTOR:** Ignored if motor test mode is not active
- **MSP_MOTOR_TEST:** Ignored if flight controller is armed

### Timeout Handling

The configurator should implement timeout handling:
- **Recommended timeout:** 500ms for standard commands
- **Calibration timeout:** 2000ms (calibration takes ~1 second)
- **Reset timeout:** 1000ms (controller resets after ~100ms)

### Retry Logic

If no response is received:
1. Wait for timeout
2. Retry up to 3 times
3. If still no response, report connection error

---

## Implementation Notes

### Packet Construction

**Python Example:**
```python
def build_msp_packet(command_id, data=None):
    if data is None:
        data = []
    
    data_size = len(data)
    packet = bytearray()
    packet.append(0x24)  # '$'
    packet.append(0x4D)  # 'M'
    packet.append(0x3C)  # '<'
    packet.append(data_size)
    packet.append(command_id)
    packet.extend(data)
    
    # Calculate checksum
    checksum = data_size ^ command_id
    for byte in data:
        checksum ^= byte
    packet.append(checksum)
    
    return bytes(packet)
```

### Packet Parsing

**Python Example:**
```python
def parse_msp_response(data):
    if len(data) < 6:
        return None
    
    if data[0] != 0x24 or data[1] != 0x4D or data[2] != 0x3E:
        return None
    
    data_size = data[3]
    command_id = data[4]
    
    if len(data) < 6 + data_size:
        return None
    
    payload = data[5:5+data_size]
    checksum = data[5+data_size]
    
    # Verify checksum
    calc_checksum = data_size ^ command_id
    for byte in payload:
        calc_checksum ^= byte
    
    if checksum != calc_checksum:
        return None
    
    return {
        'command': command_id,
        'data': payload
    }
```

### Data Encoding Helpers

**Python Example:**
```python
def pack_u16(value):
    return bytes([value & 0xFF, (value >> 8) & 0xFF])

def pack_s16(value):
    return pack_u16(value & 0xFFFF)

def pack_float(value):
    scaled = int(value * 1000)
    return bytes([
        scaled & 0xFF,
        (scaled >> 8) & 0xFF,
        (scaled >> 16) & 0xFF,
        (scaled >> 24) & 0xFF
    ])

def unpack_u16(data, offset=0):
    return data[offset] | (data[offset+1] << 8)

def unpack_s16(data, offset=0):
    value = unpack_u16(data, offset)
    if value & 0x8000:
        return value - 0x10000
    return value

def unpack_float(data, offset=0):
    scaled = unpack_s32(data, offset)
    return scaled / 1000.0
```

### Command Flow Examples

**Read PID Gains:**
```python
# Send request
request = build_msp_packet(112)  # MSP_PID
serial.write(request)

# Wait for response
response = serial.read(100)  # Read up to 100 bytes
packet = parse_msp_response(response)

if packet and packet['command'] == 112:
    data = packet['data']
    roll_p = unpack_float(data, 0)
    roll_i = unpack_float(data, 4)
    roll_d = unpack_float(data, 8)
    # ... continue for all 9 values
```

**Set PID Gains:**
```python
# Build data payload
data = bytearray()
data.extend(pack_float(1.5))   # Roll P
data.extend(pack_float(0.1))   # Roll I
data.extend(pack_float(0.05))  # Roll D
# ... continue for all 9 values

# Send request
request = build_msp_packet(202, data)  # MSP_SET_PID
serial.write(request)

# Wait for ACK
response = serial.read(100)
packet = parse_msp_response(response)
if packet and packet['command'] == 202 and len(packet['data']) == 0:
    print("PID gains saved successfully")
```

---

## Command Summary Table

| Command ID | Name | Request Size | Response Size | Description |
|------------|------|--------------|---------------|-------------|
| 100 | MSP_IDENT | 0 | 4 | Get FC identifier |
| 101 | MSP_STATUS | 0 | 10 | Get system status |
| 102 | MSP_RAW_IMU | 0 | 18 | Get raw IMU data |
| 104 | MSP_MOTOR | 0 | 16 | Get motor outputs |
| 105 | MSP_RC | 0 | 16 | Get RC channels |
| 108 | MSP_ATTITUDE | 0 | 6 | Get attitude |
| 112 | MSP_PID | 0 | 36 | Get PID gains |
| 200 | MSP_COMP_GYRO | 0 | 0 | Calibrate gyro |
| 202 | MSP_SET_PID | 36 | 0 | Set PID gains |
| 205 | MSP_ACC_CALIBRATION | 0 | 0 | Calibrate accel |
| 214 | MSP_SET_MOTOR | 16 | 0 | Set motor values |
| 241 | MSP_ESC_MIN | 2 | 0 | Set ESC min |
| 242 | MSP_ESC_MAX | 2 | 0 | Set ESC max |
| 243 | MSP_MOTOR_TEST | 0 | 0 | Enter motor test |
| 244 | MSP_MOTOR_STOP | 0 | 0 | Exit motor test |
| 245 | MSP_MOTOR_STATUS | 0 | 9 | Get motor status |
| 246 | MSP_CAL_SHOW | 0 | 12 | Get cal offsets |
| 247 | MSP_VERSION | 0 | 3 | Get version |
| 250 | MSP_EEPROM_WRITE | 0 | 0 | Save config |
| 68 | MSP_RESET | 0 | 0 | Reset FC |

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024 | Initial specification |

---

## Contact and Support

For questions or issues regarding this protocol specification, please refer to the flight controller firmware documentation or contact the development team.

---

**End of Specification**

