/// disconnect_protection_service.dart
///
/// Service capturing abrupt shutdown conditions and writing DisconnectInfo to disk.

library;

import 'dart:async';
import '../../domain/entities/disconnect_info.dart';
import '../../domain/entities/reliability_event.dart';
import 'reliability_storage_service.dart';
import 'reliability_event_bus.dart';

class DisconnectProtectionService {
  DisconnectProtectionService({
    ReliabilityStorageService? storage,
    ReliabilityEventBus? eventBus,
  })  : _storage = storage ?? ReliabilityStorageService(),
        _eventBus = eventBus ?? ReliabilityEventBus();

  final ReliabilityStorageService _storage;
  final ReliabilityEventBus _eventBus;

  Future<DisconnectInfo> protectAndRecord({
    required String sessionId,
    required String reason,
    required int lastKnownBattery,
    String? lastKnownCoordinates,
    required int pendingQueueSize,
  }) async {
    final info = DisconnectInfo(
      timestamp: DateTime.now(),
      reason: reason,
      lastKnownBattery: lastKnownBattery,
      lastKnownCoordinates: lastKnownCoordinates,
      pendingQueueSize: pendingQueueSize,
    );

    await _storage.saveDisconnectInfo(sessionId, info);
    _eventBus.publish(DisconnectDetectedEvent(info));

    return info;
  }
}
