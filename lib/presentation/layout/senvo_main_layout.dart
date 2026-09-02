import 'package:flutter/material.dart';
import '../dashboard/home_dashboard_page.dart';
import '../vitals/vitals_page.dart';
import '../../features/health_risk/presentation/pages/health_risk_dashboard_page.dart';
import '../history/local_health_history_page.dart';
import '../settings/profile_page.dart';
import '../../services/camera/camera_service.dart';
import '../../features/vitals_history/data/repositories/vitals_repository_impl.dart';
import '../../core/environment/environment_repository.dart';
import '../../core/sleep/sleep_repository.dart';
import '../../core/activity/activity_repository.dart';

class SenvoMainLayout extends StatefulWidget {
  const SenvoMainLayout({
    required this.camera,
    required this.vitalsRepository,
    required this.environmentRepository,
    required this.sleepRepository,
    required this.activityRepository,
    super.key,
  });

  final CameraService camera;
  final VitalsRepositoryImpl vitalsRepository;
  final EnvironmentRepository environmentRepository;
  final SleepRepository sleepRepository;
  final ActivityRepository activityRepository;

  @override
  State<SenvoMainLayout> createState() => _SenvoMainLayoutState();
}

class _SenvoMainLayoutState extends State<SenvoMainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeDashboardPage(
        camera: widget.camera,
        vitalsRepository: widget.vitalsRepository,
        environmentRepository: widget.environmentRepository,
        sleepRepository: widget.sleepRepository,
        activityRepository: widget.activityRepository,
      ),
      const VitalsPage(),
      const HealthRiskDashboardPage(),
      const LocalHealthHistoryPage(),
      ProfilePage(
        vitalsRepository: widget.vitalsRepository,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Vitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_amber_rounded),
            label: 'Risks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
