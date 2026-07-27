/// telemetry_session.dart
///
/// Immutable domain model representing a telemetry tracking session with state machine & point history.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';

enum TelemetryEngineState {
  idle,
  initializing,
  permissionRequest,
  tracking,
  paused,
  stopped,
  error,
}

@immutable
class TelemetrySession {
  const TelemetrySession({
    required this.sessionId,
    required this.startedAt,
    this.lastUpdate,
    this.totalPoints = 0,
    this.latestPoint,
    this.history = const [],
    this.engineState = TelemetryEngineState.idle,
    this.errorMessage,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime? lastUpdate;
  final int totalPoints;
  final TelemetryPoint? latestPoint;
  final List<TelemetryPoint> history;
  final TelemetryEngineState engineState;
  final String? errorMessage;

  bool get isTracking => engineState == TelemetryEngineState.tracking;
  bool get isPaused => engineState == TelemetryEngineState.paused;

  TelemetrySession copyWith({
    String? sessionId,
    DateTime? startedAt,
    DateTime? lastUpdate,
    int? totalPoints,
    TelemetryPoint? latestPoint,
    List<TelemetryPoint>? history,
    TelemetryEngineState? engineState,
    String? errorMessage,
  }) {
    return TelemetrySession(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      totalPoints: totalPoints ?? this.totalPoints,
      latestPoint: latestPoint ?? this.latestPoint,
      history: history ?? this.history,
      engineState: engineState ?? this.engineState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
