import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../dashboard/home_dashboard_page.dart';
import '../history/local_health_history_page.dart';
import '../settings/profile_page.dart';
import '../notifications/notifications_page.dart';
import '../../features/ppg_scan/presentation/pages/ppg_scan_page.dart';
import '../../features/ppg_scan/presentation/bloc/ppg_scan_bloc.dart';
import '../../services/camera/camera_service.dart';
import '../../features/vitals_history/data/repositories/vitals_repository_impl.dart';
import '../../core/environment/environment_repository.dart';
import '../../core/sleep/sleep_repository.dart';
import '../../core/activity/activity_repository.dart';
import '../../core/theme/senvo_theme.dart';

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
      const LocalHealthHistoryPage(),
      const NotificationsPage(),
      ProfilePage(
        vitalsRepository: widget.vitalsRepository,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openScanPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<PpgScanBloc>(context),
          child: PpgScanPage(
            cameraService: widget.camera,
            vitalsRepository: widget.vitalsRepository,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Needed for floating nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        onPressed: _openScanPage,
        elevation: 4,
        child: const Icon(Icons.document_scanner_outlined, color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: SenvoColors.surface, // Dark pill background
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0, 'Home'),
              _buildNavItem(Icons.history_outlined, Icons.history_rounded, 1, 'History'),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.notifications_outlined, Icons.notifications_rounded, 2, 'Alerts'),
              _buildNavItem(Icons.person_outline, Icons.person, 3, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? Colors.blueAccent : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
