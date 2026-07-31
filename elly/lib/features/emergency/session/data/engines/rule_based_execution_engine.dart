/// rule_based_execution_engine.dart
///
/// Deterministic orchestration engine executing configured EmergencyAction pipelines.

library;

import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/entities/emergency_session_result.dart';
import '../../domain/entities/acknowledgement_status.dart';
import '../../domain/entities/action_result.dart';
import '../../domain/entities/emergency_session_config.dart';
import '../../domain/interfaces/emergency_action.dart';
import '../../domain/interfaces/i_emergency_execution_engine.dart';

class RuleBasedExecutionEngine implements EmergencyExecutionEngine {
  RuleBasedExecutionEngine({
    required List<EmergencyAction> actions,
    EmergencySessionConfig config = const EmergencySessionConfig(),
  })  : _actions = actions,
        _config = config;

  final List<EmergencyAction> _actions;
  final EmergencySessionConfig _config;

  static const String engineVersionConst = 'v1.0.0-rules';
  static const String algorithmVersionConst = 'v1.0.0-orchestrated';

  @override
  Future<EmergencySessionResult> execute(EmergencySessionRequest request) async {
    final sw = Stopwatch()..start();
    final now = DateTime.now();

    final List<String> executedActions = [];
    final List<String> successfulActions = [];
    final List<String> failedActions = [];
    final List<ActionResult> actionResults = [];

    // Check confirmation outcome permission
    if (request.confirmationOutcome == ConfirmationOutcome.cancelled) {
      sw.stop();
      return EmergencySessionResult(
        sessionId: request.sessionId,
        sessionState: SessionState.cancelled,
        acknowledgementStatus: AcknowledgementStatus.unknown,
        executionDurationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    if (request.confirmationOutcome == ConfirmationOutcome.noConfirmationRequired) {
      sw.stop();
      return EmergencySessionResult(
        sessionId: request.sessionId,
        sessionState: SessionState.completed,
        acknowledgementStatus: AcknowledgementStatus.delivered,
        executionDurationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    // ── Tier 1: Immediate Concurrent Dispatch (Dialer + Notification) ─────────
    // Fired instantly so phone call and alarm start within 0ms without waiting for GPS.
    final tier1Actions = _actions.where((a) =>
        a.actionId == 'phone_call' || a.actionId == 'emergency_notification');

    final tier1Results = await Future.wait(
      tier1Actions.where((a) => isActionAllowed(a.actionId)).map((action) {
        executedActions.add(action.actionId);
        return _executeWithRetry(action, request);
      }),
    );

    for (final result in tier1Results) {
      actionResults.add(result);
      if (result.success) {
        successfulActions.add(result.actionId);
      } else {
        failedActions.add(result.actionId);
      }
    }

    // ── Tier 2: Parallel Context Gathering (GPS + Medical Profile) ────────────
    // Fetches live GPS and medical profile in parallel so coordinates are available for SMS.
    final tier2ContextActions = _actions.where((a) =>
        a.actionId == 'location_sharing' || a.actionId == 'medical_profile');

    final tier2ContextResults = await Future.wait(
      tier2ContextActions.where((a) => isActionAllowed(a.actionId)).map((action) {
        executedActions.add(action.actionId);
        return _executeWithRetry(action, request);
      }),
    );

    for (final result in tier2ContextResults) {
      actionResults.add(result);
      if (result.success) {
        successfulActions.add(result.actionId);
      } else {
        failedActions.add(result.actionId);
      }
    }

    // ── Tier 3: Outbound Messaging & Timeline (SMS + Timeline + Custom) ─────────────
    // Fired AFTER Tier 2 completes so SMS includes live GPS coordinates and medical details.
    final tier3Actions = _actions.where((a) =>
        a.actionId == 'send_sms' ||
        a.actionId == 'emergency_timeline' ||
        (a.actionId != 'phone_call' &&
            a.actionId != 'emergency_notification' &&
            a.actionId != 'location_sharing' &&
            a.actionId != 'medical_profile'));

    final tier3Results = await Future.wait(
      tier3Actions.where((a) => isActionAllowed(a.actionId)).map((action) {
        executedActions.add(action.actionId);
        return _executeWithRetry(action, request);
      }),
    );

    for (final result in tier3Results) {
      actionResults.add(result);
      if (result.success) {
        successfulActions.add(result.actionId);
      } else {
        failedActions.add(result.actionId);
      }
    }

    sw.stop();

    final isAllSuccessful = failedActions.isEmpty;
    final sessionState = isAllSuccessful ? SessionState.completed : SessionState.failed;
    final ackStatus = isAllSuccessful ? AcknowledgementStatus.acknowledged : AcknowledgementStatus.failed;

    return EmergencySessionResult(
      sessionId: request.sessionId,
      sessionState: sessionState,
      executedActions: executedActions,
      successfulActions: successfulActions,
      failedActions: failedActions,
      actionResults: actionResults,
      acknowledgementStatus: ackStatus,
      executionDurationMs: sw.elapsedMilliseconds,
      timestamp: DateTime.now(),
    );
  }

  Future<ActionResult> _executeWithRetry(EmergencyAction action, EmergencySessionRequest request) async {
    int attempts = 0;
    ActionResult? lastResult;

    while (attempts <= _config.retryCount) {
      try {
        attempts++;
        lastResult = await action.execute(request);
        if (lastResult.success) return lastResult;
      } catch (e) {
        lastResult = ActionResult(
          actionId: action.actionId,
          actionName: action.actionName,
          success: false,
          message: 'Execution error (Attempt $attempts): $e',
          executionTimeMs: 0,
          timestamp: DateTime.now(),
        );
      }

      if (attempts <= _config.retryCount) {
        await Future<void>.delayed(Duration(milliseconds: _config.retryDelayMs));
      }
    }

    return lastResult ??
        ActionResult(
          actionId: action.actionId,
          actionName: action.actionName,
          success: false,
          message: 'Action failed after $attempts attempts',
          executionTimeMs: 0,
          timestamp: DateTime.now(),
        );
  }

  bool isActionAllowed(String actionId) {
    switch (actionId) {
      case 'send_sms':
      case 'phone_call':
        return _config.allowPhoneCalls;
      case 'location_sharing':
        return _config.allowLocationSharing;
      case 'medical_profile':
        return _config.allowMedicalProfile;
      case 'emergency_notification':
        return _config.allowNotifications;
      case 'emergency_timeline':
        return _config.allowTimelineRecording;
      default:
        return true;
    }
  }

  @override
  void dispose() {}
}
