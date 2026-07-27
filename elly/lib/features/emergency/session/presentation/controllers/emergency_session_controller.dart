/// emergency_session_controller.dart
///
/// Master presentation controller for active emergency session orchestration & timeline tracking.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session.dart';
import 'package:elly/features/emergency/session/domain/entities/session_state.dart';
import 'package:elly/features/emergency/session/domain/entities/session_result.dart';
import 'package:elly/features/emergency/session/domain/repositories/emergency_session_repository.dart';
import 'package:elly/features/emergency/session/domain/validation/emergency_session_validator.dart';

class EmergencySessionController extends StateNotifier<EmergencySession> {
  EmergencySessionController(this._repository, this._ref)
      : super(_repository.currentSession) {
    _initStream();
  }

  final EmergencySessionRepository _repository;
  final Ref _ref;
  StreamSubscription<EmergencySession>? _sessionSub;
  Timer? _durationTimer;

  Ref get ref => _ref;

  void _initStream() {
    _sessionSub = _repository.watchSession().listen((updatedSession) {
      if (!mounted) return;
      state = updatedSession;
    });
  }

  /// Creates and starts an active emergency session orchestrating all platform engines.
  Future<SessionResult> createAndStartSession(EmergencyContext context) async {
    appLogger.info('EmergencySessionController: Creating and starting session ${context.sessionId}');

    if (state.isActive) {
      appLogger.warning('EmergencySessionController: Prevented duplicate session creation.');
      return const SessionResult(
        success: false,
        duration: Duration.zero,
        errors: {'Orchestrator': 'Session already active'},
      );
    }

    final createdSession = await _repository.createSession(context);
    state = createdSession;

    final transitionVal = EmergencySessionValidator.validateTransition(state, SessionState.starting);
    if (!transitionVal.isValid) {
      appLogger.warning('EmergencySessionController: Validation error: ${transitionVal.reason}');
    }

    final result = await _repository.startSession(context.sessionId);

    if (result.success && mounted) {
      _startDurationTimer();
    }
    return result;
  }

  /// Pauses active emergency session.
  Future<void> pauseSession() async {
    final transitionVal = EmergencySessionValidator.validateTransition(state, SessionState.paused);
    if (!transitionVal.isValid) {
      appLogger.warning('EmergencySessionController: Pause validation notice: ${transitionVal.reason}');
    }

    await _repository.pauseSession();
    _durationTimer?.cancel();
  }

  /// Resumes active emergency session.
  Future<void> resumeSession() async {
    final transitionVal = EmergencySessionValidator.validateTransition(state, SessionState.active);
    if (!transitionVal.isValid) {
      appLogger.warning('EmergencySessionController: Resume validation notice: ${transitionVal.reason}');
    }

    await _repository.resumeSession();
    _startDurationTimer();
  }

  /// Gracefully ends the active emergency session and disposes engines in reverse order.
  Future<SessionResult> endSession() async {
    appLogger.info('EmergencySessionController: Ending active session');
    _durationTimer?.cancel();

    final result = await _repository.endSession();
    return result;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !state.isActive || state.state == SessionState.paused) return;
      final newDuration = state.duration + const Duration(seconds: 1);
      state = state.copyWith(duration: newDuration);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }
}
