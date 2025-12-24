# Flight Controller Configurator - Flutter Development Guide

## Overview

This document provides complete specifications for building a Windows desktop configurator tool using Flutter for the STM32F4 Black Pill flight controller firmware. The configurator communicates via USB serial (115200 baud) and provides a graphical interface for configuration, calibration, tuning, and motor testing.

**Target Platform**: Windows Desktop (Flutter for Windows)  
**Communication**: USB Serial (CDC) at 115200 baud, 8N1  
**Protocol**: ASCII text commands terminated with `\r\n`

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Serial Communication](#serial-communication)
3. [Command Reference](#command-reference)
4. [UI/UX Design Specifications](#uiux-design-specifications)
5. [Feature Modules](#feature-modules)
6. [Data Models](#data-models)
7. [Implementation Guidelines](#implementation-guidelines)
8. [Safety Features](#safety-features)
9. [Example Code Snippets](#example-code-snippets)

---

## Project Structure

### Recommended Flutter Project Structure

```
flight_controller_configurator/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── flight_controller_state.dart
│   │   ├── pid_config.dart
│   │   ├── calibration_data.dart
│   │   ├── rc_input_data.dart
│   │   └── motor_status.dart
│   ├── services/
│   │   ├── serial_service.dart
│   │   └── command_service.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── setup_screen.dart
│   │   ├── pid_tuning_screen.dart
│   │   ├── motor_test_screen.dart
│   │   ├── rc_monitor_screen.dart
│   │   └── calibration_screen.dart
│   ├── widgets/
│   │   ├── connection_panel.dart
│   │   ├── attitude_indicator.dart
│   │   ├── pid_slider.dart
│   │   ├── motor_control_widget.dart
│   │   └── rc_channel_bar.dart
│   └── utils/
│       ├── constants.dart
│       └── validators.dart
└── pubspec.yaml
```

### Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Serial Communication
  libserialport: ^0.4.0
  
  # State Management
  provider: ^6.1.1
  
  # UI Components
  flutter_spinbox: ^0.13.1
  syncfusion_flutter_gauges: ^24.1.41  # For attitude indicator
  fl_chart: ^0.66.0  # For graphs/charts
  
  # Utilities
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## Serial Communication

### Connection Parameters

- **Baud Rate**: 115200
- **Data Bits**: 8
- **Stop Bits**: 1
- **Parity**: None (8N1)
- **Flow Control**: None
- **Line Ending**: `\r\n` (Carriage Return + Line Feed)

### Serial Port Discovery

```dart
import 'package:libserialport/libserialport.dart';

List<String> getAvailablePorts() {
  final ports = SerialPort.availablePorts;
  return ports;
}
```

### Opening Connection

```dart
SerialPort? _port;
SerialPortReader? _reader;

Future<bool> connect(String portName) async {
  try {
    _port = SerialPort(portName);
    
    final config = SerialPortConfig()
      ..baudRate = 115200
      ..bits = 8
      ..stopBits = 1
      ..parity = SerialPortParity.none;
    
    _port!.config = config;
    
    if (!_port!.openReadWrite()) {
      return false;
    }
    
    _reader = SerialPortReader(_port!);
    _startListening();
    
    return true;
  } catch (e) {
    print('Error connecting: $e');
    return false;
  }
}
```

### Sending Commands

```dart
void sendCommand(String command) {
  if (_port == null || !_port!.isOpen) {
    throw Exception('Port not open');
  }
  
  final data = '$command\r\n';
  _port!.write(Uint8List.fromList(data.codeUnits));
}
```

### Reading Responses

```dart
Stream<String> _responseStream = Stream.empty();

void _startListening() {
  _responseStream = _reader!.stream
    .map((data) => String.fromCharCodes(data))
    .transform(const LineSplitter());
}
```

---

## Command Reference

### Connection & Status Commands

| Command | Parameters | Response | Description |
|---------|-----------|----------|-------------|
| `help` | None | Multi-line help text | Display all available commands |
| `version` | None | "iFlight Controller v1.0.0" | Get firmware version |
| `status` | None | Roll/Pitch/Yaw angles, Armed status | Get current flight controller status |
| `reset` | None | System resets | Restart flight controller |
| `save` | None | "Configuration saved" | Save settings to flash memory |

### Calibration Commands

| Command | Parameters | Response | Description |
|---------|-----------|----------|-------------|
| `cal_gyro` | None | "Calibrating gyro...", "complete" | Calibrate gyroscope (keep still) |
| `cal_accel` | None | "Calibrating accelerometer...", "complete" | Calibrate accelerometer (keep level) |
| `cal_show` | None | Gyro/Accel offset values | Display current calibration offsets |

### PID Tuning Commands

| Command | Parameters | Response | Description |
|---------|-----------|----------|-------------|
| `pid_p <value>` | Float (0.0-10.0) | "PID P set to X.XXX" | Set P gain for roll/pitch |
| `pid_i <value>` | Float (0.0-1.0) | "PID I set to X.XXX" | Set I gain for roll/pitch |
| `pid_d <value>` | Float (0.0-1.0) | "PID D set to X.XXX" | Set D gain for roll/pitch |
| `pid_show` | None | Current PID values | Display Roll/Pitch/Yaw PID configuration |

**Example Response for `pid_show`:**
```
Current PID Configuration:
Roll:  P=0.700  I=0.050  D=0.020
Pitch: P=0.700  I=0.050  D=0.020
Yaw:   P=0.600  I=0.020  D=0.000
```

### RC Input Monitoring

| Command | Parameters | Response | Description |
|---------|-----------|----------|-------------|
| `rc_data` | None | RC channel values in microseconds | Display all RC input channels |

**Example Response:**
```
RC Input Data:
Roll:     1500 us
Pitch:    1500 us
Throttle: 1000 us
Yaw:      1500 us
AUX1:     1000 us
AUX2:     1500 us
```

Or if no signal:
```
RC: NO SIGNAL
```

### Motor Testing Commands

| Command | Parameters | Response | Description |
|---------|-----------|----------|-------------|
| `motor_test` | None | "Motor test mode ENABLED" | Enter motor test mode (requires disarm) |
| `motor <0-3> <value>` | Motor: 0-3, Value: 0-1000 | "Motor X set to Y" | Set individual motor speed |
| `motor_all <value>` | Value: 0-1000 | "All motors set to Y" | Set all motors to same speed |
| `motor_status` | None | Current motor values | Display motor speeds and test mode status |
| `motor_stop` | None | "Motor test mode DISABLED" | Exit motor test mode, stop all motors |

**Motor Mapping:**
```
   M1(0)  M2(1)     Front
      \  /
       \/
       /\
      /  \
   M4(3)  M3(2)     Back
```

### ESC Configuration Commands

| Command | Parameters | Response | Description |
|---------|-----------|----------|-------------|
| `esc_calibrate` | None | Multi-line calibration steps | Display ESC calibration procedure |
| `esc_min <value>` | Microseconds: 500-1500 | "ESC min set to X us" | Set ESC minimum pulse width |
| `esc_max <value>` | Microseconds: 1500-2500 | "ESC max set to X us" | Set ESC maximum pulse width |

---

## UI/UX Design Specifications

### Color Scheme

```dart
class AppColors {
  static const primary = Color(0xFF2196F3);        // Blue
  static const secondary = Color(0xFF00BCD4);      // Cyan
  static const success = Color(0xFF4CAF50);        // Green
  static const warning = Color(0xFFFF9800);        // Orange
  static const danger = Color(0xFFFF5252);         // Red
  static const dark = Color(0xFF263238);           // Dark Blue-Grey
  static const light = Color(0xFFECEFF1);          // Light Grey
  static const background = Color(0xFF1E1E1E);     // Dark background
  static const cardBg = Color(0xFF2D2D2D);         // Card background
}
```

### Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│  Flight Controller Configurator          [_][□][X]      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Connection Panel                                 │  │
│  │  [Port: COM3 ▼]  [Connect]  ● Connected         │  │
│  │  Version: v1.0.0  |  Status: Armed               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────┬──────┬──────┬──────┬──────┬──────────────┐  │
│  │ Home │ Setup│ PID  │Motors│  RC  │ Calibration  │  │
│  └──────┴──────┴──────┴──────┴──────┴──────────────┘  │
│                                                          │
│  [Tab Content Area]                                     │
│                                                          │
│                                                          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Navigation Tabs

1. **Home** - Dashboard with attitude indicator and status
2. **Setup** - Basic configuration and firmware info
3. **PID Tuning** - PID gain adjustment with sliders
4. **Motors** - Motor testing and ESC calibration
5. **RC Monitor** - RC input visualization
6. **Calibration** - IMU calibration tools

---

## Feature Modules

### Module 1: Connection Panel

**Location**: Top of all screens  
**Features**:
- COM port dropdown (auto-refresh)
- Connect/Disconnect button
- Connection status indicator (● Green = Connected, ● Red = Disconnected)
- Firmware version display
- Armed/Disarmed status

**UI Elements**:
```dart
Widget _buildConnectionPanel() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Port Selector
          DropdownButton<String>(
            value: selectedPort,
            items: availablePorts.map((port) {
              return DropdownMenuItem(value: port, child: Text(port));
            }).toList(),
            onChanged: (value) => setState(() => selectedPort = value),
          ),
          
          SizedBox(width: 16),
          
          // Connect Button
          ElevatedButton(
            onPressed: isConnected ? disconnect : connect,
            child: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),
          
          SizedBox(width: 16),
          
          // Status Indicator
          Row(
            children: [
              Icon(
                Icons.circle,
                color: isConnected ? Colors.green : Colors.red,
                size: 12,
              ),
              SizedBox(width: 8),
              Text(isConnected ? 'Connected' : 'Disconnected'),
            ],
          ),
          
          Spacer(),
          
          // Version & Status
          Text('Version: $firmwareVersion'),
          SizedBox(width: 16),
          Text('Status: ${isArmed ? "Armed" : "Disarmed"}'),
        ],
      ),
    ),
  );
}
```

### Module 2: Home Screen (Dashboard)

**Features**:
- Attitude indicator (roll, pitch, yaw visualization)
- Real-time attitude values
- Armed/Disarmed status
- System health indicators

**Components**:
1. **Artificial Horizon** - Shows roll and pitch
2. **Heading Indicator** - Shows yaw
3. **Numerical Displays** - Exact angle values
4. **Status Cards** - Connection, calibration status

**Implementation**:
Use `syncfusion_flutter_gauges` for attitude indicator:
```dart
SfRadialGauge(
  axes: <RadialAxis>[
    RadialAxis(
      minimum: -45,
      maximum: 45,
      ranges: <GaugeRange>[
        GaugeRange(startValue: -45, endValue: 45, color: Colors.blue),
      ],
      pointers: <GaugePointer>[
        NeedlePointer(value: currentRoll),
      ],
    ),
  ],
)
```

### Module 3: PID Tuning Screen

**Features**:
- Sliders for P, I, D gains (Roll/Pitch/Yaw)
- Numerical input fields
- Real-time value display
- Save button
- Reset to defaults button
- PID tuning guide/tips

**Layout**:
```
┌─────────────────────────────────────────────────────┐
│  PID Tuning                                          │
├─────────────────────────────────────────────────────┤
│                                                       │
│  Roll & Pitch                                        │
│  ┌─────────────────────────────────────────────┐   │
│  │ P Gain:  [0.700]  [========●====] (0-5.0)   │   │
│  │ I Gain:  [0.050]  [==●==========] (0-0.5)   │   │
│  │ D Gain:  [0.020]  [=●===========] (0-0.2)   │   │
│  └─────────────────────────────────────────────┘   │
│                                                       │
│  Yaw                                                 │
│  ┌─────────────────────────────────────────────┐   │
│  │ P Gain:  [0.600]  [=======●=====] (0-5.0)   │   │
│  │ I Gain:  [0.020]  [=●===========] (0-0.5)   │   │
│  │ D Gain:  [0.000]  [●============] (0-0.2)   │   │
│  └─────────────────────────────────────────────┘   │
│                                                       │
│  [Save Configuration]  [Reset to Defaults]          │
│                                                       │
│  💡 Tips:                                            │
│  • Increase P until oscillations appear             │
│  • Add I to eliminate drift                          │
│  • Add D to reduce overshoot                         │
└─────────────────────────────────────────────────────┘
```

**Slider Widget**:
```dart
class PIDSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Function(double) onChanged;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        SizedBox(
          width: 100,
          child: TextField(
            controller: TextEditingController(text: value.toStringAsFixed(3)),
            keyboardType: TextInputType.number,
            onChanged: (text) => onChanged(double.tryParse(text) ?? value),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 1000,
            onChanged: onChanged,
          ),
        ),
        Text('($min-$max)'),
      ],
    );
  }
}
```

### Module 4: Motor Test Screen

**⚠️ CRITICAL SAFETY FEATURES**:
- Red warning banner: "REMOVE PROPELLERS BEFORE TESTING"
- Checkbox: "I confirm propellers are removed"
- Cannot enable motors without checkbox
- Auto-disable on disconnect
- Emergency stop button (always visible)

**Features**:
1. **Individual Motor Controls** - 4 vertical sliders (0-1000)
2. **Master Control** - One slider controlling all motors
3. **Motor Status Display** - Current values for each motor
4. **Motor Layout Diagram** - Visual representation
5. **ESC Calibration Wizard**

**Layout**:
```
┌──────────────────────────────────────────────────────┐
│  ⚠️ WARNING: REMOVE PROPELLERS BEFORE TESTING ⚠️     │
│  ☐ I confirm propellers are removed                  │
├──────────────────────────────────────────────────────┤
│                                                       │
│  [Enable Motor Test]        [EMERGENCY STOP]         │
│                                                       │
│  Master Control (All Motors)                         │
│  ┌────────────────────────────────────────────┐     │
│  │  [=================●===========] 500        │     │
│  └────────────────────────────────────────────┘     │
│                                                       │
│  Individual Motors                                   │
│  ┌──────┬──────┬──────┬──────┐                     │
│  │  M1  │  M2  │  M3  │  M4  │                     │
│  │ 1000 │ 1000 │ 1000 │ 1000 │                     │
│  │  │   │  │   │  │   │  │   │                     │
│  │  ●   │  ●   │  ●   │  ●   │                     │
│  │  │   │  │   │  │   │  │   │                     │
│  │  │   │  │   │  │   │  │   │                     │
│  │  │   │  │   │  │   │  │   │                     │
│  │  ●   │  ●   │  ●   │  ●   │                     │
│  │  │   │  │   │  │   │  │   │                     │
│  │  0   │  0   │  0   │  0   │                     │
│  └──────┴──────┴──────┴──────┘                     │
│                                                       │
│  Motor Layout:                                       │
│     M1   M2     Front                                │
│       \ /                                            │
│        X                                             │
│       / \                                            │
│     M4   M3     Back                                 │
│                                                       │
│  [ESC Calibration Wizard]                           │
└──────────────────────────────────────────────────────┘
```

**Motor Control Widget**:
```dart
class MotorControl extends StatelessWidget {
  final int motorNumber;
  final int value;
  final Function(int) onChanged;
  final bool enabled;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('M${motorNumber + 1}', style: TextStyle(fontSize: 18)),
        Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 1000,
              divisions: 1000,
              onChanged: enabled ? (v) => onChanged(v.toInt()) : null,
            ),
          ),
        ),
        Text('0'),
      ],
    );
  }
}
```

**ESC Calibration Wizard**:
```dart
class ESCCalibrationWizard extends StatefulWidget {
  @override
  _ESCCalibrationWizardState createState() => _ESCCalibrationWizardState();
}

class _ESCCalibrationWizardState extends State<ESCCalibrationWizard> {
  int currentStep = 0;
  
  List<String> steps = [
    'Disconnect battery from ESCs',
    'Click "Start Calibration"',
    'Connect battery to ESCs',
    'Wait for ESC beeps',
    'Calibration complete!',
  ];
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ESC Calibration Wizard'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Step ${currentStep + 1} of ${steps.length}'),
          SizedBox(height: 16),
          Text(steps[currentStep], style: TextStyle(fontSize: 18)),
          SizedBox(height: 24),
          if (currentStep == 1)
            ElevatedButton(
              onPressed: () => _startCalibration(),
              child: Text('Start Calibration'),
            ),
        ],
      ),
      actions: [
        if (currentStep > 0 && currentStep < steps.length - 1)
          TextButton(
            onPressed: () => setState(() => currentStep++),
            child: Text('Next'),
          ),
        if (currentStep == steps.length - 1)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Finish'),
          ),
      ],
    );
  }
  
  void _startCalibration() async {
    // Send motor_test
    await commandService.sendCommand('motor_test');
    await Future.delayed(Duration(milliseconds: 500));
    
    // Send max throttle
    await commandService.sendCommand('motor_all 1000');
    
    setState(() => currentStep++);
    
    // Wait for user to connect battery
    await Future.delayed(Duration(seconds: 5));
    
    // Send min throttle
    await commandService.sendCommand('motor_all 0');
    
    setState(() => currentStep++);
    
    // Wait a bit
    await Future.delayed(Duration(seconds: 2));
    
    // Exit motor test
    await commandService.sendCommand('motor_stop');
    
    setState(() => currentStep++);
  }
}
```

### Module 5: RC Monitor Screen

**Features**:
- Real-time RC channel visualization
- Horizontal bars showing channel values (1000-2000 µs)
- Numerical display
- "No Signal" indicator
- Auto-refresh (10 Hz)

**Layout**:
```
┌──────────────────────────────────────────────────────┐
│  RC Input Monitor                       [Refresh]     │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Roll:     [=========●==========] 1500 µs            │
│  Pitch:    [=========●==========] 1500 µs            │
│  Throttle: [●===================] 1000 µs            │
│  Yaw:      [=========●==========] 1500 µs            │
│  AUX1:     [●===================] 1000 µs            │
│  AUX2:     [=========●==========] 1500 µs            │
│                                                       │
│  Status: ● Signal Valid                              │
│                                                       │
│  💡 Tips:                                            │
│  • Center sticks should show ~1500 µs                │
│  • Throttle down should show ~1000 µs                │
│  • Full deflection should show 1000-2000 µs          │
└──────────────────────────────────────────────────────┘
```

**RC Channel Bar Widget**:
```dart
class RCChannelBar extends StatelessWidget {
  final String label;
  final int value;
  
  @override
  Widget build(BuildContext context) {
    // Normalize to 0-1 range
    double normalized = (value - 1000) / 1000.0;
    normalized = normalized.clamp(0.0, 1.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: normalized,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text('$value µs', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
```

### Module 6: Calibration Screen

**Features**:
1. **Gyroscope Calibration**
   - "Calibrate Gyro" button
   - Instructions: "Keep quadcopter still"
   - Progress indicator
   - Success/failure message

2. **Accelerometer Calibration**
   - "Calibrate Accelerometer" button
   - Instructions: "Keep quadcopter level"
   - Progress indicator
   - Success/failure message

3. **Calibration Status**
   - Show current offsets
   - Last calibration timestamp

**Layout**:
```
┌──────────────────────────────────────────────────────┐
│  IMU Calibration                                      │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Gyroscope Calibration                               │
│  ┌────────────────────────────────────────────┐     │
│  │  Keep the quadcopter completely still       │     │
│  │  [Calibrate Gyroscope]                      │     │
│  │  Status: ✓ Calibrated                       │     │
│  │  Offsets: X=-12  Y=45  Z=-8                │     │
│  └────────────────────────────────────────────┘     │
│                                                       │
│  Accelerometer Calibration                           │
│  ┌────────────────────────────────────────────┐     │
│  │  Place quadcopter on level surface          │     │
│  │  [Calibrate Accelerometer]                  │     │
│  │  Status: ✓ Calibrated                       │     │
│  │  Offsets: X=123  Y=-234  Z=16234           │     │
│  └────────────────────────────────────────────┘     │
│                                                       │
│  [Show Calibration Data]  [Save to Flash]           │
└──────────────────────────────────────────────────────┘
```

---

## Data Models

### FlightControllerState

```dart
class FlightControllerState {
  bool isConnected;
  bool isArmed;
  String firmwareVersion;
  
  double roll;
  double pitch;
  double yaw;
  
  PIDConfig pidConfig;
  RCInputData rcData;
  MotorStatus motorStatus;
  CalibrationData calibration;
  
  FlightControllerState({
    this.isConnected = false,
    this.isArmed = false,
    this.firmwareVersion = 'Unknown',
    this.roll = 0.0,
    this.pitch = 0.0,
    this.yaw = 0.0,
    required this.pidConfig,
    required this.rcData,
    required this.motorStatus,
    required this.calibration,
  });
}
```

### PIDConfig

```dart
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
  
  // Parse from pid_show response
  factory PIDConfig.fromResponse(List<String> lines) {
    // Parse lines like "Roll:  P=0.700  I=0.050  D=0.020"
    final rollMatch = RegExp(r'Roll:\s+P=([\d.]+)\s+I=([\d.]+)\s+D=([\d.]+)');
    final pitchMatch = RegExp(r'Pitch:\s+P=([\d.]+)\s+I=([\d.]+)\s+D=([\d.]+)');
    final yawMatch = RegExp(r'Yaw:\s+P=([\d.]+)\s+I=([\d.]+)\s+D=([\d.]+)');
    
    double rollP = 0.5, rollI = 0.03, rollD = 0.02;
    double pitchP = 0.5, pitchI = 0.03, pitchD = 0.02;
    double yawP = 0.6, yawI = 0.02, yawD = 0.0;
    
    for (var line in lines) {
      final roll = rollMatch.firstMatch(line);
      if (roll != null) {
        rollP = double.parse(roll.group(1)!);
        rollI = double.parse(roll.group(2)!);
        rollD = double.parse(roll.group(3)!);
      }
      
      final pitch = pitchMatch.firstMatch(line);
      if (pitch != null) {
        pitchP = double.parse(pitch.group(1)!);
        pitchI = double.parse(pitch.group(2)!);
        pitchD = double.parse(pitch.group(3)!);
      }
      
      final yaw = yawMatch.firstMatch(line);
      if (yaw != null) {
        yawP = double.parse(yaw.group(1)!);
        yawI = double.parse(yaw.group(2)!);
        yawD = double.parse(yaw.group(3)!);
      }
    }
    
    return PIDConfig(
      rollP: rollP, rollI: rollI, rollD: rollD,
      pitchP: pitchP, pitchI: pitchI, pitchD: pitchD,
      yawP: yawP, yawI: yawI, yawD: yawD,
    );
  }
}
```

### RCInputData

```dart
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
  
  // Parse from rc_data response
  factory RCInputData.fromResponse(List<String> lines) {
    if (lines.any((line) => line.contains('NO SIGNAL'))) {
      return RCInputData(signalValid: false);
    }
    
    int roll = 1500, pitch = 1500, throttle = 1000;
    int yaw = 1500, aux1 = 1000, aux2 = 1500;
    
    for (var line in lines) {
      if (line.contains('Roll:')) {
        roll = int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
      } else if (line.contains('Pitch:')) {
        pitch = int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
      } else if (line.contains('Throttle:')) {
        throttle = int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
      } else if (line.contains('Yaw:')) {
        yaw = int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
      } else if (line.contains('AUX1:')) {
        aux1 = int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
      } else if (line.contains('AUX2:')) {
        aux2 = int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
      }
    }
    
    return RCInputData(
      roll: roll, pitch: pitch, throttle: throttle,
      yaw: yaw, aux1: aux1, aux2: aux2,
      signalValid: true,
    );
  }
}
```

### MotorStatus

```dart
class MotorStatus {
  List<int> motorValues; // 0-1000 for each motor
  bool testModeEnabled;
  
  MotorStatus({
    List<int>? motorValues,
    this.testModeEnabled = false,
  }) : motorValues = motorValues ?? [0, 0, 0, 0];
  
  // Parse from motor_status response
  factory MotorStatus.fromResponse(List<String> lines) {
    List<int> values = [0, 0, 0, 0];
    bool enabled = false;
    
    for (var line in lines) {
      final motorMatch = RegExp(r'Motor (\d): (\d+)').firstMatch(line);
      if (motorMatch != null) {
        int index = int.parse(motorMatch.group(1)!);
        int value = int.parse(motorMatch.group(2)!);
        if (index < 4) values[index] = value;
      }
      
      if (line.contains('Test Mode: ENABLED')) {
        enabled = true;
      }
    }
    
    return MotorStatus(motorValues: values, testModeEnabled: enabled);
  }
}
```

### CalibrationData

```dart
class CalibrationData {
  int gyroX, gyroY, gyroZ;
  int accelX, accelY, accelZ;
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
  
  // Parse from cal_show response
  factory CalibrationData.fromResponse(List<String> lines) {
    int gx = 0, gy = 0, gz = 0;
    int ax = 0, ay = 0, az = 0;
    
    for (var line in lines) {
      if (line.contains('Gyro offsets:')) {
        final match = RegExp(r'X=(-?\d+)\s+Y=(-?\d+)\s+Z=(-?\d+)').firstMatch(line);
        if (match != null) {
          gx = int.parse(match.group(1)!);
          gy = int.parse(match.group(2)!);
          gz = int.parse(match.group(3)!);
        }
      } else if (line.contains('Accel offsets:')) {
        final match = RegExp(r'X=(-?\d+)\s+Y=(-?\d+)\s+Z=(-?\d+)').firstMatch(line);
        if (match != null) {
          ax = int.parse(match.group(1)!);
          ay = int.parse(match.group(2)!);
          az = int.parse(match.group(3)!);
        }
      }
    }
    
    return CalibrationData(
      gyroX: gx, gyroY: gy, gyroZ: gz,
      accelX: ax, accelY: ay, accelZ: az,
      lastCalibrated: DateTime.now(),
    );
  }
}
```

---

## Implementation Guidelines

### 1. Serial Service Implementation

```dart
import 'package:libserialport/libserialport.dart';
import 'dart:async';

class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamController<String> _responseController = StreamController.broadcast();
  
  Stream<String> get responseStream => _responseController.stream;
  bool get isConnected => _port != null && _port!.isOpen;
  
  List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }
  
  Future<bool> connect(String portName) async {
    try {
      _port = SerialPort(portName);
      
      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;
      
      _port!.config = config;
      
      if (!_port!.openReadWrite()) {
        return false;
      }
      
      _reader = SerialPortReader(_port!);
      _startListening();
      
      return true;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }
  
  void disconnect() {
    _reader?.close();
    _port?.close();
    _port = null;
    _reader = null;
  }
  
  void sendCommand(String command) {
    if (!isConnected) {
      throw Exception('Not connected');
    }
    
    final data = '$command\r\n';
    _port!.write(Uint8List.fromList(data.codeUnits));
  }
  
  void _startListening() {
    _reader!.stream
      .map((data) => String.fromCharCodes(data))
      .transform(const LineSplitter())
      .listen((line) {
        _responseController.add(line);
      });
  }
  
  void dispose() {
    disconnect();
    _responseController.close();
  }
}
```

### 2. Command Service Implementation

```dart
class CommandService {
  final SerialService _serialService;
  final FlightControllerState _state;
  
  CommandService(this._serialService, this._state);
  
  // Status Commands
  Future<void> getStatus() async {
    _serialService.sendCommand('status');
    // Parse response and update _state
  }
  
  Future<String> getVersion() async {
    _serialService.sendCommand('version');
    // Return version from response
    return 'v1.0.0'; // Placeholder
  }
  
  // PID Commands
  Future<void> setPIDp(double value) async {
    _serialService.sendCommand('pid_p ${value.toStringAsFixed(3)}');
  }
  
  Future<void> setPIDi(double value) async {
    _serialService.sendCommand('pid_i ${value.toStringAsFixed(3)}');
  }
  
  Future<void> setPIDd(double value) async {
    _serialService.sendCommand('pid_d ${value.toStringAsFixed(3)}');
  }
  
  Future<PIDConfig> getPIDConfig() async {
    _serialService.sendCommand('pid_show');
    // Wait for and parse response
    // Return PIDConfig
    return PIDConfig(); // Placeholder
  }
  
  // Motor Commands
  Future<void> enterMotorTest() async {
    _serialService.sendCommand('motor_test');
  }
  
  Future<void> exitMotorTest() async {
    _serialService.sendCommand('motor_stop');
  }
  
  Future<void> setMotor(int motor, int value) async {
    if (motor < 0 || motor > 3 || value < 0 || value > 1000) {
      throw ArgumentError('Invalid motor or value');
    }
    _serialService.sendCommand('motor $motor $value');
  }
  
  Future<void> setAllMotors(int value) async {
    if (value < 0 || value > 1000) {
      throw ArgumentError('Invalid value');
    }
    _serialService.sendCommand('motor_all $value');
  }
  
  Future<MotorStatus> getMotorStatus() async {
    _serialService.sendCommand('motor_status');
    // Parse response
    return MotorStatus(); // Placeholder
  }
  
  // RC Commands
  Future<RCInputData> getRCData() async {
    _serialService.sendCommand('rc_data');
    // Parse response
    return RCInputData(); // Placeholder
  }
  
  // Calibration Commands
  Future<void> calibrateGyro() async {
    _serialService.sendCommand('cal_gyro');
  }
  
  Future<void> calibrateAccel() async {
    _serialService.sendCommand('cal_accel');
  }
  
  Future<CalibrationData> getCalibrationData() async {
    _serialService.sendCommand('cal_show');
    // Parse response
    return CalibrationData(); // Placeholder
  }
  
  // Configuration Commands
  Future<void> saveConfiguration() async {
    _serialService.sendCommand('save');
  }
  
  Future<void> reset() async {
    _serialService.sendCommand('reset');
  }
}
```

### 3. State Management with Provider

```dart
import 'package:flutter/foundation.dart';

class FlightControllerProvider extends ChangeNotifier {
  final SerialService _serialService;
  final CommandService _commandService;
  
  FlightControllerState _state = FlightControllerState(
    pidConfig: PIDConfig(),
    rcData: RCInputData(),
    motorStatus: MotorStatus(),
    calibration: CalibrationData(),
  );
  
  FlightControllerState get state => _state;
  
  FlightControllerProvider(this._serialService, this._commandService) {
    _serialService.responseStream.listen(_handleResponse);
  }
  
  void _handleResponse(String line) {
    // Parse responses and update state
    if (line.contains('Armed:')) {
      _state.isArmed = line.contains('YES');
      notifyListeners();
    }
    // Add more response parsing...
  }
  
  Future<void> connect(String port) async {
    bool success = await _serialService.connect(port);
    if (success) {
      _state.isConnected = true;
      notifyListeners();
      
      // Get initial data
      await refreshStatus();
    }
  }
  
  Future<void> disconnect() async {
    _serialService.disconnect();
    _state.isConnected = false;
    notifyListeners();
  }
  
  Future<void> refreshStatus() async {
    await _commandService.getStatus();
    await _commandService.getPIDConfig();
    // ... other data
    notifyListeners();
  }
  
  Future<void> updatePID(double p, double i, double d) async {
    await _commandService.setPIDp(p);
    await _commandService.setPIDi(i);
    await _commandService.setPIDd(d);
    await _commandService.saveConfiguration();
    await refreshStatus();
  }
}
```

### 4. Main App Structure

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SerialService>(create: (_) => SerialService()),
        ProxyProvider<SerialService, CommandService>(
          update: (_, serial, __) => CommandService(serial, FlightControllerState(
            pidConfig: PIDConfig(),
            rcData: RCInputData(),
            motorStatus: MotorStatus(),
            calibration: CalibrationData(),
          )),
        ),
        ChangeNotifierProxyProvider2<SerialService, CommandService, FlightControllerProvider>(
          create: (context) => FlightControllerProvider(
            context.read<SerialService>(),
            context.read<CommandService>(),
          ),
          update: (_, serial, command, provider) =>
            provider ?? FlightControllerProvider(serial, command),
        ),
      ],
      child: MaterialApp(
        title: 'Flight Controller Configurator',
        theme: ThemeData.dark().copyWith(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: MainScreen(),
      ),
    );
  }
}
```

---

## Safety Features

### Critical Safety Requirements

1. **Motor Test Mode Safety**:
   ```dart
   bool _propsRemoved = false;
   bool _motorTestEnabled = false;
   
   void enableMotorTest() {
     if (!_propsRemoved) {
       showDialog(
         context: context,
         builder: (context) => AlertDialog(
           title: Text('⚠️ SAFETY WARNING'),
           content: Text('You must remove propellers before testing motors!'),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text('OK'),
             ),
           ],
         ),
       );
       return;
     }
     
     if (_state.isArmed) {
       showWarning('Cannot enter motor test mode while armed!');
       return;
     }
     
     _commandService.enterMotorTest();
     _motorTestEnabled = true;
   }
   ```

2. **Emergency Stop**:
   ```dart
   Widget _buildEmergencyStop() {
     return Container(
       color: Colors.red,
       child: ElevatedButton(
         style: ElevatedButton.styleFrom(
           backgroundColor: Colors.red,
           minimumSize: Size(200, 60),
         ),
         onPressed: () async {
           await _commandService.setAllMotors(0);
           await _commandService.exitMotorTest();
         },
         child: Text(
           'EMERGENCY STOP',
           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
         ),
       ),
     );
   }
   ```

3. **Auto-Disconnect Safety**:
   ```dart
   @override
   void dispose() {
     // Stop motors before closing
     if (_motorTestEnabled) {
       _commandService.setAllMotors(0);
       _commandService.exitMotorTest();
     }
     _serialService.disconnect();
     super.dispose();
   }
   ```

4. **Value Validation**:
   ```dart
   void setMotorValue(int motor, int value) {
     // Validate inputs
     if (motor < 0 || motor > 3) {
       throw ArgumentError('Motor must be 0-3');
     }
     if (value < 0 || value > 1000) {
       throw ArgumentError('Value must be 0-1000');
     }
     
     if (!_motorTestEnabled) {
       showWarning('Enter motor test mode first!');
       return;
     }
     
     _commandService.setMotor(motor, value);
   }
   ```

---

## Example Code Snippets

### Complete Motor Test Screen Example

```dart
class MotorTestScreen extends StatefulWidget {
  @override
  _MotorTestScreenState createState() => _MotorTestScreenState();
}

class _MotorTestScreenState extends State<MotorTestScreen> {
  bool _propsRemoved = false;
  bool _testModeActive = false;
  List<int> _motorValues = [0, 0, 0, 0];
  int _masterValue = 0;
  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FlightControllerProvider>(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Warning Banner
          Container(
            color: Colors.red,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '⚠️ WARNING: REMOVE PROPELLERS BEFORE TESTING ⚠️',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Safety Checkbox
          CheckboxListTile(
            title: Text('I confirm propellers are removed'),
            value: _propsRemoved,
            onChanged: (value) => setState(() => _propsRemoved = value ?? false),
          ),
          
          // Control Buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _propsRemoved && !_testModeActive
                    ? () => _enableMotorTest(provider)
                    : null,
                  child: Text('Enable Motor Test'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _emergencyStop(provider),
                  child: Text('EMERGENCY STOP'),
                ),
              ],
            ),
          ),
          
          // Master Control
          if (_testModeActive) ...[
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Master Control (All Motors)', style: TextStyle(fontSize: 18)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _masterValue.toDouble(),
                          min: 0,
                          max: 1000,
                          divisions: 100,
                          label: _masterValue.toString(),
                          onChanged: (value) {
                            setState(() => _masterValue = value.toInt());
                            provider._commandService.setAllMotors(_masterValue);
                            // Update individual values
                            setState(() {
                              for (int i = 0; i < 4; i++) {
                                _motorValues[i] = _masterValue;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(_masterValue.toString(), style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Individual Motor Controls
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Individual Motors', style: TextStyle(fontSize: 18)),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return _buildMotorControl(index, provider);
                }),
              ),
            ),
            
            // Motor Layout Diagram
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Motor Layout:', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('   M1   M2     Front'),
                  Text('     \\ /'),
                  Text('      X'),
                  Text('     / \\'),
                  Text('   M4   M3     Back'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMotorControl(int motorIndex, FlightControllerProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('M${motorIndex + 1}', style: TextStyle(fontSize: 18)),
        Text(
          '${_motorValues[motorIndex]}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: _motorValues[motorIndex].toDouble(),
              min: 0,
              max: 1000,
              divisions: 100,
              onChanged: (value) {
                setState(() => _motorValues[motorIndex] = value.toInt());
                provider._commandService.setMotor(motorIndex, value.toInt());
              },
            ),
          ),
        ),
        Text('0'),
      ],
    );
  }
  
  Future<void> _enableMotorTest(FlightControllerProvider provider) async {
    await provider._commandService.enterMotorTest();
    setState(() => _testModeActive = true);
  }
  
  Future<void> _emergencyStop(FlightControllerProvider provider) async {
    await provider._commandService.setAllMotors(0);
    await provider._commandService.exitMotorTest();
    setState(() {
      _testModeActive = false;
      _motorValues = [0, 0, 0, 0];
      _masterValue = 0;
    });
  }
  
  @override
  void dispose() {
    if (_testModeActive) {
      _emergencyStop(Provider.of<FlightControllerProvider>(context, listen: false));
    }
    super.dispose();
  }
}
```

---

## Testing Checklist

- [ ] Serial port connection/disconnection works
- [ ] All commands send properly with `\r\n` termination
- [ ] Response parsing works for all command types
- [ ] PID sliders update in real-time
- [ ] Motor test mode requires props-removed confirmation
- [ ] Motor test mode prevents arming
- [ ] Emergency stop works immediately
- [ ] RC monitor updates at ~10 Hz
- [ ] Calibration commands show progress
- [ ] Save/load configuration works
- [ ] Error handling for disconnection during operation
- [ ] Auto-stop motors on app close
- [ ] Value validation prevents invalid inputs

---

## Additional Resources

### Helpful Flutter Packages

- `libserialport` - Cross-platform serial communication
- `provider` - State management
- `syncfusion_flutter_gauges` - Attitude indicators
- `fl_chart` - Data visualization
- `flutter_spinbox` - Numeric input widgets

### Design References

- **iNav Configurator** - https://github.com/iNavFlight/inav-configurator
- **Betaflight Configurator** - https://github.com/betaflight/betaflight-configurator
- **Material Design** - https://material.io/design

### Testing Tools

- Use **Virtual Serial Port** tools for testing without hardware
- **com0com** (Windows) for virtual COM port pairs
- **Serial Monitor** tools for debugging communication

---

## Final Notes

This configurator should provide a complete, safe, and user-friendly interface for configuring the flight controller. Key priorities:

1. **Safety First** - Multiple safeguards for motor testing
2. **User Experience** - Clear, intuitive interface
3. **Real-time Updates** - Live data visualization
4. **Error Handling** - Graceful handling of disconnections
5. **Cross-platform** - Works on Windows (extensible to Linux/Mac)

The serial protocol is simple ASCII-based commands, making debugging and development straightforward. All responses follow predictable patterns that can be parsed with regular expressions.

Good luck with development! 🚁

