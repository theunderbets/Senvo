class CurrentHealthSnapshot {
  const CurrentHealthSnapshot({
    required this.timestamp,
    this.heartRateBpm,
    this.spo2Percent,
    this.systolicBp,
    this.diastolicBp,
    this.bodyTemperatureCelsius,
    this.ambientTemperatureCelsius,
    this.humidityPercent,
    this.aqi,
    this.pm25,
    this.pm10,
    this.activityLevel,
    this.movementLevel,
    this.sleepDuration,
    this.signalQuality,
  });

  final DateTime timestamp;
  final double? heartRateBpm;
  final double? spo2Percent;
  final double? systolicBp;
  final double? diastolicBp;
  final double? bodyTemperatureCelsius;
  final double? ambientTemperatureCelsius;
  final double? humidityPercent;
  final double? aqi;
  final double? pm25;
  final double? pm10;
  final double? activityLevel;
  final double? movementLevel;
  final Duration? sleepDuration;
  final double? signalQuality;
}

class PersonalBaseline {
  const PersonalBaseline({
    this.age,
    this.averageHeartRateBpm,
    this.averageSpo2Percent,
    this.averageSystolicBp,
    this.averageDiastolicBp,
    this.averageBodyTemperatureCelsius,
    this.averageActivityLevel,
    required this.calculatedAt,
    required this.sampleCount,
  });

  final int? age;

  final double? averageHeartRateBpm;
  final double? averageSpo2Percent;
  final double? averageSystolicBp;
  final double? averageDiastolicBp;
  final double? averageBodyTemperatureCelsius;
  final double? averageActivityLevel;
  final DateTime calculatedAt;
  final int sampleCount;
}
