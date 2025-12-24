# Flight Controller Configurator - Quick Start Guide

## Overview

This is a companion document to `CONFIGURATOR_DEVELOPMENT.md` providing a quick reference for AI agents or developers building the Flutter configurator.

## Project Setup (30 seconds)

```bash
flutter create flight_controller_configurator
cd flight_controller_configurator
```

Add to `pubspec.yaml`:
```yaml
dependencies:
  libserialport: ^0.4.0
  provider: ^6.1.1
  syncfusion_flutter_gauges: ^24.1.41
  fl_chart: ^0.66.0
```

```bash
flutter pub get
```

## Serial Communication (Core Implementation)

### 1. Connect to Flight Controller
```dart
import 'package:libserialport/libserialport.dart';

SerialPort port = SerialPort('COM3');
port.config = SerialPortConfig()
  ..baudRate = 115200
  ..bits = 8
  ..stopBits = 1
  ..parity = SerialPortParity.none;

port.openReadWrite();
```

### 2. Send Command
```dart
void sendCommand(String cmd) {
  final data = '$cmd\r\n';
  port.write(Uint8List.fromList(data.codeUnits));
}

// Examples:
sendCommand('pid_show');
sendCommand('motor_all 500');
sendCommand('save');
```

### 3. Read Response
```dart
SerialPortReader reader = SerialPortReader(port);
reader.stream
  .map((data) => String.fromCharCodes(data))
  .transform(LineSplitter())
  .listen((line) {
    print('Received: $line');
  });
```

## Command Categories

### Essential Commands (Implement First)
1. `help` - Get command list
2. `version` - Get firmware version
3. `status` - Get attitude and armed status
4. `save` - Save configuration

### PID Tuning Commands
1. `pid_show` - Display current PID values
2. `pid_p 0.7` - Set P gain
3. `pid_i 0.05` - Set I gain
4. `pid_d 0.02` - Set D gain

### Motor Test Commands (Safety Critical!)
1. `motor_test` - Enter motor test mode
2. `motor 0 500` - Set motor 0 to 50%
3. `motor_all 300` - Set all motors to 30%
4. `motor_stop` - Exit and stop motors

### Monitoring Commands
1. `rc_data` - Get RC input values
2. `motor_status` - Get current motor values
3. `cal_show` - Show calibration offsets

## Screen Priority Order

Build screens in this order:

1. **Connection Screen** (Day 1)
   - Port selector dropdown
   - Connect button
   - Status display

2. **Home/Dashboard** (Day 1-2)
   - Attitude indicator
   - Status cards
   - Connection panel

3. **PID Tuning** (Day 2)
   - Sliders for P, I, D
   - Save button
   - Real-time updates

4. **Motor Testing** (Day 3)
   - Safety warnings
   - Individual motor sliders
   - Master control slider
   - Emergency stop

5. **RC Monitor** (Day 3)
   - Channel bars
   - Real-time updates

6. **Calibration** (Day 4)
   - Gyro calibration button
   - Accel calibration button
   - Status display

## Critical Safety Checks

### Motor Test Mode Requirements
```dart
bool canEnableMotorTest() {
  return propsRemovedCheckbox && 
         !isArmed && 
         isConnected;
}
```

### Emergency Stop Implementation
```dart
Future<void> emergencyStop() async {
  await sendCommand('motor_all 0');
  await sendCommand('motor_stop');
  setState(() {
    motorTestActive = false;
    allMotorValues = [0, 0, 0, 0];
  });
}
```

### Auto-Stop on Close
```dart
@override
void dispose() {
  if (motorTestActive) {
    emergencyStop();
  }
  port.close();
  super.dispose();
}
```

## Common Response Patterns

### PID Show Response
```
Current PID Configuration:
Roll:  P=0.700  I=0.050  D=0.020
Pitch: P=0.700  I=0.050  D=0.020
Yaw:   P=0.600  I=0.020  D=0.000
```

Parse with regex:
```dart
final match = RegExp(r'P=([\d.]+)\s+I=([\d.]+)\s+D=([\d.]+)');
```

### RC Data Response
```
RC Input Data:
Roll:     1500 us
Pitch:    1500 us
Throttle: 1000 us
Yaw:      1500 us
AUX1:     1000 us
AUX2:     1500 us
```

Parse with:
```dart
final match = RegExp(r'(\d+) us');
```

### Motor Status Response
```
Motor Status:
Motor 0: 500
Motor 1: 300
Motor 2: 0
Motor 3: 0
Test Mode: ENABLED
```

## UI Component Examples

### PID Slider
```dart
Row(
  children: [
    Text('P Gain:'),
    Slider(
      value: pValue,
      min: 0.0,
      max: 5.0,
      onChanged: (v) {
        setState(() => pValue = v);
        sendCommand('pid_p ${v.toStringAsFixed(3)}');
      },
    ),
    Text(pValue.toStringAsFixed(3)),
  ],
)
```

### Motor Control Slider (Vertical)
```dart
RotatedBox(
  quarterTurns: 3,
  child: Slider(
    value: motorValue.toDouble(),
    min: 0,
    max: 1000,
    onChanged: (v) {
      setState(() => motorValue = v.toInt());
      sendCommand('motor 0 ${v.toInt()}');
    },
  ),
)
```

### RC Channel Bar
```dart
LinearProgressIndicator(
  value: (rcValue - 1000) / 1000,  // Normalize 1000-2000 to 0-1
  minHeight: 30,
)
```

## Testing Without Hardware

Use virtual serial port:
1. Install **com0com** (Windows)
2. Create COM port pair (e.g., COM3 ↔ COM4)
3. Use serial monitor on COM4 to simulate flight controller
4. Test configurator on COM3

## Common Issues & Solutions

### Issue: Port access denied
**Solution**: Close other serial monitors, check permissions

### Issue: Commands not working
**Solution**: Verify `\r\n` line ending is added

### Issue: Responses not parsing
**Solution**: Check for echo (command is echoed back), skip echo lines

### Issue: Motor values not updating
**Solution**: Ensure motor_test mode is active first

## Development Timeline Estimate

- **Day 1**: Serial communication + Connection screen
- **Day 2**: Home screen + PID tuning
- **Day 3**: Motor testing + RC monitor
- **Day 4**: Calibration + polish
- **Day 5**: Testing + bug fixes

Total: ~40 hours for full implementation

## File Structure
```
lib/
├── main.dart                      # App entry point
├── services/
│   ├── serial_service.dart        # Serial port handling
│   └── command_service.dart       # Command abstraction
├── models/
│   ├── pid_config.dart           # Data models
│   └── motor_status.dart
├── screens/
│   ├── home_screen.dart          # Dashboard
│   ├── pid_tuning_screen.dart    # PID adjustment
│   └── motor_test_screen.dart    # Motor testing
└── widgets/
    ├── connection_panel.dart      # Reusable components
    └── motor_control.dart
```

## Key Takeaways

1. **Serial Protocol**: Simple ASCII commands with `\r\n`
2. **Safety First**: Multiple checks for motor testing
3. **Real-time Updates**: Poll commands at 1-10 Hz
4. **Error Handling**: Always handle disconnect gracefully
5. **State Management**: Use Provider for reactive UI

## Next Steps

1. Read full `CONFIGURATOR_DEVELOPMENT.md`
2. Set up Flutter project with dependencies
3. Implement SerialService first
4. Test connection with hardware
5. Build screens incrementally
6. Test thoroughly with hardware

Good luck! 🚀

