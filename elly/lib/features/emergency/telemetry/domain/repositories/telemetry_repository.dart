/// telemetry_repository.dart
///
/// Abstract repository contract for starting, stopping, and streaming location telemetry.

library;

import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_session.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_result.dart';

abstract class TelemetryRepository {
  Future<TelemetryResult> startTracking(String sessionId);
  Future<void> stopTracking();
  Future<void> pauseTracking();
  Future<void> resumeTracking();
  Future<TelemetryPoint?> currentLocation();
  Stream<TelemetryPoint> locationStream();
  TelemetrySession get currentSession;
}
