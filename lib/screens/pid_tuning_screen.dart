import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_controller_provider.dart';
import '../models/pid_config.dart';
import '../utils/app_colors.dart';

class PIDTuningScreen extends StatefulWidget {
  const PIDTuningScreen({super.key});

  @override
  State<PIDTuningScreen> createState() => _PIDTuningScreenState();
}

class _PIDTuningScreenState extends State<PIDTuningScreen> {
  PIDConfig? _localConfig;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    _localConfig = provider.state.pidConfig.copyWith();
  }

  void _updateValue(String axis, String type, double value) {
    setState(() {
      _hasChanges = true;
      switch ('$axis$type') {
        case 'RollP': _localConfig = _localConfig!.copyWith(rollP: value); break;
        case 'RollI': _localConfig = _localConfig!.copyWith(rollI: value); break;
        case 'RollD': _localConfig = _localConfig!.copyWith(rollD: value); break;
        case 'PitchP': _localConfig = _localConfig!.copyWith(pitchP: value); break;
        case 'PitchI': _localConfig = _localConfig!.copyWith(pitchI: value); break;
        case 'PitchD': _localConfig = _localConfig!.copyWith(pitchD: value); break;
        case 'YawP': _localConfig = _localConfig!.copyWith(yawP: value); break;
        case 'YawI': _localConfig = _localConfig!.copyWith(yawI: value); break;
        case 'YawD': _localConfig = _localConfig!.copyWith(yawD: value); break;
      }
    });
  }

  Future<void> _save() async {
    if (_localConfig == null) return;

    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    bool success = await provider.updatePIDConfig(_localConfig!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'PID configuration saved' : 'Failed to save'),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
    if (success) setState(() => _hasChanges = false);
  }

  void _reset() {
    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    setState(() {
      _localConfig = provider.state.pidConfig.copyWith();
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_localConfig == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Roll/Pitch and Yaw Cards Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roll & Pitch
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Roll & Pitch',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPIDRow('P', _localConfig!.rollP, 0, 5, (v) => _updateValue('Roll', 'P', v)),
                        _buildPIDRow('I', _localConfig!.rollI, 0, 0.5, (v) => _updateValue('Roll', 'I', v)),
                        _buildPIDRow('D', _localConfig!.rollD, 0, 0.2, (v) => _updateValue('Roll', 'D', v)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Yaw
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rotate_right, color: AppColors.secondary, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Yaw',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPIDRow('P', _localConfig!.yawP, 0, 5, (v) => _updateValue('Yaw', 'P', v)),
                        _buildPIDRow('I', _localConfig!.yawI, 0, 0.5, (v) => _updateValue('Yaw', 'I', v)),
                        _buildPIDRow('D', _localConfig!.yawD, 0, 0.2, (v) => _updateValue('Yaw', 'D', v)),
                      ],
                    ),
                  ),
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
                  if (_hasChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: AppColors.warning, size: 12),
                          const SizedBox(width: 4),
                          const Text(
                            'Unsaved',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: _hasChanges ? _reset : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: _hasChanges ? AppColors.divider : AppColors.divider.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Save'),
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
                      'PID Tuning Tips',
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
                  '• P: Increase until oscillations, then reduce\n'
                  '• I: Add to eliminate drift and steady-state error\n'
                  '• D: Add to reduce overshoot and improve response',
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
  }

  Widget _buildPIDRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.divider,
              ),
            ),
          ),
          Container(
            width: 45,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
