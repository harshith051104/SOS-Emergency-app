/// send_sms_action.dart
///
/// Production implementation of [EmergencyAction] for sending emergency SMS
/// notifications to all configured emergency contacts via the native platform
/// SMS dialer (url_launcher sms: URI scheme).
///
/// Platform behaviour:
///   Android: Opens the native SMS app pre-filled with recipients and the
///             emergency message body. The user taps Send.
///   iOS:     Opens the Messages app with the same pre-filled content.
///
/// NOTE: Silent background SMS (without opening the app) requires a native
/// Android plugin (e.g. SmsManager via MethodChannel) which is planned for
/// Phase 9. The url_launcher approach is the safest cross-platform option
/// that works without additional permissions beyond SEND_SMS.

library;

import 'package:url_launcher/url_launcher.dart';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/action_result.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/interfaces/emergency_action.dart';

class SendSmsAction implements EmergencyAction {
  @override
  String get actionId => 'send_sms';

  @override
  String get actionName => 'Send Emergency SMS';

  @override
  Future<ActionResult> execute(EmergencySessionRequest request) async {
    final sw = Stopwatch()..start();
    final contacts = request.emergencyContacts
        .where((c) => c.isNotEmpty)
        .toList();

    if (contacts.isEmpty) {
      sw.stop();
      appLogger.warning('SendSmsAction: No actionable contacts configured.');
      return ActionResult(
        actionId: actionId,
        actionName: actionName,
        success: false,
        message: 'No emergency contacts configured. Please add contacts in the Responders screen.',
        executionTimeMs: sw.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    }

    // Build the SMS message body
    final body = _buildEmergencyMessage(request);

    // Encode phone numbers and body for SMS URI
    // RFC 5724: sms:+1234,+5678?body=encoded_body
    final recipientList = contacts.join(',');
    final encodedBody = Uri.encodeComponent(body);
    final smsUri = Uri.parse('sms:$recipientList?body=$encodedBody');

    bool launched = false;
    String resultMessage;

    try {
      appLogger.info('SendSmsAction: Launching SMS for ${contacts.length} contacts.');
      if (await canLaunchUrl(smsUri)) {
        launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        // Fallback: try each contact individually
        for (final contact in contacts) {
          final singleUri = Uri.parse(
              'sms:${Uri.encodeComponent(contact)}?body=$encodedBody');
          if (await canLaunchUrl(singleUri)) {
            launched = await launchUrl(singleUri,
                mode: LaunchMode.externalApplication);
            if (launched) break;
          }
        }
      }

      resultMessage = launched
          ? 'SMS dispatcher opened for ${contacts.length} contact(s). User must tap Send.'
          : 'SMS dispatcher could not be opened on this device.';
    } catch (e, st) {
      appLogger.error('SendSmsAction: Failed to launch SMS dispatcher', e, st);
      launched = false;
      resultMessage = 'SMS dispatch failed: ${e.toString()}';
    }

    sw.stop();
    return ActionResult(
      actionId: actionId,
      actionName: actionName,
      success: launched,
      message: resultMessage,
      executionTimeMs: sw.elapsedMilliseconds,
      timestamp: DateTime.now(),
    );
  }

  String _buildEmergencyMessage(EmergencySessionRequest request) {
    final now = request.timestamp;
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day}/${now.month}/${now.year}';

    // Attempt to read location from request profile if available
    final lat = request.emergencyProfile['latitude'] as double?;
    final lng = request.emergencyProfile['longitude'] as double?;
    final locationStr = (lat != null && lng != null)
        ? 'Location: https://maps.google.com/?q=$lat,$lng'
        : 'Location: Unavailable (GPS off or permission denied)';

    final buffer = StringBuffer();
    buffer.writeln('🆘 EMERGENCY ALERT — ELLY SOS');
    buffer.writeln('Time: $timeStr on $dateStr');
    buffer.writeln(locationStr);
    buffer.writeln('Session: ${request.sessionId.substring(0, 12)}');
    if (request.decisionReasons.isNotEmpty) {
      buffer.writeln('Reason: ${request.decisionReasons.first}');
    }
    buffer.writeln('Please respond immediately. This is an automated alert.');

    return buffer.toString().trim();
  }
}
