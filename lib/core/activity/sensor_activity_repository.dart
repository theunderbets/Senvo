import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'activity_models.dart';
import 'activity_repository.dart';

/// Sensor-based activity tracking using phone accelerometer.
///
/// Uses user accelerometer events to classify activity state and
/// track active vs sedentary duration for the current app session.
class SensorActivityRepository implements ActivityRepository {
  SensorActivityRepository() {
    _startTracking();
  }

  final _controller = StreamController<ActivityContext>.broadcast();
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  Timer? _emitTimer;

  // Sliding window of magnitude values for variance computation
  final List<double> _magnitudeWindow = [];
  static const int _windowSize = 50;

  // Session tracking
  DateTime _sessionStart = DateTime.now();
  Duration _activeDuration = Duration.zero;
  Duration _sedentaryDuration = Duration.zero;
  DateTime _lastClassification = DateTime.now();
  ActivityState _currentState = ActivityState.resting;
  double _currentIntensity = 0.0;

  void _startTracking() {
    _sessionStart = DateTime.now();

    // Subscribe to user accelerometer (gravity-free)
    _accelSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_onAccelerometerEvent);

    // Emit activity context every 5 seconds
    _emitTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateDurations();
      _controller.add(_buildContext());
    });
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    // Compute magnitude of user acceleration (gravity removed)
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    _magnitudeWindow.add(magnitude);
    if (_magnitudeWindow.length > _windowSize) {
      _magnitudeWindow.removeAt(0);
    }

    if (_magnitudeWindow.length >= _windowSize) {
      _classify();
    }
  }

  void _classify() {
    // Compute variance of magnitudes in the window
    final mean = _magnitudeWindow.reduce((a, b) => a + b) / _magnitudeWindow.length;
    final variance = _magnitudeWindow.map((m) => (m - mean) * (m - mean)).reduce((a, b) => a + b) / _magnitudeWindow.length;

    // Classification thresholds (tuned for typical phone accelerometer)
    // variance < 0.5  => resting (phone mostly still)
    // variance 0.5-3  => light (gentle movement, walking slowly)
    // variance 3-10   => moderate (brisk walk, normal activity)
    // variance > 10   => vigorous (running, exercise)
    ActivityState newState;
    if (variance < 0.5) {
      newState = ActivityState.resting;
    } else if (variance < 3.0) {
      newState = ActivityState.light;
    } else if (variance < 10.0) {
      newState = ActivityState.moderate;
    } else {
      newState = ActivityState.vigorous;
    }

    // Normalize intensity: clamp variance to 0-20 range, map to 0.0-1.0
    _currentIntensity = (variance / 20.0).clamp(0.0, 1.0);
    _currentState = newState;
  }

  void _updateDurations() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastClassification);
    _lastClassification = now;

    if (_currentState == ActivityState.resting) {
      _sedentaryDuration += elapsed;
    } else {
      _activeDuration += elapsed;
    }
  }

  ActivityContext _buildContext() {
    return ActivityContext(
      state: _currentState,
      intensity: _currentIntensity,
      activeDuration: _activeDuration,
      sedentaryDuration: _sedentaryDuration,
    );
  }

  @override
  Future<ActivityContext> getCurrentActivityContext() async {
    _updateDurations();
    return _buildContext();
  }

  @override
  Future<MovementContext> getCurrentMovementContext() async {
    _updateDurations();
    return MovementContext(
      movementScore: _currentIntensity,
      activeDuration: _activeDuration,
      sedentaryDuration: _sedentaryDuration,
      measuredAt: DateTime.now(),
    );
  }

  @override
  Stream<ActivityContext> watchActivityContext() => _controller.stream;

  /// Call when the repository is no longer needed.
  void dispose() {
    _accelSub?.cancel();
    _emitTimer?.cancel();
    _controller.close();
  }
}
