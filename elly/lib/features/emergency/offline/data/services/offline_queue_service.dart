/// offline_queue_service.dart
///
/// Persistent local offline queue service storing immutable EmergencyDataPacket records in SharedPreferences.

library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_data_packet.dart';
import 'package:elly/features/emergency/offline/domain/entities/offline_packet.dart';

class OfflineQueueService {
  static const String _storageKey = 'elly_offline_packet_queue_v1';
  final List<OfflinePacket> _queue = [];

  List<OfflinePacket> get pendingPackets => List.unmodifiable(_queue.where((p) => p.packetStatus != PacketStatus.uploaded));
  List<OfflinePacket> get allPackets => List.unmodifiable(_queue);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _queue.clear();
        for (final item in list) {
          _queue.add(OfflinePacket.fromJson(Map<String, dynamic>.from(item as Map)));
        }
        appLogger.info('OfflineQueueService: Loaded ${_queue.length} packets from persistent local queue.');
      }
    } catch (e) {
      appLogger.warning('OfflineQueueService: Could not load local queue: $e');
    }
  }

  Future<OfflinePacket> enqueuePacket(EmergencyDataPacket packet) async {
    final now = AppClock.now();
    final queueId = 'QPKT_${now.millisecondsSinceEpoch}_${packet.sequenceNumber}';

    final offlinePacket = OfflinePacket(
      queueId: queueId,
      packetId: packet.packetId,
      sequenceNumber: packet.sequenceNumber,
      createdAt: now,
      priority: packet.priority,
      packetStatus: PacketStatus.queued,
      packet: packet,
    );

    _queue.add(offlinePacket);
    await _persist();
    appLogger.info('OfflineQueueService: Enqueued packet ${packet.packetId} (Queue ID: $queueId).');
    return offlinePacket;
  }

  Future<void> markUploaded(String queueId) async {
    final idx = _queue.indexWhere((p) => p.queueId == queueId);
    if (idx != -1) {
      _queue[idx] = _queue[idx].copyWith(packetStatus: PacketStatus.uploaded);
      await _persist();
      appLogger.info('OfflineQueueService: Marked packet $queueId as UPLOADED.');
    }
  }

  Future<void> updatePacketStatus(String queueId, PacketStatus status, {String? failureReason, DateTime? nextRetryAt}) async {
    final idx = _queue.indexWhere((p) => p.queueId == queueId);
    if (idx != -1) {
      _queue[idx] = _queue[idx].copyWith(
        packetStatus: status,
        failureReason: failureReason,
        nextRetryAt: nextRetryAt,
        retryCount: _queue[idx].retryCount + 1,
      );
      await _persist();
    }
  }

  Future<void> dequeuePacket(String queueId) async {
    _queue.removeWhere((p) => p.queueId == queueId);
    await _persist();
  }

  Future<void> clearExpired({Duration maxAge = const Duration(days: 7)}) async {
    final cutoff = AppClock.now().subtract(maxAge);
    _queue.removeWhere((p) => p.createdAt.isBefore(cutoff));
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_queue.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      appLogger.error('OfflineQueueService: Failed persisting queue to SharedPreferences', e);
    }
  }
}
