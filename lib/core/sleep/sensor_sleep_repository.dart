import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sleep_models.dart';
import 'sleep_repository.dart';

/// Sensor-based sleep estimation using accelerometer stillness detection
/// and time-of-day heuristics.
///
/// Strategy:
/// 1. On app launch, check stored sleep data from shared_preferences.
/// 2. Monitor accelerometer for prolonged stillness during sleep hours (10pm-8am).
/// 3. When the phone is very still for extended periods during sleep hours,
///    infer sleep. Interruptions (phone pickups) reduce sleep quality.
/// 4. Persist inferred sleep data so it survives app restarts.
class SensorSleepRepository implements SleepRepository {
  SensorSleepRepository() {
    _initialize();
  }

  final _controller = StreamController<SleepContext>.broadcast();
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  Timer? _checkTimer;

  // Accelerometer tracking for stillness
  final List<double> _recentMagnitudes = [];
  static const int _stillnessWindowSize = 100;
  static const double _stillnessThreshold = 0.3; // variance below this = still

  // Sleep tracking state
  DateTime? _stillnessStart;
  int _interruptionCount = 0;
  bool _isCurrentlyStill = false;
  Duration _totalStillDuration = Duration.zero;

  // Persisted sleep data
  SleepContext? _lastSleepContext;

  // SharedPreferences keys
  static const String _keySleepStart = 'senvo_sleep_start';
  static const String _keySleepEnd = 'senvo_sleep_end';
  static const String _keySleepDurationMin = 'senvo_sleep_duration_min';
  static const String _keySleepQuality = 'senvo_sleep_quality';
  static const String _keySleepDate = 'senvo_sleep_date';

  Future<void> _initialize() async {
    // Load persisted sleep data
    await _loadPersistedSleep();

    // Start monitoring accelerometer
    _accelSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(_onAccelerometerEvent);

    // Periodically check if we should update sleep inference (every 30s)
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkAndInferSleep();
    });
  }

  Future<void> _loadPersistedSleep() async {
    const storage = FlutterSecureStorage();
    final dateStr = await storage.read(key: _keySleepDate);
    final today = _dateKey(DateTime.now());

    if (dateStr == today) {
      // We have today's sleep data
      final startMsStr = await storage.read(key: _keySleepStart);
      final endMsStr = await storage.read(key: _keySleepEnd);
      final durationMinStr = await storage.read(key: _keySleepDurationMin);
      final qualityStr = await storage.read(key: _keySleepQuality);

      final startMs = startMsStr != null ? int.tryParse(startMsStr) : null;
      final endMs = endMsStr != null ? int.tryParse(endMsStr) : null;
      final durationMin = durationMinStr != null ? int.tryParse(durationMinStr) : null;
      final quality = qualityStr != null ? double.tryParse(qualityStr) : null;

      if (startMs != null && endMs != null && durationMin != null) {
        _lastSleepContext = SleepContext(
          sleepDuration: Duration(minutes: durationMin),
          sleepQuality: quality,
          sleepStart: DateTime.fromMillisecondsSinceEpoch(startMs),
          sleepEnd: DateTime.fromMillisecondsSinceEpoch(endMs),
        );
      }
    }

    // If no data for today, try to infer from time-of-day heuristic
    if (_lastSleepContext == null) {
      _lastSleepContext = _heuristicSleepEstimate();
      await _persistSleep(_lastSleepContext!);
    }
  }

  /// Heuristic fallback: estimate sleep based on current time.
  /// If it's morning/afternoon, assume a typical sleep window occurred.
  /// If it's late evening/night, assume no sleep data yet for today.
  SleepContext _heuristicSleepEstimate() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6) {
      // After 6am: assume sleep happened last night
      // Estimate bedtime around 11pm, wake around 6:30am = ~7.5 hrs
      final sleepStart = DateTime(now.year, now.month, now.day - (hour < 4 ? 1 : 0), 23, 0);
      final sleepEnd = DateTime(now.year, now.month, now.day, 6, 30);
      final duration = sleepEnd.difference(sleepStart);

      return SleepContext(
        sleepDuration: duration.isNegative ? const Duration(hours: 7) : duration,
        sleepQuality: 0.7, // Assumed average quality
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
      );
    } else {
      // Before 6am: probably still sleeping or just woke up
      final sleepStart = DateTime(now.year, now.month, now.day - 1, 23, 0);
      final soFar = now.difference(sleepStart);

      return SleepContext(
        sleepDuration: soFar,
        sleepQuality: 0.6,
        sleepStart: sleepStart,
        sleepEnd: now,
      );
    }
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    _recentMagnitudes.add(magnitude);
    if (_recentMagnitudes.length > _stillnessWindowSize) {
      _recentMagnitudes.removeAt(0);
    }

    if (_recentMagnitudes.length >= _stillnessWindowSize) {
      _evaluateStillness();
    }
  }

  void _evaluateStillness() {
    final mean = _recentMagnitudes.reduce((a, b) => a + b) / _recentMagnitudes.length;
    final variance = _recentMagnitudes.map((m) => (m - mean) * (m - mean)).reduce((a, b) => a + b) / _recentMagnitudes.length;

    final wasStill = _isCurrentlyStill;
    _isCurrentlyStill = variance < _stillnessThreshold;

    if (_isCurrentlyStill && !wasStill) {
      // Entered stillness
      _stillnessStart = DateTime.now();
    } else if (!_isCurrentlyStill && wasStill) {
      // Left stillness — this is an interruption
      if (_stillnessStart != null) {
        _totalStillDuration += DateTime.now().difference(_stillnessStart!);
      }
      _stillnessStart = null;

      // Only count interruptions during sleep hours
      if (_isSleepHour(DateTime.now().hour)) {
        _interruptionCount++;
      }
    }
  }

  bool _isSleepHour(int hour) {
    return hour >= 22 || hour < 8;
  }

  void _checkAndInferSleep() async {
    final now = DateTime.now();
    final hour = now.hour;

    // Only re-evaluate sleep inference around wake-up time (6-10am)
    if (hour >= 6 && hour <= 10 && _totalStillDuration.inMinutes > 30) {
      // We have real stillness data from the sleep period
      final quality = _computeSleepQuality();
      final sleepEnd = now;
      final sleepStart = now.subtract(_totalStillDuration);

      final newContext = SleepContext(
        sleepDuration: _totalStillDuration,
        sleepQuality: quality,
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
      );

      _lastSleepContext = newContext;
      await _persistSleep(newContext);
      _controller.add(newContext);

      // Reset for next night
      _totalStillDuration = Duration.zero;
      _interruptionCount = 0;
    }
  }

  double _computeSleepQuality() {
    // Quality based on:
    // 1. Duration (7-9 hrs is ideal)
    // 2. Number of interruptions (fewer = better)
    final hours = _totalStillDuration.inMinutes / 60.0;

    // Duration score: 1.0 at 8 hours, drops off linearly
    final durationScore = 1.0 - ((hours - 8.0).abs() / 8.0).clamp(0.0, 0.5);

    // Interruption score: 1.0 with 0 interruptions, drops by 0.1 per interruption
    final interruptionScore = (1.0 - _interruptionCount * 0.1).clamp(0.0, 1.0);

    return ((durationScore + interruptionScore) / 2.0).clamp(0.0, 1.0);
  }

  Future<void> _persistSleep(SleepContext ctx) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _keySleepDate, value: _dateKey(DateTime.now()));
    await storage.write(key: _keySleepStart, value: ctx.sleepStart.millisecondsSinceEpoch.toString());
    await storage.write(key: _keySleepEnd, value: ctx.sleepEnd.millisecondsSinceEpoch.toString());
    await storage.write(key: _keySleepDurationMin, value: ctx.sleepDuration.inMinutes.toString());
    if (ctx.sleepQuality != null) {
      await storage.write(key: _keySleepQuality, value: ctx.sleepQuality!.toString());
    }
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  @override
  Future<SleepContext> getCurrentSleepContext() async {
    if (_lastSleepContext != null) return _lastSleepContext!;
    await _loadPersistedSleep();
    return _lastSleepContext!;
  }

  @override
  Stream<SleepContext> watchSleepContext() => _controller.stream;

  /// Call when the repository is no longer needed.
  void dispose() {
    _accelSub?.cancel();
    _checkTimer?.cancel();
    _controller.close();
  }
}
