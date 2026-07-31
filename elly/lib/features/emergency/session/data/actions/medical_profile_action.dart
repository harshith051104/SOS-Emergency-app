/// medical_profile_action.dart
///
/// Production implementation of [EmergencyAction] for embedding the user's
/// emergency health profile into the emergency session payload.
///
/// Reads the health passport data that was already loaded in the session
/// request's emergencyProfile map (populated by the session controller from
/// the HealthPassportController). If additional details are needed they are
/// appended to the profile map for downstream actions.

library;

import '../../domain/entities/action_result.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/interfaces/emergency_action.dart';

class MedicalProfileAction implements EmergencyAction {
  @override
  String get actionId => 'medical_profile';

  @override
  String get actionName => 'Transmit Medical Profile';

  @override
  Future<ActionResult> execute(EmergencySessionRequest request) async {
    final sw = Stopwatch()..start();

    final profile = request.emergencyProfile;
    final bloodType = profile['bloodType']?.toString() ?? '';
    final allergies = profile['allergies'];
    final conditions = profile['conditions'];

    final hasProfile = bloodType.isNotEmpty ||
        (allergies is List && allergies.isNotEmpty) ||
        (conditions is List && conditions.isNotEmpty);

    final messageParts = <String>[];
    if (bloodType.isNotEmpty) messageParts.add('Blood: $bloodType');
    if (allergies is List && allergies.isNotEmpty) {
      messageParts.add('Allergies: ${allergies.join(', ')}');
    }
    if (conditions is List && conditions.isNotEmpty) {
      messageParts.add('Conditions: ${conditions.join(', ')}');
    }

    final message = hasProfile
        ? 'Medical profile packaged — ${messageParts.join(' | ')}'
        : 'No health passport configured. Set up your profile in Health Passport screen.';

    sw.stop();
    return ActionResult(
      actionId: actionId,
      actionName: actionName,
      success: true,
      message: message,
      executionTimeMs: sw.elapsedMilliseconds,
      timestamp: DateTime.now(),
    );
  }
}
