import '../../heat_stress/domain/heat_stress_models.dart';
import 'fall_detection.dart';

enum EmergencyAlertType { fallDetected, heatStressEmergency, manualEmergency }

enum SmsDispatchStatus {
  sent,
  failed,
  permissionDenied,
  unsupported,
  noSim,
  serviceUnavailable,
  cancelled,
}

enum EmergencyStatus {
  idle,
  possibleFall,
  confirmationPending,
  preparingAlert,
  acquiringLocation,
  sendingSms,
  sent,
  partiallySent,
  failed,
  cancelled,
}

class CachedLocation {
  const CachedLocation({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.accuracy,
  });
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final double accuracy;
  String get mapsUrl => 'https://www.google.com/maps?q=$latitude,$longitude';
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.enabled = true,
  });
  final String name;
  final String phoneNumber;
  final bool enabled;
}

class EmergencyMessage {
  const EmergencyMessage({
    required this.alertId,
    required this.alertType,
    required this.timestamp,
    required this.explanation,
    this.vitals,
    this.location,
    this.fallConfidence,
  });
  final String alertId;
  final EmergencyAlertType alertType;
  final DateTime timestamp;
  final CurrentVitals? vitals;
  final CachedLocation? location;
  final double? fallConfidence;
  final String explanation;
}

class SmsDispatchResult {
  const SmsDispatchResult({
    required this.alertId,
    required this.status,
    required this.contactsAttempted,
    required this.contactsSuccessful,
    this.errorCode,
  });
  final String alertId;
  final SmsDispatchStatus status;
  final int contactsAttempted;
  final int contactsSuccessful;
  final String? errorCode;
}

abstract interface class EmergencySmsService {
  Future<SmsDispatchResult> sendEmergencySms(
    EmergencyMessage message,
    List<EmergencyContact> contacts,
  );
}

abstract interface class LocationService {
  Future<CachedLocation?> getCachedLocation();
  Future<CachedLocation?> getFreshLocation({required Duration timeout});
}

class EmergencySystemConfig {
  const EmergencySystemConfig({
    this.locationTimeout = const Duration(seconds: 8),
    this.maximumCachedLocationAge = const Duration(hours: 6),
    this.maxSmsRetries = 2,
    this.requireUserConfirmation = true,
    this.emergencyFallConfidenceThreshold = .75,
  });
  final Duration locationTimeout;
  final Duration maximumCachedLocationAge;
  final int maxSmsRetries;
  final bool requireUserConfirmation;
  final double emergencyFallConfidenceThreshold;
}

class EmergencyOrchestrator {
  EmergencyOrchestrator({
    required this.locationService,
    required this.smsService,
    required this.contacts,
    this.config = const EmergencySystemConfig(),
    this.idFactory = _defaultId,
  });
  final LocationService locationService;
  final EmergencySmsService smsService;
  final List<EmergencyContact> contacts;
  final EmergencySystemConfig config;
  final String Function() idFactory;
  String? _activeAlertId;

  Future<SmsDispatchResult> trigger({
    required EmergencyAlertType alertType,
    FallEvidence? fallEvidence,
    HeatStressRiskResult? riskResult,
    CurrentVitals? vitals,
  }) async {
    if (_activeAlertId != null) {
      return SmsDispatchResult(
        alertId: _activeAlertId!,
        status: SmsDispatchStatus.cancelled,
        contactsAttempted: 0,
        contactsSuccessful: 0,
        errorCode: 'duplicate_alert',
      );
    }
    if (fallEvidence != null &&
        fallEvidence.confidence < config.emergencyFallConfidenceThreshold) {
      return const SmsDispatchResult(
        alertId: '',
        status: SmsDispatchStatus.cancelled,
        contactsAttempted: 0,
        contactsSuccessful: 0,
        errorCode: 'confirmation_required',
      );
    }
    final alertId = idFactory();
    _activeAlertId = alertId;
    var location = await locationService.getCachedLocation();
    if (location != null &&
        DateTime.now().difference(location.capturedAt) >
            config.maximumCachedLocationAge) {
      location = null;
    }
    location ??= await locationService.getFreshLocation(
      timeout: config.locationTimeout,
    );
    final message = EmergencyMessage(
      alertId: alertId,
      alertType: alertType,
      timestamp: DateTime.now(),
      explanation:
          riskResult?.headline ??
          'Possible fall detected. Please check on the user.',
      vitals: vitals,
      location: location,
      fallConfidence: fallEvidence?.confidence,
    );
    SmsDispatchResult result = const SmsDispatchResult(
      alertId: '',
      status: SmsDispatchStatus.failed,
      contactsAttempted: 0,
      contactsSuccessful: 0,
    );
    for (var attempt = 0; attempt < config.maxSmsRetries; attempt++) {
      result = await smsService.sendEmergencySms(
        message,
        contacts.where((contact) => contact.enabled).toList(growable: false),
      );
      if (result.status == SmsDispatchStatus.sent ||
          result.status == SmsDispatchStatus.permissionDenied ||
          result.status == SmsDispatchStatus.unsupported ||
          result.status == SmsDispatchStatus.noSim) {
        break;
      }
    }
    return result;
  }

  void clearActiveIncident() => _activeAlertId = null;
}

String _defaultId() => DateTime.now().microsecondsSinceEpoch.toString();
