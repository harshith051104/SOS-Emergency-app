/// telemetry_repository_impl.dart
///
/// Data layer implementation of TelemetryRepository managing session state machine,
/// history recording, stream filtering, and domain events.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_session.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_result.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_event.dart';
import 'package:elly/features/emergency/telemetry/domain/validation/telemetry_validator.dart';
import 'package:elly/features/emergency/telemetry/domain/repositories/telemetry_repository.dart';
import 'package:elly/features/emergency/telemetry/data/services/telemetry_service.dart';

class TelemetryRepositoryImpl implements TelemetryRepository {
  TelemetryRepositoryImpl({TelemetryService? service})
      : _service = service ?? TelemetryService(),
        _streamController = StreamController<TelemetryPoint>.broadcast();

  final TelemetryService _service;
  final StreamController<TelemetryPoint> _streamController;
  StreamSubscription<TelemetryPoint>? _locationSub;

  TelemetrySession _currentSession = TelemetrySession(
    sessionId: 'session_idle',
    startedAt: DateTime.now(),
  );

  @override
  TelemetrySession get currentSession => _currentSession;

  @override
  Future<TelemetryResult> startTracking(String sessionId) async {
    appLogger.info('TelemetryRepositoryImpl: Starting live telemetry session $sessionId');
    _currentSession = _currentSession.copyWith(engineState: TelemetryEngineState.permissionRequest);

    final hasPermission = await _service.checkAndRequestPermissions();
    if (!hasPermission) {
      _currentSession = _currentSession.copyWith(
        engineState: TelemetryEngineState.error,
        errorMessage: 'Location permission denied or GPS service disabled.',
      );
      return TelemetryResult.failure('Location permission denied or GPS service disabled.');
    }

    _currentSession = TelemetrySession(
      sessionId: sessionId,
      startedAt: DateTime.now(),
      engineState: TelemetryEngineState.tracking,
    );


    _service.emitEvent(TelemetryStartedEvent(sessionId: sessionId, startedAt: DateTime.now()));

    _locationSub?.cancel();
    _locationSub = _service.startLocationStream().listen(_handleNewPoint);

    final initialPoint = await currentLocation();
    return TelemetryResult.success(initialPoint ?? _currentSession.latestPoint!);
  }

  @override
  Future<void> stopTracking() async {
    appLogger.info('TelemetryRepositoryImpl: Stopping telemetry session ${_currentSession.sessionId}');
    _locationSub?.cancel();
    _locationSub = null;

    final captured = _currentSession.totalPoints;
    _service.emitEvent(TrackingStoppedEvent(
      sessionId: _currentSession.sessionId,
      totalPointsCaptured: captured,
    ));

    _currentSession = _currentSession.copyWith(
      engineState: TelemetryEngineState.stopped,
    );
  }

  @override
  Future<void> pauseTracking() async {
    if (!_currentSession.isTracking || _currentSession.isPaused) return;
    appLogger.info('TelemetryRepositoryImpl: Pausing telemetry tracking.');
    _locationSub?.pause();
    _currentSession = _currentSession.copyWith(engineState: TelemetryEngineState.paused);
    _service.emitEvent(TrackingPausedEvent(
      sessionId: _currentSession.sessionId,
      pausedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> resumeTracking() async {
    if (!_currentSession.isPaused) return;
    appLogger.info('TelemetryRepositoryImpl: Resuming telemetry tracking.');
    _locationSub?.resume();
    _currentSession = _currentSession.copyWith(engineState: TelemetryEngineState.tracking);
    _service.emitEvent(TrackingResumedEvent(
      sessionId: _currentSession.sessionId,
      resumedAt: DateTime.now(),
    ));
  }

  @override
  Future<TelemetryPoint?> currentLocation() async {
    final point = await _service.fetchCurrentLocation();
    if (point != null) {
      final updatedHistory = List<TelemetryPoint>.from(_currentSession.history)..add(point);
      _currentSession = _currentSession.copyWith(
        latestPoint: point,
        lastUpdate: DateTime.now(),
        history: updatedHistory,
      );
    }
    return point;
  }

  @override
  Stream<TelemetryPoint> locationStream() => _streamController.stream;

  void _handleNewPoint(TelemetryPoint point) {
    if (_currentSession.isPaused) return;

    final validation = TelemetryValidator.validatePoint(
      point,
      previousPoint: _currentSession.latestPoint,
    );

    if (!validation.isValid) {
      appLogger.warning('TelemetryRepositoryImpl: Discarded sample: ${validation.reason}');
      return;
    }

    final evaluatedPoint = validation.evaluatedPoint;
    final updatedHistory = List<TelemetryPoint>.from(_currentSession.history)..add(evaluatedPoint);

    _currentSession = _currentSession.copyWith(
      latestPoint: evaluatedPoint,
      lastUpdate: evaluatedPoint.timestamp,
      totalPoints: _currentSession.totalPoints + 1,
      history: updatedHistory,
    );

    if (!_streamController.isClosed) {
      _streamController.add(evaluatedPoint);
    }

    _service.emitEvent(LocationUpdatedEvent(
      point: evaluatedPoint,
      sessionId: _currentSession.sessionId,
    ));

    if (evaluatedPoint.speed > 1.5) { // speed > ~5.4 km/h
      _service.emitEvent(MovementDetectedEvent(
        point: evaluatedPoint,
        speedKmh: evaluatedPoint.speed * 3.6,
        sessionId: _currentSession.sessionId,
      ));
    }
  }
}
