enum EnvironmentalDataSource {
  liveNetwork,
  localCache,
  bundledFallback,
  unavailable,
}

enum BaselineStatus { available, insufficientData, stale, unavailable }

enum HeatStressRiskLevel { normal, watch, alert, emergency }

enum RiskFactorSeverity { info, moderate, high, severe }

enum EnvironmentalFreshness { fresh, stale, expired, unavailable }

class CurrentVitals {
  const CurrentVitals({
    this.heartRateBpm,
    this.spo2Percent,
    this.systolicBp,
    this.diastolicBp,
    required this.signalQuality,
    required this.timestamp,
  });

  final double? heartRateBpm;
  final double? spo2Percent;
  final double? systolicBp;
  final double? diastolicBp;
  final double signalQuality;
  final DateTime timestamp;
}

class EnvironmentalMetrics {
  const EnvironmentalMetrics({
    required this.temperatureCelsius,
    required this.relativeHumidityPercent,
    required this.aqi,
    required this.observedAt,
    required this.source,
  });

  final double temperatureCelsius;
  final double relativeHumidityPercent;
  final double? aqi;
  final DateTime observedAt;
  final EnvironmentalDataSource source;
}

class CachedEnvironmentalMetrics {
  const CachedEnvironmentalMetrics({
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.aqi,
    required this.observedAt,
    required this.cachedAt,
  });

  final double temperatureCelsius;
  final double humidityPercent;
  final double? aqi;
  final DateTime observedAt;
  final DateTime cachedAt;

  EnvironmentalMetrics toMetrics() => EnvironmentalMetrics(
    temperatureCelsius: temperatureCelsius,
    relativeHumidityPercent: humidityPercent,
    aqi: aqi,
    observedAt: observedAt,
    source: EnvironmentalDataSource.localCache,
  );
}

class PersonalBaseline {
  const PersonalBaseline({
    this.averageHeartRateBpm,
    this.averageSpo2Percent,
    this.averageSystolicBp,
    this.averageDiastolicBp,
    required this.sampleCount,
    required this.windowStart,
    required this.calculatedAt,
    this.status = BaselineStatus.available,
  });

  final double? averageHeartRateBpm;
  final double? averageSpo2Percent;
  final double? averageSystolicBp;
  final double? averageDiastolicBp;
  final int sampleCount;
  final DateTime windowStart;
  final DateTime calculatedAt;
  final BaselineStatus status;
}

class RiskFactor {
  const RiskFactor({
    required this.id,
    required this.title,
    required this.description,
    required this.contribution,
    required this.severity,
  });

  final String id;
  final String title;
  final String description;
  final double contribution;
  final RiskFactorSeverity severity;
}

class EnvironmentalStress {
  const EnvironmentalStress({
    required this.temperatureScore,
    required this.humidityScore,
    required this.combinedHeatScore,
    required this.description,
    required this.aqiModifier,
  });

  final double temperatureScore;
  final double humidityScore;
  final double combinedHeatScore;
  final double aqiModifier;
  final String description;
}

class HeatEnvironmentAssessment {
  const HeatEnvironmentAssessment({
    required this.heatIndexCelsius,
    required this.stress,
  });

  final double heatIndexCelsius;
  final EnvironmentalStress stress;
}

class HeatStressRiskResult {
  const HeatStressRiskResult({
    required this.level,
    required this.riskScore,
    required this.confidence,
    required this.evaluatedAt,
    required this.vitals,
    required this.baseline,
    required this.environment,
    required this.factors,
    required this.headline,
    required this.recommendation,
    required this.baselineAvailable,
    required this.environmentalDataAvailable,
    required this.measurementQualityAcceptable,
    required this.environmentalDataAge,
    required this.baselineAge,
  });

  final HeatStressRiskLevel level;
  final double riskScore;
  final double confidence;
  final DateTime evaluatedAt;
  final CurrentVitals vitals;
  final PersonalBaseline? baseline;
  final EnvironmentalMetrics? environment;
  final List<RiskFactor> factors;
  final String headline;
  final String recommendation;
  final bool baselineAvailable;
  final bool environmentalDataAvailable;
  final bool measurementQualityAcceptable;
  final Duration? environmentalDataAge;
  final Duration? baselineAge;
}
