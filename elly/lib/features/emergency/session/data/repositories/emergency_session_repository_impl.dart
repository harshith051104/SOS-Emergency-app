/// emergency_session_repository_impl.dart
///
/// Data layer implementation of EmergencySessionRepository managing session state transitions,
/// timeline event streams, and orchestrator execution.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session.dart';
import 'package:elly/features/emergency/session/domain/entities/session_state.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/domain/entities/session_result.dart';
import 'package:elly/features/emergency/session/domain/repositories/emergency_session_repository.dart';
import 'package:elly/features/emergency/session/data/orchestrator/emergency_session_orchestrator.dart';

class EmergencySessionRepositoryImpl implements EmergencySessionRepository {
  EmergencySessionRepositoryImpl({required EmergencySessionOrchestrator orchestrator})
      : _orchestrator = orchestrator,
        _sessionStreamController = StreamController<EmergencySession>.broadcast(),
        _timelineStreamController = StreamController<List<EmergencyTimelineEvent>>.broadcast();

  final EmergencySessionOrchestrator _orchestrator;
  final StreamController<EmergencySession> _sessionStreamController;
  final StreamController<List<EmergencyTimelineEvent>> _timelineStreamController;

  EmergencySession? _session;
  final List<EmergencyTimelineEvent> _timeline = [];

  @override
  EmergencySession get currentSession {
    return _session ??
        EmergencySession(
          sessionId: 'idle_session',
          context: EmergencyContext(
            sessionId: 'idle_session',
            dispatchId: 'disp_idle',
            emergencyType: 'None',
            startedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        );
  }

  @override
  Future<EmergencySession> createSession(EmergencyContext context) async {
    appLogger.info('EmergencySessionRepositoryImpl: Creating session ${context.sessionId}');
    _timeline.clear();

    final now = DateTime.now();
    final newSession = EmergencySession(
      sessionId: context.sessionId,
      context: context,
      state: SessionState.preparing,
      createdAt: now,
    );

    _session = newSession;
    _emitSession(newSession);

    recordTimelineEvent(EmergencyTimelineEvent(
      id: 'evt_${now.millisecondsSinceEpoch}_1',
      timestamp: now,
      category: EventCategory.lifecycle,
      severity: EventSeverity.info,
      title: 'Session Created',
      description: 'Emergency session created for ${context.emergencyType}',
      sourceEngine: 'Session Engine',
    ));

    return newSession;
  }

  @override
  Future<SessionResult> startSession(String sessionId) async {
    appLogger.info('EmergencySessionRepositoryImpl: Starting emergency session $sessionId');
    final now = DateTime.now();

    _session = currentSession.copyWith(
      state: SessionState.starting,
      activatedAt: now,
    );
    _emitSession(_session!);

    recordTimelineEvent(EmergencyTimelineEvent(
      id: 'evt_${now.millisecondsSinceEpoch}_2',
      timestamp: now,
      category: EventCategory.lifecycle,
      severity: EventSeverity.warning,
      title: 'Session Activation Initiated',
      description: 'Orchestrating engine startup sequence...',
      sourceEngine: 'Session Engine',
    ));

    final initResult = await _orchestrator.initializeEngines(currentSession.context);

    if (initResult.success) {
      _session = _session!.copyWith(
        state: SessionState.active,
        activeEngines: initResult.enginesStarted,
      );
      recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}_3',
        timestamp: DateTime.now(),
        category: EventCategory.lifecycle,
        severity: EventSeverity.info,
        title: 'All Engines Active',
        description: 'Successfully initialized ${initResult.enginesStarted.length} engines.',
        sourceEngine: 'Orchestrator',
      ));
    } else {
      _session = _session!.copyWith(
        state: SessionState.recovering,
        activeEngines: initResult.enginesStarted,
      );
      recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}_err',
        timestamp: DateTime.now(),
        category: EventCategory.system,
        severity: EventSeverity.error,
        title: 'Engine Initialization Failure',
        description: 'Partial engine startup: ${initResult.errors}',
        sourceEngine: 'Orchestrator',
      ));
    }

    _emitSession(_session!);
    return initResult;
  }

  @override
  Future<void> pauseSession() async {
    if (_session == null || !_session!.isActive) return;
    appLogger.info('EmergencySessionRepositoryImpl: Pausing session ${_session!.sessionId}');
    _session = _session!.copyWith(state: SessionState.paused);
    _emitSession(_session!);

    recordTimelineEvent(EmergencyTimelineEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      category: EventCategory.lifecycle,
      severity: EventSeverity.info,
      title: 'Session Paused',
      description: 'Emergency tracking paused by user.',
      sourceEngine: 'Session Engine',
    ));
  }

  @override
  Future<void> resumeSession() async {
    if (_session == null || _session!.state != SessionState.paused) return;
    appLogger.info('EmergencySessionRepositoryImpl: Resuming session ${_session!.sessionId}');
    _session = _session!.copyWith(state: SessionState.active);
    _emitSession(_session!);

    recordTimelineEvent(EmergencyTimelineEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      category: EventCategory.lifecycle,
      severity: EventSeverity.info,
      title: 'Session Resumed',
      description: 'Emergency session resumed.',
      sourceEngine: 'Session Engine',
    ));
  }

  @override
  Future<SessionResult> endSession() async {
    if (_session == null) {
      return const SessionResult(success: true, duration: Duration.zero);
    }

    appLogger.info('EmergencySessionRepositoryImpl: Ending session ${_session!.sessionId}');
    final now = DateTime.now();
    _session = _session!.copyWith(state: SessionState.ending);
    _emitSession(_session!);

    recordTimelineEvent(EmergencyTimelineEvent(
      id: 'evt_${now.millisecondsSinceEpoch}',
      timestamp: now,
      category: EventCategory.lifecycle,
      severity: EventSeverity.info,
      title: 'Session Shutdown Initiated',
      description: 'Shutting down platform engines in reverse order...',
      sourceEngine: 'Session Engine',
    ));

    final disposeResult = await _orchestrator.disposeEngines();

    final endT = DateTime.now();
    final totalDuration = _session!.activatedAt != null ? endT.difference(_session!.activatedAt!) : Duration.zero;

    _session = _session!.copyWith(
      state: SessionState.completed,
      endedAt: endT,
      duration: totalDuration,
      activeEngines: const [],
    );

    recordTimelineEvent(EmergencyTimelineEvent(
      id: 'evt_${endT.millisecondsSinceEpoch}',
      timestamp: endT,
      category: EventCategory.lifecycle,
      severity: EventSeverity.success,
      title: 'Session Completed',
      description: 'Emergency session completed cleanly in ${totalDuration.inSeconds}s.',
      sourceEngine: 'Session Engine',
    ));

    _emitSession(_session!);
    return disposeResult;
  }

  @override
  Stream<EmergencySession> watchSession() => _sessionStreamController.stream;

  @override
  Stream<List<EmergencyTimelineEvent>> watchTimeline() => _timelineStreamController.stream;

  @override
  void recordTimelineEvent(EmergencyTimelineEvent event) {
    _timeline.add(event);
    if (_session != null) {
      _session = _session!.copyWith(timeline: List.unmodifiable(_timeline));
    }
    if (!_timelineStreamController.isClosed) {
      _timelineStreamController.add(List.unmodifiable(_timeline));
    }
  }

  void _emitSession(EmergencySession session) {
    if (!_sessionStreamController.isClosed) {
      _sessionStreamController.add(session);
    }
  }
}
