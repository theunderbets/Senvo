import '../health/health_models.dart';

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}

class RiskValidator {
  const RiskValidator();

  ValidationResult validate(CurrentHealthSnapshot snapshot) {
    final errors = <String>[];
    _range(snapshot.heartRateBpm, 'heartRateBpm', 30, 260, errors);
    _range(snapshot.spo2Percent, 'spo2Percent', 50, 100, errors);
    _range(snapshot.systolicBp, 'systolicBp', 40, 300, errors);
    _range(snapshot.diastolicBp, 'diastolicBp', 20, 200, errors);
    _range(snapshot.bodyTemperatureCelsius, 'bodyTemperatureCelsius', 25, 45, errors);
    _range(snapshot.ambientTemperatureCelsius, 'ambientTemperatureCelsius', -50, 60, errors);
    _range(snapshot.humidityPercent, 'humidityPercent', 0, 100, errors);
    _range(snapshot.aqi, 'aqi', 0, 1000, errors);
    _range(snapshot.pm25, 'pm25', 0, 1000, errors);
    _range(snapshot.pm10, 'pm10', 0, 1000, errors);
    _range(snapshot.activityLevel, 'activityLevel', 0, 1, errors);
    _range(snapshot.movementLevel, 'movementLevel', 0, 1, errors);
    _range(snapshot.signalQuality, 'signalQuality', 0, 1, errors);

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  void _range(double? value, String name, double low, double high, List<String> errors) {
    if (value != null && (!value.isFinite || value < low || value > high)) {
      errors.add('$name is out of bounds ($low-$high): $value');
    }
  }
}
