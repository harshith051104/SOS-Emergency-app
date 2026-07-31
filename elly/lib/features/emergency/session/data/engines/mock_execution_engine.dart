/// mock_execution_engine.dart
///
/// Mock implementation of EmergencyExecutionEngine for unit testing and instant UI demonstration.

library;

import '../../domain/entities/emergency_session_request.dart';
import '../../domain/entities/emergency_session_result.dart';
import '../../domain/entities/acknowledgement_status.dart';
import '../../domain/entities/action_result.dart';
import '../../domain/interfaces/i_emergency_execution_engine.dart';

class MockExecutionEngine implements EmergencyExecutionEngine {
  MockExecutionEngine({
    this.mockResult,
    this.simulatedLatencyMs = 2,
  });

  final EmergencySessionResult? mockResult;
  final int simulatedLatencyMs;

  @override
  Future<EmergencySessionResult> execute(EmergencySessionRequest request) async {
    if (simulatedLatencyMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: simulatedLatencyMs));
    }

    if (mockResult != null) {
      return mockResult!;
    }

    final now = DateTime.now();

    return EmergencySessionResult(
      sessionId: request.sessionId,
      sessionState: SessionState.completed,
      executedActions: const ['send_sms', 'phone_call', 'location_sharing', 'medical_profile', 'emergency_timeline', 'emergency_notification'],
      successfulActions: const ['send_sms', 'phone_call', 'location_sharing', 'medical_profile', 'emergency_timeline', 'emergency_notification'],
      actionResults: [
        ActionResult(actionId: 'send_sms', actionName: 'Send Emergency SMS', success: true, message: 'Dispatched emergency SMS payload', executionTimeMs: 15, timestamp: now),
        ActionResult(actionId: 'phone_call', actionName: 'Initiate Emergency Phone Call', success: true, message: 'Emergency dialer channel initialized', executionTimeMs: 10, timestamp: now),
        ActionResult(actionId: 'location_sharing', actionName: 'Share Live GPS Location', success: true, message: 'Packaged live location payload', executionTimeMs: 12, timestamp: now),
        ActionResult(actionId: 'medical_profile', actionName: 'Transmit Medical Profile', success: true, message: 'Encrypted medical profile packaged', executionTimeMs: 8, timestamp: now),
        ActionResult(actionId: 'emergency_timeline', actionName: 'Record Emergency Timeline', success: true, message: 'Logged timestamp to audit buffer', executionTimeMs: 5, timestamp: now),
        ActionResult(actionId: 'emergency_notification', actionName: 'Dispatch System Notification', success: true, message: 'Dispatched system notification', executionTimeMs: 6, timestamp: now),
      ],
      acknowledgementStatus: AcknowledgementStatus.acknowledged,
      executionDurationMs: 56,
      engineVersion: 'v1.0.0-mock',
      algorithmVersion: 'v1.0.0-mock',
      timestamp: now,
    );
  }

  @override
  void dispose() {}
}
