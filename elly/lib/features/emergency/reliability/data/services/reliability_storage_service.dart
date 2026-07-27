/// reliability_storage_service.dart
///
/// Encodes, calculates checksums (32-bit FNV-1a), and persists queue items, disconnect logs, and reliability markers.

library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/emergency_queue_item.dart';
import '../../domain/entities/queue_priority.dart';
import '../../domain/entities/delivery_guarantee.dart';
import '../../domain/entities/transport_config.dart';
import '../../domain/entities/disconnect_info.dart';

class ReliabilityStorageService {
  static const String _queuePrefix = 'elly_rel_queue_';
  static const String _disconnectLogPrefix = 'elly_rel_disconnect_';


  Future<void> saveQueueItem(EmergencyQueueItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_queuePrefix${item.sessionId}_${item.id}';
      final jsonMap = _itemToJson(item);
      await prefs.setString(key, jsonEncode(jsonMap));
    } catch (_) {}
  }

  Future<List<EmergencyQueueItem>> getQueueItems(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('$_queuePrefix${sessionId}_'));

      final list = <EmergencyQueueItem>[];
      for (final key in keys) {
        final str = prefs.getString(key);
        if (str != null) {
          try {
            final map = jsonDecode(str) as Map<String, dynamic>;
            final item = _itemFromJson(map);

            // Re-verify payload checksum
            final expected = calculateFnv1aChecksum('${item.sessionId}|${item.sequenceNumber}|${item.payloadJson}');
            if (item.checksum != expected) {
              list.add(item.copyWith(status: QueueItemStatus.corrupted));
            } else {
              list.add(item);
            }
          } catch (_) {}
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> removeItem(String sessionId, String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_queuePrefix${sessionId}_$itemId';
      await prefs.remove(key);
    } catch (_) {}
  }

  Future<void> saveDisconnectInfo(String sessionId, DisconnectInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_disconnectLogPrefix$sessionId';
      final map = {
        'timestamp': info.timestamp.toIso8601String(),
        'reason': info.reason,
        'lastKnownBattery': info.lastKnownBattery,
        'lastKnownCoordinates': info.lastKnownCoordinates,
        'pendingQueueSize': info.pendingQueueSize,
      };
      await prefs.setString(key, jsonEncode(map));
    } catch (_) {}
  }

  /// 32-bit FNV-1a checksum calculation (Web & Mobile cross-platform compatible).
  String calculateFnv1aChecksum(String payload) {
    var hash = 0x811c9dc5;
    final bytes = utf8.encode(payload);
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  Map<String, dynamic> _itemToJson(EmergencyQueueItem item) {
    return {
      'id': item.id,
      'sessionId': item.sessionId,
      'sequenceNumber': item.sequenceNumber,
      'itemType': item.itemType,
      'payloadJson': item.payloadJson,
      'idempotencyKey': item.idempotencyKey,
      'priority': item.priority.name,
      'guaranteeLevel': item.guaranteeLevel.name,
      'supportedTransports': item.transportConfig.supportedTransports,
      'preferredTransport': item.transportConfig.preferredTransport,
      'fallbackOrder': item.transportConfig.fallbackOrder,
      'attempts': item.attempts,
      'createdAt': item.createdAt.toIso8601String(),
      'status': item.status.name,
      'checksum': item.checksum,
    };
  }

  EmergencyQueueItem _itemFromJson(Map<String, dynamic> j) {
    return EmergencyQueueItem(
      id: j['id'] as String,
      sessionId: j['sessionId'] as String,
      sequenceNumber: j['sequenceNumber'] as int,
      itemType: j['itemType'] as String,
      payloadJson: j['payloadJson'] as String,
      idempotencyKey: j['idempotencyKey'] as String,
      priority: QueuePriority.values.firstWhere(
        (e) => e.name == j['priority'],
        orElse: () => QueuePriority.critical,
      ),
      guaranteeLevel: DeliveryGuaranteeLevel.values.firstWhere(
        (e) => e.name == j['guaranteeLevel'],
        orElse: () => DeliveryGuaranteeLevel.mustDeliver,
      ),
      transportConfig: TransportConfig(
        supportedTransports: List<String>.from(j['supportedTransports'] ?? ['http']),
        preferredTransport: j['preferredTransport'] as String? ?? 'http',
        fallbackOrder: List<String>.from(j['fallbackOrder'] ?? ['http']),
      ),
      attempts: j['attempts'] as int,
      createdAt: DateTime.parse(j['createdAt'] as String),
      status: QueueItemStatus.values.firstWhere(
        (e) => e.name == j['status'],
        orElse: () => QueueItemStatus.pending,
      ),
      checksum: j['checksum'] as String,
    );
  }
}
