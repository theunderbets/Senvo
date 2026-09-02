import 'dart:math' as math;

class MotionSample {
  const MotionSample({
    required this.timestamp,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  final DateTime timestamp;
  final double ax, ay, az, gx, gy, gz;
  double get accelerationMagnitude => math.sqrt(ax * ax + ay * ay + az * az);
  double get gyroscopeMagnitude => math.sqrt(gx * gx + gy * gy + gz * gz);
}

enum FallDetectionState {
  monitoring,
  possibleFreeFall,
  impactDetected,
  postImpactMonitoring,
  probableFall,
  awaitingConfirmation,
  confirmedFall,
  recovered,
}

class FallDetectionConfig {
  const FallDetectionConfig({
    this.freeFallThreshold = 2.5,
    this.minimumFreeFallDuration = const Duration(milliseconds: 120),
    this.impactThreshold = 25,
    this.maximumFreeFallToImpactWindow = const Duration(seconds: 2),
    this.postImpactInactivityDuration = const Duration(seconds: 2),
    this.inactivityVarianceThreshold = 1.5,
    this.inactivityGyroThreshold = 1.5,
    this.confirmationConfidenceThreshold = .7,
  });

  final double freeFallThreshold;
  final Duration minimumFreeFallDuration;
  final double impactThreshold;
  final Duration maximumFreeFallToImpactWindow;
  final Duration postImpactInactivityDuration;
  final double inactivityVarianceThreshold;
  final double inactivityGyroThreshold;
  final double confirmationConfidenceThreshold;
}

class FallEvidence {
  const FallEvidence({
    required this.freeFallDetected,
    required this.impactDetected,
    required this.inactivityDetected,
    required this.impactMagnitude,
    required this.freeFallDuration,
    required this.postImpactActivity,
    required this.confidence,
  });

  final bool freeFallDetected;
  final bool impactDetected;
  final bool inactivityDetected;
  final double impactMagnitude;
  final double freeFallDuration;
  final double postImpactActivity;
  final double confidence;
}

class FallDetectionEngine {
  FallDetectionEngine({this.config = const FallDetectionConfig()});

  final FallDetectionConfig config;
  FallDetectionState state = FallDetectionState.monitoring;
  DateTime? _freeFallStarted;
  DateTime? _impactAt;
  final List<MotionSample> _postImpactSamples = [];
  double _impactMagnitude = 0;
  bool _angularChange = false;

  FallEvidence? process(MotionSample sample) {
    if (!_valid(sample)) return null;
    final acceleration = sample.accelerationMagnitude;
    final gyro = sample.gyroscopeMagnitude;
    switch (state) {
      case FallDetectionState.monitoring:
        if (acceleration < config.freeFallThreshold) {
          _freeFallStarted = sample.timestamp;
          state = FallDetectionState.possibleFreeFall;
        }
      case FallDetectionState.possibleFreeFall:
        final started = _freeFallStarted;
        if (started == null ||
            sample.timestamp.difference(started) >
                config.maximumFreeFallToImpactWindow) {
          reset();
        } else if (acceleration >= config.impactThreshold &&
            sample.timestamp.difference(started) >=
                config.minimumFreeFallDuration) {
          _impactAt = sample.timestamp;
          _impactMagnitude = acceleration;
          _postImpactSamples.clear();
          _angularChange = gyro >= config.inactivityGyroThreshold * 3;
          state = FallDetectionState.impactDetected;
        }
      case FallDetectionState.impactDetected:
        _postImpactSamples.add(sample);
        state = FallDetectionState.postImpactMonitoring;
      case FallDetectionState.postImpactMonitoring:
        _postImpactSamples.add(sample);
        _angularChange =
            _angularChange || gyro >= config.inactivityGyroThreshold * 3;
        final impactAt = _impactAt;
        if (impactAt == null ||
            sample.timestamp.difference(impactAt) >=
                config.postImpactInactivityDuration) {
          final activity = _activityScore();
          final inactive =
              activity <= config.inactivityVarianceThreshold &&
              _averageGyro() <= config.inactivityGyroThreshold;
          final confidence = _confidence(inactive);
          final evidence = FallEvidence(
            freeFallDetected: true,
            impactDetected: true,
            inactivityDetected: inactive,
            impactMagnitude: _impactMagnitude,
            freeFallDuration: impactAt == null || _freeFallStarted == null
                ? 0
                : impactAt.difference(_freeFallStarted!).inMilliseconds / 1000,
            postImpactActivity: activity,
            confidence: confidence,
          );
          if (inactive && _angularChange) {
            state = FallDetectionState.probableFall;
          }
          return evidence;
        }
      case FallDetectionState.probableFall:
      case FallDetectionState.awaitingConfirmation:
      case FallDetectionState.confirmedFall:
      case FallDetectionState.recovered:
        break;
    }
    return null;
  }

  void beginConfirmation() {
    if (state == FallDetectionState.probableFall) {
      state = FallDetectionState.awaitingConfirmation;
    }
  }

  void confirmFall() {
    if (state == FallDetectionState.awaitingConfirmation) {
      state = FallDetectionState.confirmedFall;
    }
  }

  void recover() {
    state = FallDetectionState.recovered;
    reset();
  }

  void reset() {
    state = FallDetectionState.monitoring;
    _freeFallStarted = null;
    _impactAt = null;
    _postImpactSamples.clear();
    _impactMagnitude = 0;
    _angularChange = false;
  }

  bool _valid(MotionSample s) =>
      [s.ax, s.ay, s.az, s.gx, s.gy, s.gz].every((v) => v.isFinite);
  double _averageGyro() => _postImpactSamples.isEmpty
      ? double.infinity
      : _postImpactSamples
                .map((s) => s.gyroscopeMagnitude)
                .reduce((a, b) => a + b) /
            _postImpactSamples.length;
  double _activityScore() {
    if (_postImpactSamples.length < 2) return double.infinity;
    final values = _postImpactSamples
        .map((s) => s.accelerationMagnitude)
        .toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
  }

  double _confidence(bool inactive) =>
      [
        _freeFallStarted != null,
        _impactAt != null,
        inactive,
        _angularChange,
      ].where((value) => value).length /
      4;
}
