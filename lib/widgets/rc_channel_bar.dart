import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class RCChannelBar extends StatelessWidget {
  final String label;
  final int value;

  const RCChannelBar({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize to 0-1 range (1000-2000 μs)
    double normalized = (value - RCConfig.minValue) /
        (RCConfig.maxValue - RCConfig.minValue);
    normalized = normalized.clamp(0.0, 1.0);

    Color barColor = AppColors.primary;
    if (value < RCConfig.minValue || value > RCConfig.maxValue) {
      barColor = AppColors.danger;
    } else if ((value - RCConfig.centerValue).abs() < 50) {
      barColor = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.divider.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: normalized,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Center indicator
                Positioned(
                  left: ((RCConfig.centerValue - RCConfig.minValue) /
                          (RCConfig.maxValue - RCConfig.minValue)) *
                      MediaQuery.of(context).size.width *
                      0.7,
                  child: Container(
                    width: 2,
                    height: 32,
                    color: AppColors.textPrimary.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              '$value μs',
              style: TextStyle(
                color: barColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

