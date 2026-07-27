/// packet_storage_repository_impl.dart
///
/// Implementation of IPacketStorageRepository wrapping MonitoringStorageService.

library;

import '../../domain/entities/packet_record.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/entities/session_metadata.dart';
import '../../domain/entities/retention_policy.dart';
import '../../domain/repositories/i_packet_storage_repository.dart';
import '../services/monitoring_storage_service.dart';

class PacketStorageRepositoryImpl implements IPacketStorageRepository {
  PacketStorageRepositoryImpl(this._storageService);

  final MonitoringStorageService _storageService;

  @override
  Future<void> savePacket(PacketRecord packet) async {
    await _storageService.savePacket(packet);
  }

  @override
  Future<List<PacketRecord>> getPackets(String sessionId) async {
    return await _storageService.getPackets(sessionId);
  }

  @override
  Future<PacketRecord?> getLatestPacket(String sessionId) async {
    final packets = await _storageService.getPackets(sessionId);
    return packets.isNotEmpty ? packets.last : null;
  }

  @override
  Future<void> saveTimelineEntry(String sessionId, TimelineEntry entry) async {
    await _storageService.saveTimelineEntry(sessionId, entry);
  }

  @override
  Future<List<TimelineEntry>> getTimeline(String sessionId) async {
    return await _storageService.getTimeline(sessionId);
  }

  @override
  Future<void> saveSessionMetadata(SessionMetadata metadata) async {
    await _storageService.saveSessionMetadata(metadata);
  }

  @override
  Future<SessionMetadata?> getActiveSessionMetadata() async {
    return await _storageService.getActiveSessionMetadata();
  }

  @override
  Future<void> clearActiveSessionMetadata() async {
    await _storageService.clearActiveSessionMetadata();
  }

  @override
  Future<void> applyRetentionPolicy(RetentionPolicy policy) async {
    await _storageService.applyRetentionPolicy(policy);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _storageService.deleteSession(sessionId);
  }
}
