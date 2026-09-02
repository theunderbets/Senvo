class SleepContext {
  const SleepContext({
    required this.sleepDuration,
    this.sleepQuality,
    required this.sleepStart,
    required this.sleepEnd,
  });
  
  final Duration sleepDuration;
  final double? sleepQuality; // 0.0 to 1.0
  final DateTime sleepStart;
  final DateTime sleepEnd;
}
