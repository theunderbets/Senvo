import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/senvo_theme.dart';
import 'presentation/splash/splash_page.dart';
import 'features/ppg_scan/data/repositories/camera_ppg_repository.dart';
import 'features/ppg_scan/domain/usecases/vital_estimators.dart';
import 'features/ppg_scan/presentation/bloc/ppg_scan_bloc.dart';
import 'features/vitals_history/data/datasources/local_vitals_datasource.dart';
import 'features/vitals_history/data/repositories/vitals_repository_impl.dart';
import 'features/vitals_history/presentation/bloc/history_bloc.dart';
import 'features/health_risk/presentation/bloc/health_risk_bloc.dart';
import 'features/health_risk/domain/engines/unified_risk_engine.dart';
import 'features/health_risk/data/repositories/health_risk_repository_impl.dart';
import 'features/health_intelligence/domain/engines/intelligence_engine.dart';
import 'features/health_intelligence/presentation/bloc/intelligence_bloc.dart';
import 'features/health_intelligence/presentation/bloc/intelligence_event.dart';
import 'core/database/database_key_manager.dart';
import 'core/database/database_manager.dart';
import 'core/security/secure_storage_service.dart';
import 'core/environment/environment_repository.dart';
import 'services/camera/camera_service.dart';
import 'services/camera/frame_processor.dart';
import 'services/permissions/permission_service.dart';
import 'services/tflite/tflite_vital_inference_service.dart';

import 'features/emergency/domain/emergency_models.dart';
import 'features/emergency/presentation/bloc/emergency_bloc.dart';
import 'features/emergency/presentation/widgets/emergency_overlay.dart';
import 'features/emergency/data/services/real_location_service.dart';
import 'features/emergency/data/services/real_sms_service.dart';
import 'core/mocks/mock_repositories.dart';
import 'core/activity/sensor_activity_repository.dart';
import 'core/activity/activity_repository.dart';
import 'core/environment/openweathermap_repository.dart';
import 'core/sleep/sensor_sleep_repository.dart';
import 'core/sleep/sleep_repository.dart';

import 'features/emergency/domain/fall_detection.dart';
import 'features/emergency/domain/fall_detection_service.dart';

import 'features/disaster_mode/domain/disaster_service.dart';
import 'features/disaster_mode/presentation/bloc/disaster_mode_bloc.dart';
import 'features/disaster_mode/presentation/bloc/disaster_mode_event.dart';

import 'services/notifications/notification_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'presentation/settings/bloc/app_settings_cubit.dart';
import 'presentation/settings/bloc/app_settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  final database = DatabaseManager(
    keyManager: SecureDatabaseKeyManager(FlutterSecureStorageService()),
  );
  await database.initialize();
  final vitalsRepository = VitalsRepositoryImpl(
    LocalVitalsDataSource(database),
  );
  final camera = CameraService();
  final repository = CameraPpgRepository(
    permissions: PermissionService(),
    camera: camera,
    processor: CameraFrameProcessor(),
  );
  
  final emergencyOrchestrator = EmergencyOrchestrator(
    locationService: RealLocationService(),
    smsService: RealSmsService(),
    contacts: const [
      // TODO: Fetch real contacts from user settings
      EmergencyContact(name: 'Emergency Services', phoneNumber: '911'),
    ],
  );

  final environmentRepository = OpenWeatherMapRepository(
    apiKey: '5c0ed740e0fcaba6a9d29ad924892145',
  );
  final sleepRepository = SensorSleepRepository();
  final activityRepository = SensorActivityRepository();

  final emergencyBloc = EmergencyBloc(orchestrator: emergencyOrchestrator);
  final disasterService = DisasterModeServiceImpl(locationService: RealLocationService());
  final disasterBloc = DisasterModeBloc(disasterService: disasterService)..add(CheckDisasterReadiness());
  final fallDetectionService = FallDetectionService(
    engine: FallDetectionEngine(),
    emergencyBloc: emergencyBloc,
  );
  fallDetectionService.start();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    SenvoApp(
      prefs: prefs,
      camera: camera,
      repository: repository,
      vitalsRepository: vitalsRepository,
      environmentRepository: environmentRepository,
      sleepRepository: sleepRepository,
      activityRepository: activityRepository,
      emergencyOrchestrator: emergencyOrchestrator,
      emergencyBloc: emergencyBloc,
      disasterBloc: disasterBloc,
    ),
  );
}

class SenvoApp extends StatelessWidget {
  const SenvoApp({
    required this.prefs,
    required this.camera,
    required this.repository,
    required this.vitalsRepository,
    required this.environmentRepository,
    required this.sleepRepository,
    required this.activityRepository,
    required this.emergencyOrchestrator,
    required this.emergencyBloc,
    required this.disasterBloc,
    super.key,
  });
  final SharedPreferences prefs;
  final CameraService camera;
  final CameraPpgRepository repository;
  final VitalsRepositoryImpl vitalsRepository;
  final EnvironmentRepository environmentRepository;
  final SleepRepository sleepRepository;
  final ActivityRepository activityRepository;
  final EmergencyOrchestrator emergencyOrchestrator;
  final EmergencyBloc emergencyBloc;
  final DisasterModeBloc disasterBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PpgScanBloc(
            repository: repository,
            estimator: TFLiteVitalEstimator(TFLiteVitalInferenceService()),
            vitalsRepository: vitalsRepository,
          ),
        ),
        BlocProvider.value(
          value: emergencyBloc,
        ),
        BlocProvider.value(
          value: disasterBloc,
        ),
        BlocProvider(
          create: (_) => HistoryBloc(vitalsRepository),
        ),
        BlocProvider(
          create: (context) => HealthRiskBloc(
            engine: UnifiedHealthRiskEngine(),
            riskRepository: HealthRiskRepositoryImpl(),
            activityRepository: activityRepository,
            sleepRepository: sleepRepository,
            vitalsRepository: vitalsRepository,
            environmentRepository: environmentRepository,
            emergencyBloc: emergencyBloc,
          ),
        ),
        BlocProvider(
          create: (context) => IntelligenceBloc(
            engine: HealthIntelligenceEngine(),
            riskRepository: HealthRiskRepositoryImpl(),
            vitalsRepository: vitalsRepository,
            activityRepository: activityRepository,
            sleepRepository: sleepRepository,
            environmentRepository: environmentRepository,
          )..add(const GenerateInsights()),
        ),
        BlocProvider(
          create: (_) => AppSettingsCubit(prefs),
        ),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Senvo',
            themeMode: settingsState.themeMode,
            theme: SenvoTheme.lightTheme,
            darkTheme: SenvoTheme.darkTheme,
            locale: settingsState.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('or'),
            ],
            home: EmergencyOverlayListener(
              child: SplashPage(
                camera: camera,
                vitalsRepository: vitalsRepository,
                environmentRepository: environmentRepository,
                sleepRepository: sleepRepository,
                activityRepository: activityRepository,
              ),
            ),
          );
        },
      ),
    );
  }
}
