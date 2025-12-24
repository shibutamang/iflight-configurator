import 'package:flutter/material.dart';
import '../widgets/connection_panel.dart';
import 'home_screen.dart';
import 'imu_screen.dart';
import 'pid_tuning_screen.dart';
import 'motor_test_screen.dart';
import 'rc_monitor_screen.dart';
import 'calibration_screen.dart';
import '../utils/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Flight Controller Configurator'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Dashboard'),
                Tab(icon: Icon(Icons.sensors, size: 20), text: 'IMU'),
                Tab(icon: Icon(Icons.tune, size: 20), text: 'PID Tuning'),
                Tab(icon: Icon(Icons.speed, size: 20), text: 'Motors'),
                Tab(icon: Icon(Icons.gamepad, size: 20), text: 'RC Monitor'),
                Tab(icon: Icon(Icons.tune, size: 20), text: 'Calibration'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const ConnectionPanel(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HomeScreen(),
                IMUScreen(),
                PIDTuningScreen(),
                MotorTestScreen(),
                RCMonitorScreen(),
                CalibrationScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

