import '../../heat_stress/domain/heat_stress_models.dart';

class HealthAdvisoryRequest {
  const HealthAdvisoryRequest({
    required this.riskTier,
    required this.vitals,
    required this.riskFactors,
    this.environment,
    this.context,
  });
  final String riskTier;
  final CurrentVitals vitals;
  final List<String> riskFactors;
  final EnvironmentalMetrics? environment;
  final String? context;

  Map<String, dynamic> toJson() => {
    'risk_tier': riskTier,
    'vitals': {
      if (vitals.heartRateBpm != null) 'heart_rate_bpm': vitals.heartRateBpm,
      if (vitals.spo2Percent != null) 'spo2_percentage': vitals.spo2Percent,
      if (vitals.systolicBp != null && vitals.diastolicBp != null)
        'blood_pressure': {
          'systolic': vitals.systolicBp,
          'diastolic': vitals.diastolicBp,
        },
    },
    if (environment != null)
      'environment': {
        'temperature_celsius': environment!.temperatureCelsius,
        'humidity_percent': environment!.relativeHumidityPercent,
        if (environment!.aqi != null) 'aqi': environment!.aqi,
      },
    'risk_factors': List<String>.unmodifiable(riskFactors),
    if (context != null) 'context': context,
  };
}

class HealthAdvisoryResponse {
  const HealthAdvisoryResponse({
    required this.advisory,
    required this.actionSteps,
    required this.severity,
  });
  final String advisory;
  final List<String> actionSteps;
  final String severity;

  factory HealthAdvisoryResponse.fromJson(Map<String, dynamic> json) {
    final advisory = json['advisory'];
    final actions = json['action_steps'];
    final severity = json['severity'];
    if (advisory is! String ||
        advisory.trim().isEmpty ||
        actions is! List ||
        severity is! String ||
        !{'normal', 'watch', 'alert', 'emergency'}.contains(severity)) {
      throw const FormatException('Invalid advisory response');
    }
    return HealthAdvisoryResponse(
      advisory: advisory,
      actionSteps: actions.whereType<String>().toList(growable: false),
      severity: severity,
    );
  }
}

abstract interface class HealthAdvisoryService {
  Future<HealthAdvisoryResponse> getAdvisory(HealthAdvisoryRequest request);
}
