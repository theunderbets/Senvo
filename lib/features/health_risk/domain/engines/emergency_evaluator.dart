import '../../../../core/health/health_models.dart';

class EmergencyAlert {
  const EmergencyAlert({
    required this.alertType,
    required this.message,
    required this.requiresImmediateAction,
  });

  final String alertType;
  final String message;
  final bool requiresImmediateAction;
}

class EmergencyRuleEvaluator {
  List<EmergencyAlert> evaluate(CurrentHealthSnapshot snapshot) {
    final alerts = <EmergencyAlert>[];

    if (snapshot.spo2Percent != null && snapshot.spo2Percent! < 88.0) {
      alerts.add(const EmergencyAlert(
        alertType: 'Critical Hypoxia',
        message: 'Blood oxygen is dangerously low. Seek immediate medical attention.',
        requiresImmediateAction: true,
      ));
    }

    if (snapshot.heartRateBpm != null) {
      if (snapshot.heartRateBpm! > 180.0) {
        alerts.add(const EmergencyAlert(
          alertType: 'Extreme Tachycardia',
          message: 'Heart rate is critically high.',
          requiresImmediateAction: true,
        ));
      } else if (snapshot.heartRateBpm! < 40.0) {
        alerts.add(const EmergencyAlert(
          alertType: 'Extreme Bradycardia',
          message: 'Heart rate is critically low.',
          requiresImmediateAction: true,
        ));
      }
    }
    
    if (snapshot.bodyTemperatureCelsius != null) {
      if (snapshot.bodyTemperatureCelsius! >= 39.5) {
        alerts.add(const EmergencyAlert(
          alertType: 'Severe Hyperthermia',
          message: 'Body temperature is dangerously high.',
          requiresImmediateAction: true,
        ));
      } else if (snapshot.bodyTemperatureCelsius! <= 35.0) {
        alerts.add(const EmergencyAlert(
          alertType: 'Hypothermia',
          message: 'Body temperature is dangerously low.',
          requiresImmediateAction: true,
        ));
      }
    }
    
    if (snapshot.systolicBp != null && snapshot.diastolicBp != null) {
        if (snapshot.systolicBp! > 180 || snapshot.diastolicBp! > 120) {
             alerts.add(const EmergencyAlert(
              alertType: 'Hypertensive Crisis',
              message: 'Blood pressure is critically high. Seek immediate medical attention.',
              requiresImmediateAction: true,
            ));
        } else if (snapshot.systolicBp! < 80 || snapshot.diastolicBp! < 50) {
             alerts.add(const EmergencyAlert(
              alertType: 'Severe Hypotension',
              message: 'Blood pressure is critically low.',
              requiresImmediateAction: true,
            ));
        }
    }

    return alerts;
  }
}
