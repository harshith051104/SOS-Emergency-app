/// i_packet_storage_repository.dart
///
/// Interface for persisting and retrieving emergency packets, timeline logs, and session recovery data.

library;

import '../entities/packet_record.dart';
import '../entities/timeline_entry.dart';
import '../entities/session_metadata.dart';
import '../entities/retention_policy.dart';

abstract class IPacketStorageRepository {
  /// Saves an immutable packet record locally.
  Future<void> savePacket(PacketRecord packet);

  /// Retrieves all saved packets for a session sorted by packet number.
  Future<List<PacketRecord>> getPackets(String sessionId);

  /// Retrieves the latest packet saved for a session.
  Future<PacketRecord?> getLatestPacket(String sessionId);

  /// Appends a timeline entry to local storage.
  Future<void> saveTimelineEntry(String sessionId, TimelineEntry entry);

  /// Retrieves full timeline event history for a session.
  Future<List<TimelineEntry>> getTimeline(String sessionId);

  /// Saves active session metadata for app restart recovery.
  Future<void> saveSessionMetadata(SessionMetadata metadata);

  /// Fetches active session metadata if present.
  Future<SessionMetadata?> getActiveSessionMetadata();

  /// Clears active session metadata (called upon session completion).
  Future<void> clearActiveSessionMetadata();

  /// Applies storage retention rules to purge stale completed session data.
  Future<void> applyRetentionPolicy(RetentionPolicy policy);

  /// Deletes all data associated with a specific session ID.
  Future<void> deleteSession(String sessionId);
}
