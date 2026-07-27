/// emergency_session_orchestrator.dart
///
/// Runtime orchestrator responsible for initializing and shutting down platform engines
/// in deterministic order using the shared EmergencyEngine interface.

library;

import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_engine.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/session/domain/entities/session_result.dart';

class EmergencySessionOrchestrator {
  EmergencySessionOrchestrator({required List<EmergencyEngine> engines})
      : _engines = List.unmodifiable(engines);

  final List<EmergencyEngine> _engines;

  List<EmergencyEngine> get engines => _engines;

  /// Initializes engines in sequential priority order (Health -> Telemetry -> SOS Circle -> Communication).
  Future<SessionResult> initializeEngines(EmergencyContext context) async {
    final startTime = DateTime.now();
    final started = <String>[];
    final errors = <String, String>{};

    appLogger.info('EmergencySessionOrchestrator: Starting initialization of ${_engines.length} engines');

    for (final engine in _engines) {
      try {
        appLogger.info('EmergencySessionOrchestrator: Initializing ${engine.engineName}...');
        await engine.initialize(context);
        started.add(engine.engineName);
        appLogger.info('EmergencySessionOrchestrator: Successfully initialized ${engine.engineName}');
      } catch (e, st) {
        appLogger.error('EmergencySessionOrchestrator: Failed initializing ${engine.engineName}', e, st);
        errors[engine.engineName] = e.toString();
      }
    }

    final duration = DateTime.now().difference(startTime);
    return SessionResult(
      success: errors.isEmpty,
      duration: duration,
      enginesStarted: List.unmodifiable(started),
      errors: Map.unmodifiable(errors),
    );
  }

  /// Shuts down engines in reverse priority order (Communication -> SOS Circle -> Telemetry -> Health).
  Future<SessionResult> disposeEngines() async {
    final startTime = DateTime.now();
    final stopped = <String>[];
    final errors = <String, String>{};

    appLogger.info('EmergencySessionOrchestrator: Starting reverse shutdown of ${_engines.length} engines');

    final reverseEngines = _engines.reversed.toList();
    for (final engine in reverseEngines) {
      try {
        appLogger.info('EmergencySessionOrchestrator: Disposing ${engine.engineName}...');
        await engine.dispose();
        stopped.add(engine.engineName);
        appLogger.info('EmergencySessionOrchestrator: Successfully disposed ${engine.engineName}');
      } catch (e, st) {
        appLogger.error('EmergencySessionOrchestrator: Failed disposing ${engine.engineName}', e, st);
        errors[engine.engineName] = e.toString();
      }
    }

    final duration = DateTime.now().difference(startTime);
    return SessionResult(
      success: errors.isEmpty,
      duration: duration,
      enginesStopped: List.unmodifiable(stopped),
      errors: Map.unmodifiable(errors),
    );
  }
}
