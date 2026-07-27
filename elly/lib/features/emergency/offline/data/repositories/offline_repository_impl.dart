/// offline_repository_impl.dart
///
/// Data layer repository implementation integrating ConnectivityService, OfflineQueueService,
/// SynchronizationService, and EmergencyEventBus event listeners.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/domain/entities/network_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/connectivity_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/synchronization_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/pending_operation.dart';
import 'package:elly/features/emergency/offline/domain/entities/offline_session.dart';
import 'package:elly/features/emergency/offline/domain/entities/sync_result.dart';
import 'package:elly/features/emergency/offline/domain/repositories/offline_repository.dart';
import 'package:elly/features/emergency/offline/data/services/connectivity_service.dart';
import 'package:elly/features/emergency/offline/data/services/offline_queue_service.dart';
import 'package:elly/features/emergency/offline/data/services/synchronization_service.dart';

class OfflineRepositoryImpl implements OfflineRepository {
  OfflineRepositoryImpl({
    required ConnectivityService connectivityService,
    required OfflineQueueService queueService,
    required SynchronizationService syncService,
    required EmergencyEventBus eventBus,
  })  : _connectivityService = connectivityService,
        _queueService = queueService,
        _syncService = syncService,
        _eventBus = eventBus,
        _queueStreamController = StreamController<List<PendingOperation>>.broadcast(),
        _networkStreamController = StreamController<NetworkState>.broadcast(),
        _sessionStreamController = StreamController<OfflineSession>.broadcast();

  final ConnectivityService _connectivityService;
  final OfflineQueueService _queueService;
  final SynchronizationService _syncService;
  final EmergencyEventBus _eventBus;

  final StreamController<List<PendingOperation>> _queueStreamController;
  final StreamController<NetworkState> _networkStreamController;
  final StreamController<OfflineSession> _sessionStreamController;

  StreamSubscription? _netSub;
  StreamSubscription? _busSub;
  OfflineSession _session = OfflineSession(
    sessionId: 'off_session_default',
    startedAt: DateTime.now(),
  );

  @override
  Future<void> initialize() async {
    appLogger.info('OfflineRepositoryImpl: Initializing offline repository...');
    await _connectivityService.initialize();
    await _queueService.initialize();

    final mappedNetState = _mapConnToNetState(_connectivityService.currentState);

    _session = _session.copyWith(
      networkState: mappedNetState,
      pendingOperations: _mapQueueToPendingOperations(),
    );
    _emitSession(_session);

    _netSub = _connectivityService.onConnectivityStateChanged.listen((connState) async {
      appLogger.info('OfflineRepositoryImpl: Connectivity state changed to $connState');
      final netState = _mapConnToNetState(connState);
      final wasOffline = _session.isOffline;
      _session = _session.copyWith(networkState: netState);
      _emitSession(_session);
      if (!_networkStreamController.isClosed) {
        _networkStreamController.add(netState);
      }

      // Auto-trigger sync on reconnection
      if (wasOffline && netState == NetworkState.online && _queueService.pendingPackets.isNotEmpty) {
        appLogger.info('OfflineRepositoryImpl: Auto-triggering synchronization upon reconnection');
        await sync();
      }
    });

    _busSub = _eventBus.events.listen((event) {
      if (_session.isOffline) {
        appLogger.info('OfflineRepositoryImpl: Device offline. Tracking event ${event.eventName}');
      }
    });
  }

  @override
  Future<void> enqueue(PendingOperation operation) async {
    _session = _session.copyWith(pendingOperations: _mapQueueToPendingOperations());
    _emitQueue();
    _emitSession(_session);
  }

  @override
  Future<void> dequeue(String id) async {
    await _queueService.dequeuePacket(id);
    _session = _session.copyWith(pendingOperations: _mapQueueToPendingOperations());
    _emitQueue();
    _emitSession(_session);
  }

  @override
  List<PendingOperation> pendingOperations() => _mapQueueToPendingOperations();

  @override
  Stream<List<PendingOperation>> watchQueue() => _queueStreamController.stream;

  @override
  Stream<NetworkState> watchNetwork() => _networkStreamController.stream;

  @override
  Stream<OfflineSession> watchSession() => _sessionStreamController.stream;

  @override
  Future<SyncResult> sync() async {
    if (_queueService.pendingPackets.isEmpty) {
      return const SyncResult(success: true, duration: Duration.zero);
    }

    _session = _session.copyWith(synchronizationState: SynchronizationState.syncing);
    _emitSession(_session);

    await _syncService.synchronizePendingPackets();

    final now = DateTime.now();
    _session = _session.copyWith(
      synchronizationState: SynchronizationState.synchronized,
      lastSync: now,
      pendingOperations: _mapQueueToPendingOperations(),
    );

    _emitQueue();
    _emitSession(_session);
    return SyncResult(
      success: true,
      duration: const Duration(seconds: 1),
      uploadedOperations: _queueService.allPackets.map((p) => p.packetId).toList(),
    );

  }

  @override
  Future<void> clear() async {
    await _queueService.clearExpired(maxAge: Duration.zero);
    _session = _session.copyWith(pendingOperations: const []);
    _emitQueue();
    _emitSession(_session);
  }

  NetworkState _mapConnToNetState(ConnectivityState conn) {
    switch (conn) {
      case ConnectivityState.online:
        return NetworkState.online;
      case ConnectivityState.reconnecting:
        return NetworkState.reconnecting;
      case ConnectivityState.offline:
      case ConnectivityState.airplaneMode:
      case ConnectivityState.noPermission:
      case ConnectivityState.limited:
        return NetworkState.offline;
    }
  }

  List<PendingOperation> _mapQueueToPendingOperations() {
    return _queueService.pendingPackets
        .map((p) => PendingOperation(
              id: p.queueId,
              operationType: 'EMERGENCY_DATA_PACKET',
              payload: p.packet.toJson(),
              timestamp: p.createdAt,
              priority: p.priority.index + 1,
            ))
        .toList();
  }

  void _emitQueue() {
    if (!_queueStreamController.isClosed) {
      _queueStreamController.add(_mapQueueToPendingOperations());
    }
  }

  void _emitSession(OfflineSession session) {
    if (!_sessionStreamController.isClosed) {
      _sessionStreamController.add(session);
    }
  }

  void dispose() {
    _netSub?.cancel();
    _busSub?.cancel();
    _connectivityService.dispose();
  }
}
