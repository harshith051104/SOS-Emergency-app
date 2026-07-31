/// decision_service.dart
///
/// Application service layer for Multi-Signal Decision Evaluation.
/// Manages request validation, timeout enforcement, telemetry aggregation, and error boundaries.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/decision_config.dart';
import '../../domain/entities/decision_error.dart';
import '../../domain/entities/emergency_decision_request.dart';
import '../../domain/entities/emergency_decision_result.dart';
import '../../domain/entities/decision_telemetry.dart';
import '../../domain/interfaces/i_decision_engine.dart';

class DecisionService {
  DecisionService({
    required DecisionEngine engine,
    DecisionConfig config = const DecisionConfig(),
  })  : _engine = engine,
        _config = config;

  final DecisionEngine _engine;
  final DecisionConfig _config;

  DecisionTelemetry _telemetry = const DecisionTelemetry();
  DecisionTelemetry get telemetry => _telemetry;

  Future<EmergencyDecisionResult> processRequest(EmergencyDecisionRequest request) async {
    if (request.sessionId.isEmpty) {
      _telemetry = _telemetry.recordFailure();
      throw const DecisionError(
        DecisionErrorCategory.evaluationFailure,
        'Session ID cannot be empty.',
      );
    }

    try {
      final result = await _engine
          .evaluate(request)
          .timeout(Duration(milliseconds: _config.maxLatencyMs + 500), onTimeout: () {
        throw const DecisionError(
          DecisionErrorCategory.timeout,
          'Decision evaluation exceeded allowable execution timeout.',
        );
      });

      _telemetry = _telemetry.recordSuccess(
        latencyMs: result.processingTimeMs.toDouble(),
        confidence: result.emergencyConfidence,
        evidenceCount: result.evidenceUsed.length,
      );

      return result;
    } on DecisionError {
      rethrow;
    } catch (e, stack) {
      _telemetry = _telemetry.recordFailure();
      appLogger.error('DecisionService: Unhandled exception during decision evaluation: $e\n$stack');
      throw DecisionError(
        DecisionErrorCategory.evaluationFailure,
        'Failed to evaluate emergency decision: $e',
      );
    }
  }

  void dispose() {
    _engine.dispose();
  }
}
