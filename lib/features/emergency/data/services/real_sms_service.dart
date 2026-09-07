import 'package:url_launcher/url_launcher.dart';
import 'package:telephony/telephony.dart';
import '../../domain/emergency_models.dart';

class RealSmsService implements EmergencySmsService {
  @override
  Future<SmsDispatchResult> sendEmergencySms(
    EmergencyMessage message,
    List<EmergencyContact> contacts,
  ) async {
    if (contacts.isEmpty) {
      return SmsDispatchResult(
        alertId: message.alertId,
        status: SmsDispatchStatus.failed,
        contactsAttempted: 0,
        contactsSuccessful: 0,
        errorCode: 'no_contacts',
      );
    }

    // Build the message body
    final buffer = StringBuffer();
    buffer.writeln('EMERGENCY ALERT: ${message.explanation}');
    
    if (message.vitals != null) {
      buffer.writeln('Heart Rate: ${message.vitals!.heartRateBpm?.round() ?? '--'} BPM');
      buffer.writeln('SpO2: ${((message.vitals!.spo2Percent ?? 0.0) * 100).round()}%');
    }
    
    if (message.location != null) {
      buffer.writeln('Location: ${message.location!.mapsUrl}');
    }

    final unencodedBody = buffer.toString();
    final body = Uri.encodeComponent(unencodedBody);
    
    // Attempt silent SMS dispatch using telephony
    try {
      final telephony = Telephony.instance;
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      
      if (permissionsGranted != null && permissionsGranted) {
        int successfulCount = 0;
        for (var contact in contacts) {
          try {
            await telephony.sendSms(to: contact.phoneNumber, message: unencodedBody);
            successfulCount++;
          } catch (e) {
            // Log or ignore individual failures, try next
          }
        }
        
        if (successfulCount > 0) {
          return SmsDispatchResult(
            alertId: message.alertId,
            status: SmsDispatchStatus.sent,
            contactsAttempted: contacts.length,
            contactsSuccessful: successfulCount,
          );
        }
      }
    } catch (e) {
      // Fall through to url_launcher if telephony fails
    }

    // Fallback to url_launcher if silent dispatch is not permitted or fails
    final phoneNumbers = contacts.map((c) => c.phoneNumber).join(',');
    final uri = Uri.parse('sms:$phoneNumbers?body=$body');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return SmsDispatchResult(
          alertId: message.alertId,
          status: SmsDispatchStatus.sent,
          contactsAttempted: contacts.length,
          contactsSuccessful: contacts.length, // Assume all successful for intent
        );
      } else {
        return SmsDispatchResult(
          alertId: message.alertId,
          status: SmsDispatchStatus.unsupported,
          contactsAttempted: contacts.length,
          contactsSuccessful: 0,
          errorCode: 'cannot_launch_sms',
        );
      }
    } catch (e) {
      return SmsDispatchResult(
        alertId: message.alertId,
        status: SmsDispatchStatus.failed,
        contactsAttempted: contacts.length,
        contactsSuccessful: 0,
        errorCode: e.toString(),
      );
    }
  }
}
