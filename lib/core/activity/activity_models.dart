enum ActivityState { resting, light, moderate, vigorous }

class ActivityContext {
  const ActivityContext({
    required this.state,
    required this.intensity,
    this.activeDuration = Duration.zero,
    this.sedentaryDuration = Duration.zero,
  });
  
  final ActivityState state;
  final double intensity; // 0.0 to 1.0
  final Duration activeDuration;
  final Duration sedentaryDuration;
}

class MovementContext {
  const MovementContext({
    required this.movementScore,
    required this.activeDuration,
    required this.sedentaryDuration,
    required this.measuredAt,
  });
  
  final double movementScore; // 0.0 to 1.0
  final Duration activeDuration;
  final Duration sedentaryDuration;
  final DateTime measuredAt;
}
