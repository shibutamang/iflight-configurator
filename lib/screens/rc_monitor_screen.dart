import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_controller_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class RCMonitorScreen extends StatefulWidget {
  const RCMonitorScreen({super.key});

  @override
  State<RCMonitorScreen> createState() => _RCMonitorScreenState();
}

class _RCMonitorScreenState extends State<RCMonitorScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefresh();
  }

  void _startRefresh() {
    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    // Fast polling for smooth real-time updates (50ms = 20 FPS)
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (provider.state.isConnected) {
        provider.refreshRCData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightControllerProvider>(
      builder: (context, provider, child) {
        final rcData = provider.state.rcData;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Icon(Icons.gamepad_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'RC Input Monitor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Signal Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (rcData.signalValid ? AppColors.success : AppColors.danger).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (rcData.signalValid ? AppColors.success : AppColors.danger).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rcData.signalValid ? Icons.wifi : Icons.wifi_off,
                          color: rcData.signalValid ? AppColors.success : AppColors.danger,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rcData.signalValid ? 'Signal OK' : 'No Signal',
                          style: TextStyle(
                            color: rcData.signalValid ? AppColors.success : AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      onPressed: () => provider.refreshRCData(),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main Channels Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Main Channels',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildChannelRow('Roll', rcData.roll, Icons.swap_horiz),
                      _buildChannelRow('Pitch', rcData.pitch, Icons.swap_vert),
                      _buildChannelRow('Throttle', rcData.throttle, Icons.arrow_upward),
                      _buildChannelRow('Yaw', rcData.yaw, Icons.rotate_right),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Aux Channels Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_input_component, color: AppColors.secondary, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Auxiliary Channels',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildChannelRow('AUX1', rcData.aux1, Icons.toggle_on),
                      _buildChannelRow('AUX2', rcData.aux2, Icons.toggle_on),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tips (compact)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Center: ~1500μs  •  Range: 1000-2000μs  •  Throttle down: ~1000μs',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.3,
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

  Widget _buildChannelRow(String label, int value, IconData icon) {
    Color barColor = AppColors.primary;
    if (value < RCConfig.minValue || value > RCConfig.maxValue) {
      barColor = AppColors.danger;
    } else if ((value - RCConfig.centerValue).abs() < 50) {
      barColor = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 14),
          const SizedBox(width: 6),
          SizedBox(
            width: 55,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _AnimatedChannelBar(
              value: value,
              barColor: barColor,
            ),
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: value, end: value),
            duration: const Duration(milliseconds: 50),
            builder: (context, animatedValue, child) {
              return Container(
                width: 58,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$animatedValue μs',
                  style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Animated channel bar widget for smooth transitions
class _AnimatedChannelBar extends StatefulWidget {
  final int value;
  final Color barColor;

  const _AnimatedChannelBar({
    required this.value,
    required this.barColor,
  });

  @override
  State<_AnimatedChannelBar> createState() => _AnimatedChannelBarState();
}

class _AnimatedChannelBarState extends State<_AnimatedChannelBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.toDouble();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: _currentValue,
      end: _currentValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(_AnimatedChannelBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
      
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Normalize to 0-1 range (1000-2000 μs)
        double normalized = (_animation.value - RCConfig.minValue) / 
            (RCConfig.maxValue - RCConfig.minValue);
        normalized = normalized.clamp(0.0, 1.0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final centerPosition = ((RCConfig.centerValue - RCConfig.minValue) /
                (RCConfig.maxValue - RCConfig.minValue)) * constraints.maxWidth;
            
            return Stack(
              children: [
                // Background track
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                  ),
                ),
                // Fill bar - animated width
                Container(
                  height: 16,
                  width: normalized * constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: widget.barColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Center marker
                Positioned(
                  left: centerPosition - 1,
                  child: Container(
                    width: 2,
                    height: 16,
                    color: AppColors.textPrimary.withOpacity(0.2),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
