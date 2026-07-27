/// telemetry_controller.dart
///
/// Controller managing presentation state for active telemetry tracking sessions.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_session.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/telemetry/domain/repositories/telemetry_repository.dart';

class TelemetryController extends StateNotifier<TelemetrySession> {
  TelemetryController(this._repository)
      : super(TelemetrySession(
          sessionId: 'session_idle',
          startedAt: DateTime.now(),
        )) {

    _initStream();
  }

  final TelemetryRepository _repository;
  StreamSubscription<TelemetryPoint>? _streamSub;

  void _initStream() {
    _streamSub = _repository.locationStream().listen((point) {
      if (!mounted) return;
      final updatedHistory = List<TelemetryPoint>.from(state.history)..add(point);
      state = state.copyWith(
        latestPoint: point,
        lastUpdate: point.timestamp,
        totalPoints: state.totalPoints + 1,
        history: updatedHistory,
      );
    });
  }

  /// Starts a live location tracking session.
  Future<bool> startSession(String sessionId) async {
    appLogger.info('TelemetryController: Starting live telemetry session $sessionId');
    state = state.copyWith(engineState: TelemetryEngineState.initializing);
    final result = await _repository.startTracking(sessionId);
    if (result.success && mounted) {
      state = _repository.currentSession;
      return true;
    } else if (mounted) {
      state = state.copyWith(
        engineState: TelemetryEngineState.error,
        errorMessage: result.reason,
      );
    }
    return false;
  }

  /// Stops current telemetry session.
  Future<void> stopSession() async {
    appLogger.info('TelemetryController: Stopping telemetry session ${state.sessionId}');
    await _repository.stopTracking();
    if (mounted) {
      state = state.copyWith(engineState: TelemetryEngineState.stopped);
    }
  }

  /// Pauses live location tracking.
  Future<void> pauseSession() async {
    await _repository.pauseTracking();
    if (mounted) {
      state = state.copyWith(engineState: TelemetryEngineState.paused);
    }
  }

  /// Resumes live location tracking.
  Future<void> resumeSession() async {
    await _repository.resumeTracking();
    if (mounted) {
      state = state.copyWith(engineState: TelemetryEngineState.tracking);
    }
  }

  /// Manually triggers current location refresh.
  Future<TelemetryPoint?> fetchCurrentLocation() async {
    final point = await _repository.currentLocation();
    if (point != null && mounted) {
      final updatedHistory = List<TelemetryPoint>.from(state.history)..add(point);
      state = state.copyWith(
        latestPoint: point,
        lastUpdate: DateTime.now(),
        history: updatedHistory,
      );
    }
    return point;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
