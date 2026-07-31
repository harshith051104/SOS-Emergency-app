/// emergency_action.dart
///
/// Interface for pluggable emergency actions executed during Phase 8.

library;

import '../entities/action_result.dart';
import '../entities/emergency_session_request.dart';

abstract class EmergencyAction {
  /// Unique identifier of the emergency action (e.g., 'send_sms', 'phone_call')
  String get actionId;

  /// Human-readable display name of the action
  String get actionName;

  /// Executes the emergency operation autonomously.
  Future<ActionResult> execute(EmergencySessionRequest request);
}
