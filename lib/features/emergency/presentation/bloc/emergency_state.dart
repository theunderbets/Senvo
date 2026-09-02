import '../../domain/emergency_models.dart';

abstract class EmergencyState {}

class EmergencyIdle extends EmergencyState {}

class EmergencyActive extends EmergencyState {
  final EmergencyAlertType alertType;
  final String explanation;
  final SmsDispatchStatus? smsStatus;

  EmergencyActive({
    required this.alertType,
    required this.explanation,
    this.smsStatus,
  });
}
