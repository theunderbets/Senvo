import 'package:url_launcher/url_launcher.dart';
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
      buffer.writeln('Heart Rate: ${message.vitals!.heartRate.round()} BPM');
      buffer.writeln('SpO2: ${(message.vitals!.spO2 * 100).round()}%');
    }
    
    if (message.location != null) {
      buffer.writeln('Location: ${message.location!.mapsUrl}');
    }

    final body = Uri.encodeComponent(buffer.toString());
    
    // We try to send to the first contact, or ideally open the SMS app with all contacts
    // For cross-platform support with url_launcher, multiple numbers can sometimes be 
    // separated by commas on Android, but it's fragile. We will use the first contact 
    // for this implementation and let the user add others manually if needed.
    
    final phoneNumbers = contacts.map((c) => c.phoneNumber).join(',');
    final uri = Uri.parse('sms:$phoneNumbers?body=$body');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return SmsDispatchResult(
          alertId: message.alertId,
          status: SmsDispatchStatus.sent,
          contactsAttempted: contacts.length,
          contactsSuccessful: contacts.length,
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
