import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_controller_provider.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<FlightControllerProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status - Compact
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (state.isConnected ? AppColors.success : AppColors.danger).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          state.isConnected ? Icons.link : Icons.link_off,
                          color: state.isConnected ? AppColors.success : AppColors.danger,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isConnected ? 'Connected' : 'Not Connected',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: state.isConnected ? AppColors.success : AppColors.danger,
                              ),
                            ),
                            Text(
                              state.isConnected
                                  ? 'Firmware: ${state.firmwareVersion}'
                                  : 'Connect to flight controller',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.isConnected && state.freeHeap > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(state.freeHeap / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // System Status Grid - Compact
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      'Battery',
                      state.isConnected && state.batteryVoltage > 0
                          ? '${state.batteryVoltage.toStringAsFixed(1)}V'
                          : '-- V',
                      state.isConnected && state.batteryVoltage > 0
                          ? _getBatteryIcon(state.batteryPercentage)
                          : Icons.battery_unknown,
                      color: state.isConnected && state.batteryVoltage > 0
                          ? _getBatteryColor(state.batteryPercentage)
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatusCard('Cycle', '${state.cycleTime} μs', Icons.speed)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusCard(
                      'I2C Err',
                      '${state.i2cErrors}',
                      Icons.error_outline,
                      color: state.i2cErrors > 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  if (state.isConnected && state.cpuLoad > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusCard('CPU', '${state.cpuLoad.toStringAsFixed(0)}%', Icons.memory),
                    ),
                  ],
                  if (state.isConnected && state.cpuTemperature > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusCard(
                        'Temp',
                        '${state.cpuTemperature.toStringAsFixed(0)}°C',
                        Icons.thermostat,
                        color: state.cpuTemperature > 70
                            ? AppColors.danger
                            : state.cpuTemperature > 60
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Sensor Health Monitor
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sensors, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Sensor Health',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (state.isConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getOverallSensorHealth(state) 
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getOverallSensorHealth(state) ? 'All OK' : 'Check Sensors',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getOverallSensorHealth(state) 
                                      ? AppColors.success 
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Sensor Grid
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSensorChip('Gyro', Icons.rotate_right, state.gyroHealthy, state.isConnected),
                          _buildSensorChip('Accel', Icons.straighten, state.accHealthy, state.isConnected),
                          _buildSensorChip('Mag', Icons.explore, state.magHealthy, state.isConnected),
                          _buildSensorChip('Baro', Icons.speed, state.baroHealthy, state.isConnected),
                          _buildSensorChipWithValue(
                            'GPS', 
                            Icons.satellite_alt, 
                            state.gpsHealthy, 
                            state.isConnected,
                            state.gpsNumSat > 0 ? '${state.gpsNumSat} sat' : null,
                          ),
                          _buildSensorChip('Range', Icons.height, state.rangefinderHealthy, state.isConnected),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.isConnected
                            ? 'Flight controller ready • Use tabs to configure'
                            : 'Connect via serial port to begin configuration',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
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

  bool _getOverallSensorHealth(state) {
    if (!state.isConnected) return false;
    // At minimum, gyro and accelerometer should be healthy
    return state.gyroHealthy && state.accHealthy;
  }

  Widget _buildSensorChip(String label, IconData icon, bool isHealthy, bool isConnected) {
    final Color statusColor = !isConnected 
        ? AppColors.textHint 
        : isHealthy 
            ? AppColors.success 
            : AppColors.danger;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: statusColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorChipWithValue(String label, IconData icon, bool isHealthy, bool isConnected, String? value) {
    final Color statusColor = !isConnected 
        ? AppColors.textHint 
        : isHealthy 
            ? AppColors.success 
            : AppColors.danger;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: statusColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 4),
            Text(
              '($value)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: statusColor.withOpacity(0.8),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, IconData icon, {Color? color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color ?? AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color ?? AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBatteryColor(int percentage) {
    if (percentage > 60) return AppColors.success;
    if (percentage > 30) return AppColors.warning;
    return AppColors.danger;
  }

  IconData _getBatteryIcon(int percentage) {
    if (percentage > 80) return Icons.battery_full;
    if (percentage > 60) return Icons.battery_6_bar;
    if (percentage > 40) return Icons.battery_4_bar;
    if (percentage > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}
