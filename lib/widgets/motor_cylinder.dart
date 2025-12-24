import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class MotorCylinder extends StatelessWidget {
  final int motorNumber;
  final int value; // 0-1000
  final ValueChanged<int>? onChanged;
  final bool enabled;

  const MotorCylinder({
    super.key,
    required this.motorNumber,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / MotorConfig.maxValue * 100).round();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Motor label
        Text(
          'M${motorNumber + 1}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: enabled ? AppColors.primary : AppColors.light.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        
        // Percentage display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getColorForValue(percentage),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Cylinder container
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final filledHeight = (value / MotorConfig.maxValue) * height;
              
              return Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Background cylinder
                    Container(
                      width: 60,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.light.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    
                    // Filled cylinder
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 60,
                      height: filledHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: _getGradientForValue(percentage),
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _getColorForValue(percentage).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    
                    // Value indicator line
                    if (value > 0)
                      Positioned(
                        bottom: filledHeight - 2,
                        child: Container(
                          width: 64,
                          height: 2,
                          color: AppColors.light,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Value display
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.light.withValues(alpha: 0.7),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Individual slider
        SizedBox(
          width: 80,
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
              activeColor: _getColorForValue(percentage),
              inactiveColor: AppColors.surface,
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForValue(int percentage) {
    if (percentage == 0) {
      return AppColors.light.withValues(alpha: 0.3);
    } else if (percentage < 30) {
      return AppColors.success;
    } else if (percentage < 70) {
      return AppColors.warning;
    } else {
      return AppColors.danger;
    }
  }

  List<Color> _getGradientForValue(int percentage) {
    final baseColor = _getColorForValue(percentage);
    return [
      baseColor,
      baseColor.withValues(alpha: 0.8),
    ];
  }
}

