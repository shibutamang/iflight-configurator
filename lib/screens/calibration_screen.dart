import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_controller_provider.dart';
import '../utils/app_colors.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _calibratingGyro = false;
  bool _calibratingAccel = false;

  Future<void> _calibrateGyro() async {
    setState(() => _calibratingGyro = true);

    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    bool success = await provider.calibrateGyro();

    if (!mounted) return;

    setState(() => _calibratingGyro = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Gyroscope calibration complete' : 'Calibration failed'),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _calibrateAccel() async {
    setState(() => _calibratingAccel = true);

    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    bool success = await provider.calibrateAccel();

    if (!mounted) return;

    setState(() => _calibratingAccel = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Accelerometer calibration complete' : 'Calibration failed'),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightControllerProvider>(
      builder: (context, provider, child) {
        final calibration = provider.state.calibration;
        final isConnected = provider.state.isConnected;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calibration Cards Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gyroscope Calibration
                  Expanded(
                    child: _buildCalibrationCard(
                      title: 'Gyroscope',
                      icon: Icons.sensors,
                      color: AppColors.primary,
                      instruction: 'Keep quadcopter still',
                      isCalibrating: _calibratingGyro,
                      isCalibrated: calibration.gyroX != 0 || calibration.gyroY != 0 || calibration.gyroZ != 0,
                      offsets: 'X:${calibration.gyroX} Y:${calibration.gyroY} Z:${calibration.gyroZ}',
                      onCalibrate: isConnected && !_calibratingGyro ? _calibrateGyro : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accelerometer Calibration
                  Expanded(
                    child: _buildCalibrationCard(
                      title: 'Accelerometer',
                      icon: Icons.straighten,
                      color: AppColors.secondary,
                      instruction: 'Place on level surface',
                      isCalibrating: _calibratingAccel,
                      isCalibrated: calibration.accelX != 0 || calibration.accelY != 0 || calibration.accelZ != 0,
                      offsets: 'X:${calibration.accelX} Y:${calibration.accelY} Z:${calibration.accelZ}',
                      onCalibrate: isConnected && !_calibratingAccel ? _calibrateAccel : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: isConnected
                                ? () async {
                                    await provider.refreshAll();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Data refreshed'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: isConnected
                                ? () async {
                                    await provider.refreshAll();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Saved to flash'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text('Save to Flash'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          'Calibration Tips',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Gyro: Keep perfectly still during calibration\n'
                      '• Accel: Use a level surface, props removed\n'
                      '• Recalibrate after firmware updates',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.5,
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

  Widget _buildCalibrationCard({
    required String title,
    required IconData icon,
    required Color color,
    required String instruction,
    required bool isCalibrating,
    required bool isCalibrated,
    required String offsets,
    VoidCallback? onCalibrate,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isCalibrated ? AppColors.success : AppColors.warning).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCalibrated ? Icons.check_circle : Icons.warning,
                        color: isCalibrated ? AppColors.success : AppColors.warning,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCalibrated ? 'OK' : 'Needed',
                        style: TextStyle(
                          color: isCalibrated ? AppColors.success : AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Instruction
            Text(
              instruction,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            // Offsets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                offsets,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Button
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                onPressed: onCalibrate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: isCalibrating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Text('Calibrate $title'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
