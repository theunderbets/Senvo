import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/senvo_theme.dart';
import '../layout/senvo_main_layout.dart';
import '../../core/environment/environment_repository.dart';
import '../../core/activity/activity_repository.dart';
import '../../core/sleep/sleep_repository.dart';
import '../../services/camera/camera_service.dart';
import '../../features/vitals_history/data/repositories/vitals_repository_impl.dart';

class SplashPage extends StatefulWidget {
  final CameraService camera;
  final EnvironmentRepository environmentRepository;
  final ActivityRepository activityRepository;
  final SleepRepository sleepRepository;
  final VitalsRepositoryImpl vitalsRepository;

  const SplashPage({
    super.key,
    required this.camera,
    required this.environmentRepository,
    required this.activityRepository,
    required this.sleepRepository,
    required this.vitalsRepository,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize preferences or any required async services
    await SharedPreferences.getInstance();

    // Wait a bit to show the splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SenvoMainLayout(
            camera: widget.camera,
            environmentRepository: widget.environmentRepository,
            activityRepository: widget.activityRepository,
            sleepRepository: widget.sleepRepository,
            vitalsRepository: widget.vitalsRepository,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SenvoColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/images/senvo_logo_original.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Your health, watched over - quietly, privately, offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: SenvoColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/cvrgu_logo.jpg',
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'C.V. Raman Global University',
                    style: TextStyle(
                      fontSize: 14,
                      color: SenvoColors.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset(
                    'assets/images/make_in_india.jpg',
                    height: 50,
                  ),
                  Image.asset(
                    'assets/images/skill_india.jpg',
                    height: 50,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The Underbets',
                style: TextStyle(
                  fontSize: 12,
                  color: SenvoColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
