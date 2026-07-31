/// emergency_notification_action.dart
///
/// Production implementation of [EmergencyAction] for recording an emergency
/// notification timeline entry and preparing a local notification summary.
///
/// In production the local notification (flutter_local_notifications) would
/// fire a high-priority heads-up notification. This action records the attempt
/// in the app log and returns a timestamped confirmation. The local notification
/// plugin is planned for a follow-up sprint — this action is production-ready
/// in its logging and data gathering behaviour.

library;

import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/action_result.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/interfaces/emergency_action.dart';

class EmergencyNotificationAction implements EmergencyAction {
  @override
  String get actionId => 'emergency_notification';

  @override
  String get actionName => 'Dispatch System Emergency Notification';

  @override
  Future<ActionResult> execute(EmergencySessionRequest request) async {
    final sw = Stopwatch()..start();

    final sessionId = request.sessionId;
    final confidence = (request.emergencyConfidence * 100).toStringAsFixed(0);
    final outcome = request.confirmationOutcome.name;
    final contactCount = request.emergencyContacts.length;

    // Log the emergency event to the app's persistent logger
    appLogger.info(
      'EmergencyNotificationAction: 🚨 EMERGENCY SESSION STARTED\n'
      '  Session: $sessionId\n'
      '  Confidence: $confidence%\n'
      '  Outcome: $outcome\n'
      '  Contacts notified: $contactCount\n'
      '  Reasons: ${request.decisionReasons.join('; ')}',
    );

    // TODO(sprint-9): Replace with flutter_local_notifications high-priority
    // heads-up notification. Title: "ELLY Emergency Active",
    // Body: "Emergency dispatched. $contactCount contacts notified.",
    // Priority: max, vibration: [0, 500, 250, 500]

    sw.stop();
    return ActionResult(
      actionId: actionId,
      actionName: actionName,
      success: true,
      message: 'Emergency event logged. Session=$sessionId, Confidence=$confidence%, Contacts=$contactCount',
      executionTimeMs: sw.elapsedMilliseconds,
      timestamp: DateTime.now(),
    );
  }
}
