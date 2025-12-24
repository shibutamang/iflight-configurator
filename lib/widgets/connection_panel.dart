import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_controller_provider.dart';
import '../services/serial_service.dart';
import '../utils/app_colors.dart';

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({super.key});

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  String? _selectedPort;
  List<String> _availablePorts = [];

  @override
  void initState() {
    super.initState();
    _refreshPorts();
  }

  void _refreshPorts() {
    final serialService = Provider.of<SerialService>(context, listen: false);
    setState(() {
      _availablePorts = serialService.getAvailablePorts();
      if (_selectedPort != null && !_availablePorts.contains(_selectedPort)) {
        _selectedPort = null;
      }
    });
  }

  Future<void> _connect() async {
    if (_selectedPort == null) return;

    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    bool success = await provider.connect(_selectedPort!);
    
    if (!mounted) return;
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to flight controller'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final provider = Provider.of<FlightControllerProvider>(context, listen: false);
    await provider.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightControllerProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Port Selector
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Port:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPort,
                              isExpanded: true,
                              isDense: true,
                              underline: const SizedBox(),
                              hint: const Text(
                                'Select Port',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 14,
                                ),
                              ),
                              dropdownColor: AppColors.cardBg,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              items: _availablePorts.map((port) {
                                return DropdownMenuItem(
                                  value: port,
                                  child: Text(port),
                                );
                              }).toList(),
                              onChanged: state.isConnected
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedPort = value;
                                      });
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: state.isConnected
                                ? AppColors.textHint
                                : AppColors.primary,
                            size: 20,
                          ),
                          onPressed: state.isConnected ? null : _refreshPorts,
                          tooltip: 'Refresh Ports',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Connect/Disconnect Button
                  ElevatedButton(
                    onPressed: state.isConnected
                        ? _disconnect
                        : (_selectedPort != null ? _connect : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isConnected
                          ? AppColors.danger
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      state.isConnected ? 'Disconnect' : 'Connect',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (state.isConnected
                          ? AppColors.success
                          : AppColors.danger).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: state.isConnected
                            ? AppColors.success
                            : AppColors.danger,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: state.isConnected
                              ? AppColors.success
                              : AppColors.danger,
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: state.isConnected
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Version & Status
                  if (state.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'v${state.firmwareVersion}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: state.isArmed
                            ? AppColors.danger
                            : AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.isArmed ? 'ARMED' : 'DISARMED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}

