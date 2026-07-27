/// offline_repository.dart
///
/// Abstract domain repository interface for offline mode state, queue, and sync streams.

library;

import 'package:elly/features/emergency/offline/domain/entities/network_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/offline_session.dart';
import 'package:elly/features/emergency/offline/domain/entities/pending_operation.dart';
import 'package:elly/features/emergency/offline/domain/entities/sync_result.dart';

abstract class OfflineRepository {
  Future<void> initialize();
  Future<void> enqueue(PendingOperation operation);
  Future<void> dequeue(String id);
  List<PendingOperation> pendingOperations();
  Stream<List<PendingOperation>> watchQueue();
  Stream<NetworkState> watchNetwork();
  Stream<OfflineSession> watchSession();
  Future<SyncResult> sync();
  Future<void> clear();
}
