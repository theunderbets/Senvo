import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'fall_detection.dart';
import '../presentation/bloc/emergency_bloc.dart';
import '../presentation/bloc/emergency_event.dart';
import 'emergency_models.dart';

class FallDetectionService {
  FallDetectionService({
    required this.engine,
    required this.emergencyBloc,
  });

  final FallDetectionEngine engine;
  final EmergencyBloc emergencyBloc;

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  GyroscopeEvent? _latestGyro;
  bool _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    
    _gyroSub = gyroscopeEventStream().listen((event) {
      _latestGyro = event;
    });

    _accelSub = userAccelerometerEventStream().listen((event) {
      final gyro = _latestGyro;
      final sample = MotionSample(
        timestamp: DateTime.now(),
        ax: event.x,
        ay: event.y,
        az: event.z,
        gx: gyro?.x ?? 0.0,
        gy: gyro?.y ?? 0.0,
        gz: gyro?.z ?? 0.0,
      );

      final evidence = engine.process(sample);
      if (evidence != null) {
        if (engine.state == FallDetectionState.probableFall) {
           engine.beginConfirmation();
           emergencyBloc.add(TriggerEmergency(
             alertType: EmergencyAlertType.fallDetected,
             fallEvidence: evidence,
             customHeadline: 'Hard fall detected! Initiating emergency response.',
           ));
        }
      }
    });
  }

  void stop() {
    _isRunning = false;
    _accelSub?.cancel();
    _accelSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    engine.reset();
  }
}
