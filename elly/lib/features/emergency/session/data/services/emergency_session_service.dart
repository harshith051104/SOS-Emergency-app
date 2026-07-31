/// emergency_session_service.dart
///
/// Application service layer for Phase 8 Emergency Session execution. Handles validation,
/// telemetry updates, and error boundaries.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/emergency_execution_error.dart';
import '../../domain/entities/emergency_session_config.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/entities/emergency_session_result.dart';
import '../../domain/entities/emergency_execution_telemetry.dart';
import '../../domain/interfaces/i_emergency_execution_engine.dart';

class EmergencySessionService {
  EmergencySessionService({
    required EmergencyExecutionEngine engine,
    EmergencySessionConfig config = const EmergencySessionConfig(),
  })  : _engine = engine,
        _config = config;

  final EmergencyExecutionEngine _engine;
  final EmergencySessionConfig _config;

  EmergencyExecutionTelemetry _telemetry = const EmergencyExecutionTelemetry();
  EmergencyExecutionTelemetry get telemetry => _telemetry;
  EmergencySessionConfig get config => _config;

  Future<EmergencySessionResult> processRequest(EmergencySessionRequest request) async {
    if (request.sessionId.isEmpty) {
      throw const EmergencyExecutionError(
        EmergencyExecutionErrorCategory.executionFailure,
        'Session ID cannot be empty.',
      );
    }

    try {
      final result = await _engine.execute(request);

      _telemetry = _telemetry.recordSessionComplete(
        isCompleted: result.sessionState == SessionState.completed,
        isCancelled: result.sessionState == SessionState.cancelled,
        executionDurationMs: result.executionDurationMs.toDouble(),
        successActions: result.successfulActions.length,
        failActions: result.failedActions.length,
      );

      return result;
    } on EmergencyExecutionError {
      rethrow;
    } catch (e, stack) {
      appLogger.error('EmergencySessionService: Unhandled exception during emergency session execution: $e\n$stack');
      throw EmergencyExecutionError(
        EmergencyExecutionErrorCategory.executionFailure,
        'Failed to execute emergency session: $e',
      );
    }
  }

  void dispose() {
    _engine.dispose();
  }
}
