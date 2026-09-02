import 'risk_enums.dart';

class BaselineDeviation {
  const BaselineDeviation({
    required this.absoluteDifference,
    required this.percentageDifference,
    required this.normalizedDeviation,
  });
  final double? absoluteDifference;
  final double? percentageDifference;
  final double normalizedDeviation;
}

class BaselineDeviationCalculator {
  const BaselineDeviationCalculator();

  BaselineDeviation calculate(
    double? current,
    double? baseline, {
    double sensitivity = 1.0,
  }) {
    if (current == null || baseline == null || baseline == 0) {
      return const BaselineDeviation(
        absoluteDifference: null,
        percentageDifference: null,
        normalizedDeviation: 0.0,
      );
    }
    final absolute = current - baseline;
    return BaselineDeviation(
      absoluteDifference: absolute,
      percentageDifference: absolute / baseline * 100.0,
      normalizedDeviation: (absolute.abs() / (baseline.abs() * sensitivity)).clamp(0.0, 1.0),
    );
  }
}

class DataAvailability {
  const DataAvailability({
    required this.completeness,
    required this.freshness,
    required this.physiologicalConfidence,
  });
  final double completeness;
  final double freshness;
  final double physiologicalConfidence;
}

class RiskConfidenceCalculator {
  const RiskConfidenceCalculator();

  double calculate({
    required List<double> componentConfidences,
    required DataAvailability availability,
  }) {
    if (componentConfidences.isEmpty) return 0.0;
    final avg = componentConfidences.reduce((a, b) => a + b) / componentConfidences.length;
    
    // Penalize confidence based on availability metrics
    final penalty = (1.0 - availability.completeness) * 0.2 + 
                    (1.0 - availability.freshness) * 0.2 + 
                    (1.0 - availability.physiologicalConfidence) * 0.2;

    return (avg - penalty).clamp(0.0, 1.0);
  }
}

class RiskUtils {
  static double calculateConfidence(int activeSensors, double avgSignalQuality, Duration dataAge, Duration maxValidAge) {
    if (dataAge > maxValidAge) return 0.0;
    
    double agePenalty = dataAge.inMinutes / maxValidAge.inMinutes;
    double confidence = avgSignalQuality * (1.0 - (agePenalty * 0.5)); // Age reduces confidence by up to 50%
    return confidence.clamp(0.0, 1.0);
  }

  static RiskLevel getRiskLevelFromScore(double score) {
    if (score >= 80) return RiskLevel.critical;
    if (score >= 60) return RiskLevel.high;
    if (score >= 40) return RiskLevel.elevated;
    if (score >= 20) return RiskLevel.moderate;
    return RiskLevel.low;
  }

  static double calculateZScore(double current, double mean, double stdDev) {
    if (stdDev == 0) return 0.0;
    return ((current - mean) / stdDev).abs();
  }
}

double normalizeRisk(double value, double low, double high) {
  if (value <= low) return 0.0;
  if (value >= high) return 1.0;
  return (value - low) / (high - low);
}
