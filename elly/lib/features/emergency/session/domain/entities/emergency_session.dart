/// emergency_session.dart
///
/// Immutable aggregate root model representing an active emergency session and its timeline history.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/session/domain/entities/session_state.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';

@immutable
class EmergencySession {
  const EmergencySession({
    required this.sessionId,
    required this.context,
    this.state = SessionState.idle,
    required this.createdAt,
    this.activatedAt,
    this.endedAt,
    this.duration = Duration.zero,
    this.activeEngines = const [],
    this.timeline = const [],
  });

  final String sessionId;
  final EmergencyContext context;
  final SessionState state;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? endedAt;
  final Duration duration;
  final List<String> activeEngines;
  final List<EmergencyTimelineEvent> timeline;

  bool get isActive => state == SessionState.active || state == SessionState.starting || state == SessionState.recovering;

  EmergencySession copyWith({
    String? sessionId,
    EmergencyContext? context,
    SessionState? state,
    DateTime? createdAt,
    DateTime? activatedAt,
    DateTime? endedAt,
    Duration? duration,
    List<String>? activeEngines,
    List<EmergencyTimelineEvent>? timeline,
  }) {
    return EmergencySession(
      sessionId: sessionId ?? this.sessionId,
      context: context ?? this.context,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      activatedAt: activatedAt ?? this.activatedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      activeEngines: activeEngines ?? this.activeEngines,
      timeline: timeline ?? this.timeline,
    );
  }
}
