/// confirmation_service.dart
///
/// Application service layer for Confirmation Engine execution. Handles validation,
/// telemetry updates, and error boundaries.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/confirmation_config.dart';
import '../../domain/entities/confirmation_error.dart';
import '../../domain/entities/confirmation_outcome.dart';
import '../../domain/entities/confirmation_request.dart';
import '../../domain/entities/confirmation_result.dart';
import '../../domain/entities/confirmation_telemetry.dart';
import '../../domain/interfaces/i_confirmation_engine.dart';

class ConfirmationService {
  ConfirmationService({
    required ConfirmationEngine engine,
    ConfirmationConfig config = const ConfirmationConfig(),
  })  : _engine = engine,
        _config = config;

  final ConfirmationEngine _engine;
  final ConfirmationConfig _config;

  ConfirmationTelemetry _telemetry = const ConfirmationTelemetry();
  ConfirmationTelemetry get telemetry => _telemetry;
  ConfirmationConfig get config => _config;

  Future<ConfirmationResult> processRequest(ConfirmationRequest request) async {
    if (request.sessionId.isEmpty) {
      _telemetry = _telemetry.recordFailure();
      throw const ConfirmationError(
        ConfirmationErrorCategory.processingFailure,
        'Session ID cannot be empty.',
      );
    }

    try {
      final result = await _engine.evaluate(request);

      _telemetry = _telemetry.recordOutcome(
        isConfirmed: result.confirmationOutcome == ConfirmationOutcome.confirmed,
        isTimeout: result.confirmationOutcome == ConfirmationOutcome.timedOut,
        isCancelled: result.confirmationOutcome == ConfirmationOutcome.cancelled,
        isInterrupted: result.confirmationOutcome == ConfirmationOutcome.interrupted,
        responseTimeMs: result.responseTimeMs.toDouble(),
      );

      return result;
    } on ConfirmationError {
      rethrow;
    } catch (e, stack) {
      _telemetry = _telemetry.recordFailure();
      appLogger.error('ConfirmationService: Unhandled exception during confirmation evaluation: $e\n$stack');
      throw ConfirmationError(
        ConfirmationErrorCategory.processingFailure,
        'Failed to evaluate confirmation request: $e',
      );
    }
  }

  void dispose() {
    _engine.dispose();
  }
}
