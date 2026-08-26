import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/ppg_scan/data/repositories/camera_ppg_repository.dart';
import 'features/ppg_scan/domain/usecases/vital_estimators.dart';
import 'features/ppg_scan/presentation/bloc/ppg_scan_bloc.dart';
import 'features/ppg_scan/presentation/pages/ppg_scan_page.dart';
import 'features/vitals_history/data/datasources/local_vitals_datasource.dart';
import 'features/vitals_history/data/repositories/vitals_repository_impl.dart';
import 'core/database/database_key_manager.dart';
import 'core/database/database_manager.dart';
import 'core/security/secure_storage_service.dart';
import 'services/camera/camera_service.dart';
import 'services/camera/frame_processor.dart';
import 'services/permissions/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(
    SenvoApp(
      camera: camera,
      repository: repository,
      vitalsRepository: vitalsRepository,
    ),
  );
}

class SenvoApp extends StatelessWidget {
  const SenvoApp({
    required this.camera,
    required this.repository,
    required this.vitalsRepository,
    super.key,
  });
  final CameraService camera;
  final CameraPpgRepository repository;
  final VitalsRepositoryImpl vitalsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Senvo',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0b1719),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff63d7b0),
          brightness: Brightness.dark,
        ),
      ),
      home: BlocProvider(
        create: (_) => PpgScanBloc(
          repository: repository,
          estimator: const ExperimentalVitalEstimator(),
          vitalsRepository: vitalsRepository,
        ),
        child: PpgScanPage(
          cameraService: camera,
          vitalsRepository: vitalsRepository,
        ),
      ),
    );
  }
}
