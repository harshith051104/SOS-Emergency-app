/// emergency_session_repository.dart
///
/// Abstract domain repository contract for active emergency session orchestration and timeline observation.

library;

import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/domain/entities/session_result.dart';

abstract class EmergencySessionRepository {
  Future<EmergencySession> createSession(EmergencyContext context);
  Future<SessionResult> startSession(String sessionId);
  Future<void> pauseSession();
  Future<void> resumeSession();
  Future<SessionResult> endSession();
  EmergencySession get currentSession;
  Stream<EmergencySession> watchSession();
  Stream<List<EmergencyTimelineEvent>> watchTimeline();
  void recordTimelineEvent(EmergencyTimelineEvent event);
}
