import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_controller_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/drone_3d.dart';
import '../widgets/airbus_attitude_indicator.dart';

class IMUScreen extends StatefulWidget {
  const IMUScreen({super.key});

  @override
  State<IMUScreen> createState() => _IMUScreenState();
}

class _IMUScreenState extends State<IMUScreen> {
  double _staticRoll = 15.0;
  double _staticPitch = -10.0;
  double _staticYaw = 30.0;
  bool _useStaticValues = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightControllerProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final calibration = state.calibration;
        
        final roll = _useStaticValues ? _staticRoll : state.roll;
        final pitch = _useStaticValues ? _staticPitch : state.pitch;
        final yaw = _useStaticValues ? _staticYaw : state.yaw;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Data (40%)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // IMU Status
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sensors, color: AppColors.primary, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'IMU Status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildStatusBadge('Gyro', calibration.gyroX != 0 || calibration.gyroY != 0 || calibration.gyroZ != 0)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildStatusBadge('Accel', calibration.accelX != 0 || calibration.accelY != 0 || calibration.accelZ != 0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Current Attitude
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flight, color: AppColors.success, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Attitude',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildValueRow('Roll', roll, Colors.red),
                            _buildValueRow('Pitch', pitch, Colors.green),
                            _buildValueRow('Yaw', yaw, Colors.blue),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Offsets
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tune, color: AppColors.secondary, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sensor Offsets',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildOffsetSection('Gyro', calibration.gyroX, calibration.gyroY, calibration.gyroZ),
                            const SizedBox(height: 8),
                            _buildOffsetSection('Accel', calibration.accelX, calibration.accelY, calibration.accelZ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Test Controls
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.science, color: AppColors.warning, size: 14),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Test Mode',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 24,
                                  child: Switch(
                                    value: _useStaticValues,
                                    onChanged: (v) => setState(() => _useStaticValues = v),
                                    activeColor: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (_useStaticValues) ...[
                              const SizedBox(height: 10),
                              _buildSlider('Roll', _staticRoll, -45, 45, Colors.red, (v) => setState(() => _staticRoll = v)),
                              _buildSlider('Pitch', _staticPitch, -45, 45, Colors.green, (v) => setState(() => _staticPitch = v)),
                              _buildSlider('Yaw', _staticYaw, 0, 360, Colors.blue, (v) => setState(() => _staticYaw = v)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() { _staticRoll = 0; _staticPitch = 0; _staticYaw = 0; }),
                                    child: const Text('Reset', style: TextStyle(fontSize: 11)),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() { _staticRoll = 15; _staticPitch = -10; _staticYaw = 45; }),
                                    child: const Text('Example', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right Column - Visualizations (60%) - Side by side
              Expanded(
                flex: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3D View
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '3D Attitude',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 400,
                                width: double.infinity,
                                child: Drone3D(roll: roll, pitch: pitch, yaw: yaw),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Attitude Indicator
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attitude Indicator',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 400,
                                width: double.infinity,
                                child: AirbusAttitudeIndicator(roll: roll, pitch: pitch),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String label, bool isOk) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: (isOk ? AppColors.success : AppColors.warning).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isOk ? AppColors.success : AppColors.warning).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isOk ? Icons.check_circle : Icons.warning, color: isOk ? AppColors.success : AppColors.warning, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isOk ? AppColors.success : AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
            child: Text(
              '${value.toStringAsFixed(1)}°',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffsetSection(String label, int x, int y, int z) {
    return Row(
      children: [
        SizedBox(
          width: 45,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
            child: Text(
              'X:$x  Y:$y  Z:$z',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Color color, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                activeColor: color,
                inactiveColor: AppColors.divider,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${value.toStringAsFixed(0)}°',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
