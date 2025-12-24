import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class MotorBar extends StatelessWidget {
  final int motorNumber;
  final int value; // 0-1000
  final ValueChanged<int>? onChanged;
  final bool enabled;

  const MotorBar({
    super.key,
    required this.motorNumber,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Motor label
        Text(
          'M${motorNumber + 1}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
        const SizedBox(height: 8),
        
        // Vertical bar container
        Container(
          width: 80,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Filled portion
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: (value / MotorConfig.maxValue) * 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: value > 50 ? Center(
                    child: Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ) : null,
                ),
              ),
              // Value text for low values (display above bar)
              if (value <= 50)
                Positioned(
                  bottom: (value / MotorConfig.maxValue) * 200 + 4,
                  left: 0,
                  right: 0,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Individual motor slider
        SizedBox(
          width: 80,
          height: 150,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value.toDouble(),
              min: MotorConfig.minValue.toDouble(),
              max: MotorConfig.maxValue.toDouble(),
              divisions: 100,
              onChanged: enabled && onChanged != null
                  ? (v) => onChanged!(v.toInt())
                  : null,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.divider,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Slider label
        Text(
          '${MotorConfig.minValue}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

