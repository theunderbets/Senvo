import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/senvo_main_layout.dart';
import '../../core/environment/environment_repository.dart';
import '../../core/activity/activity_repository.dart';
import '../../core/sleep/sleep_repository.dart';
import '../../services/camera/camera_service.dart';
import '../../features/vitals_history/data/repositories/vitals_repository_impl.dart';
import '../../l10n/app_localizations.dart';

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
    // We want the splash screen to be permanently light mode.
    // So we use hardcoded colors representing the light theme.
    final loc = AppLocalizations.of(context);
    final tagline = loc?.tagline ?? 'Your health, watched over.';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Light background
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/images/senvo_logo.png', // Logo without background
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, // Slightly increased but not as big as a title
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.asset(
                      'assets/images/cvrgu_logo.jpg',
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'C.V. Raman Global University',
                    style: TextStyle(
                      fontSize: 16, // Matching logo height conceptually
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/make_in_india.jpg',
                    height: 40,
                  ),
                  const SizedBox(width: 32),
                  Image.asset(
                    'assets/images/skill_india.jpg',
                    height: 40,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'The Underbets',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
