import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_controller_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class MotorTestScreen extends StatefulWidget {
  const MotorTestScreen({super.key});

  @override
  State<MotorTestScreen> createState() => _MotorTestScreenState();
}

class _MotorTestScreenState extends State<MotorTestScreen> {
  bool _propsRemoved = false;
  bool _testModeActive = false;
  bool _useTestMode = false;
  List<int> _motorValues = [0, 0, 0, 0];
  int _masterValue = 0;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    _testModeActive = provider.state.motorTestMode;
    _motorValues = List.from(provider.state.motorStatus.motorValues);
  }

  Future<void> _enableMotorTest() async {
    if (!_propsRemoved) {
      _showSafetyWarning();
      return;
    }

    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    
    if (!provider.state.isConnected) {
      setState(() {
        _testModeActive = true;
        _useTestMode = true;
      });
      return;
    }
    
    if (provider.state.isArmed) {
      _showError('Cannot enter motor test mode while armed!');
      return;
    }

    bool success = await provider.enterMotorTest();
    
    if (!mounted) return;

    if (success) {
      setState(() {
        _testModeActive = true;
        _useTestMode = false;
      });
    } else {
      _showError('Failed to enable motor test mode');
    }
  }

  Future<void> _emergencyStop() async {
    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    
    if (!_useTestMode && provider.state.isConnected) {
      await provider.setMotorValues([0, 0, 0, 0]);
      await provider.exitMotorTest();
    }
    
    setState(() {
      _testModeActive = false;
      _useTestMode = false;
      _motorValues = [0, 0, 0, 0];
      _masterValue = 0;
    });
  }

  Future<void> _setMotor(int index, int value) async {
    if (!_testModeActive) return;

    setState(() {
      _motorValues[index] = value.clamp(MotorConfig.minValue, MotorConfig.maxValue);
    });

    if (!_useTestMode) {
      final provider = Provider.of<FlightControllerProvider>(context, listen: false);
      await provider.setMotorValues(_motorValues);
    }
  }

  Future<void> _setAllMotors(int value) async {
    if (!_testModeActive) return;

    setState(() {
      _masterValue = value.clamp(MotorConfig.minValue, MotorConfig.maxValue);
      for (int i = 0; i < 4; i++) {
        _motorValues[i] = _masterValue;
      }
    });

    if (!_useTestMode) {
      final provider = Provider.of<FlightControllerProvider>(context, listen: false);
      await provider.setMotorValues(_motorValues);
    }
  }

  void _showSafetyWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Safety Warning',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'Remove propellers before testing motors!',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightControllerProvider>(
      builder: (context, provider, child) {
        final isConnected = provider.state.isConnected;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Test Mode + Warning Banner Row
              Row(
                children: [
                  // Warning Banner (compact)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'REMOVE PROPELLERS BEFORE TESTING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isConnected) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.science, color: AppColors.warning, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _testModeActive ? 'TEST ACTIVE' : 'Test Mode',
                            style: TextStyle(
                              color: _testModeActive ? AppColors.warning : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Controls Row - Checkbox and Buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Safety Checkbox
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _propsRemoved,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() => _propsRemoved = value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Props removed',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Buttons
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: _propsRemoved && !_testModeActive ? _enableMotorTest : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          child: Text(isConnected ? 'Enable Test' : 'Enable Test Mode'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: _emergencyStop,
                          child: const Text('STOP'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_testModeActive) ...[
                const SizedBox(height: 16),

                // Motors Control Card - Horizontal Layout
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(Icons.speed, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Motor Control',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Motors + Master in horizontal row (aligned left)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Individual Motors
                            ...List.generate(4, (index) {
                              return _buildMotorControl(index);
                            }),
                            // Divider
                            Container(
                              width: 1,
                              height: 140,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              color: AppColors.divider,
                            ),
                            // Master Control
                            _buildMasterControl(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on, color: AppColors.warning, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildQuickButton('Stop', 0),
                        const SizedBox(width: 8),
                        _buildQuickButton('10%', 100),
                        const SizedBox(width: 8),
                        _buildQuickButton('25%', 250),
                        const SizedBox(width: 8),
                        _buildQuickButton('50%', 500),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMotorControl(int index) {
    final value = _motorValues[index];
    final percentage = (value / MotorConfig.maxValue * 100).round();
    
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        children: [
          // Motor label
          Text(
            'M${index + 1}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Vertical bar
          Container(
            width: 40,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    height: (value / MotorConfig.maxValue) * 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: value > 300 ? Colors.white : AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Slider
          SizedBox(
            width: 36,
            height: 80,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: MotorConfig.minValue.toDouble(),
                  max: MotorConfig.maxValue.toDouble(),
                  onChanged: (v) => _setMotor(index, v.toInt()),
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.divider,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterControl() {
    final percentage = (_masterValue / MotorConfig.maxValue * 100).round();
    
    return Column(
      children: [
        const Text(
          'Master',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.warning,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Vertical bar
        Container(
          width: 44,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 0.5),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: (_masterValue / MotorConfig.maxValue) * 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: _masterValue > 300 ? Colors.white : AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Slider
        SizedBox(
          width: 40,
          height: 80,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: _masterValue.toDouble(),
                min: MotorConfig.minValue.toDouble(),
                max: MotorConfig.maxValue.toDouble(),
                onChanged: (v) => _setAllMotors(v.toInt()),
                activeColor: AppColors.warning,
                inactiveColor: AppColors.divider,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, int value) {
    final isActive = _masterValue == value;
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: () => _setAllMotors(value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? AppColors.primary.withOpacity(0.1) : null,
          foregroundColor: isActive ? AppColors.primary : AppColors.textSecondary,
          side: BorderSide(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  void dispose() {
    if (_testModeActive) {
      _emergencyStop();
    }
    super.dispose();
  }
}
