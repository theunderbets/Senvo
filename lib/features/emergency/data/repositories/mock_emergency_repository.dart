import '../../domain/emergency_models.dart';

class MockLocationService implements LocationService {
  @override
  Future<CachedLocation?> getCachedLocation() async {
    return CachedLocation(
      latitude: 37.7749,
      longitude: -122.4194,
      capturedAt: DateTime.now(),
      accuracy: 10.0,
    );
  }

  @override
  Future<CachedLocation?> getFreshLocation({required Duration timeout}) async {
    await Future.delayed(const Duration(seconds: 1));
    return CachedLocation(
      latitude: 37.7749,
      longitude: -122.4194,
      capturedAt: DateTime.now(),
      accuracy: 5.0,
    );
  }
}

class MockEmergencySmsService implements EmergencySmsService {
  @override
  Future<SmsDispatchResult> sendEmergencySms(
    EmergencyMessage message,
    List<EmergencyContact> contacts,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    return SmsDispatchResult(
      alertId: message.alertId,
      status: SmsDispatchStatus.sent,
      contactsAttempted: contacts.length,
      contactsSuccessful: contacts.length,
    );
  }
}
