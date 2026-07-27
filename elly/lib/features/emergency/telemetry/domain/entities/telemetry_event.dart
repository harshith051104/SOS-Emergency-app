/// telemetry_event.dart
///
/// Event hierarchy for real-time telemetry updates, movement detection, and session state changes.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';

@immutable
sealed class TelemetryEvent {
  const TelemetryEvent();
}

class TelemetryStartedEvent extends TelemetryEvent {
  const TelemetryStartedEvent({
    required this.sessionId,
    required this.startedAt,
  });

  final String sessionId;
  final DateTime startedAt;
}

class LocationUpdatedEvent extends TelemetryEvent {
  const LocationUpdatedEvent({
    required this.point,
    required this.sessionId,
  });

  final TelemetryPoint point;
  final String sessionId;
}

class MovementDetectedEvent extends TelemetryEvent {
  const MovementDetectedEvent({
    required this.point,
    required this.speedKmh,
    required this.sessionId,
  });

  final TelemetryPoint point;
  final double speedKmh;
  final String sessionId;
}

class TrackingPausedEvent extends TelemetryEvent {
  const TrackingPausedEvent({
    required this.sessionId,
    required this.pausedAt,
  });

  final String sessionId;
  final DateTime pausedAt;
}

class TrackingResumedEvent extends TelemetryEvent {
  const TrackingResumedEvent({
    required this.sessionId,
    required this.resumedAt,
  });

  final String sessionId;
  final DateTime resumedAt;
}

class TrackingStoppedEvent extends TelemetryEvent {
  const TrackingStoppedEvent({
    required this.sessionId,
    required this.totalPointsCaptured,
  });

  final String sessionId;
  final int totalPointsCaptured;
}
