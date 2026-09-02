import '../../domain/emergency_models.dart';
import '../../domain/fall_detection.dart';
import '../../../heat_stress/domain/heat_stress_models.dart';

abstract class EmergencyEvent {}

class TriggerEmergency extends EmergencyEvent {
  final EmergencyAlertType alertType;
  final FallEvidence? fallEvidence;
  final HeatStressRiskResult? riskResult;
  final String? customHeadline;

  TriggerEmergency({
    required this.alertType,
    this.fallEvidence,
    this.riskResult,
    this.customHeadline,
  });
}

class CancelEmergency extends EmergencyEvent {}
