/// emergency_session_snapshot.dart
///
/// Immutable aggregate read model providing a single unified view of active session,
/// latest location, active engines, health summary, and timeline count for UI presentation.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';

@immutable
class EmergencySessionSnapshot {
  const EmergencySessionSnapshot({
    required this.session,
    this.latestLocation,
    this.activeEngines = const [],
    this.healthSummary = const {},
    required this.timelineCount,
    this.currentTimeline = const [],
  });

  final EmergencySession session;
  final TelemetryPoint? latestLocation;
  final List<String> activeEngines;
  final Map<String, String> healthSummary;
  final int timelineCount;
  final List<EmergencyTimelineEvent> currentTimeline;
}
