/// offline_providers.dart
///
/// Riverpod dependency injection definitions exposing ConnectivityService,
/// OfflineQueueService, SynchronizationService, OfflineRepository, and OfflineController.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/domain/entities/network_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/synchronization_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/pending_operation.dart';
import 'package:elly/features/emergency/offline/domain/entities/offline_session.dart';
import 'package:elly/features/emergency/offline/domain/repositories/offline_repository.dart';
import 'package:elly/features/emergency/offline/data/services/connectivity_service.dart';
import 'package:elly/features/emergency/offline/data/services/offline_queue_service.dart';
import 'package:elly/features/emergency/offline/data/services/synchronization_service.dart';
import 'package:elly/features/emergency/offline/data/repositories/offline_repository_impl.dart';
import 'package:elly/features/emergency/offline/presentation/controllers/offline_controller.dart';

final emergencyEventBusProvider = Provider<EmergencyEventBus>((ref) {
  final bus = EmergencyEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final offlineQueueProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

final synchronizationServiceProvider = Provider<SynchronizationService>((ref) {
  final queueService = ref.watch(offlineQueueProvider);
  final eventBus = ref.watch(emergencyEventBusProvider);
  return SynchronizationService(ref: ref, queueService: queueService, eventBus: eventBus);
});

final offlineRepositoryProvider = Provider<OfflineRepository>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final queue = ref.watch(offlineQueueProvider);
  final syncService = ref.watch(synchronizationServiceProvider);
  final eventBus = ref.watch(emergencyEventBusProvider);

  final repository = OfflineRepositoryImpl(
    connectivityService: connectivity,
    queueService: queue,
    syncService: syncService,
    eventBus: eventBus,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final offlineControllerProvider =
    StateNotifierProvider<OfflineController, OfflineSession>((ref) {
  final repository = ref.watch(offlineRepositoryProvider);
  return OfflineController(repository);
});

final networkStateProvider = Provider<NetworkState>((ref) {
  final session = ref.watch(offlineControllerProvider);
  return session.networkState;
});

final pendingOperationsProvider = Provider<List<PendingOperation>>((ref) {
  final session = ref.watch(offlineControllerProvider);
  return session.pendingOperations;
});

final syncStatusProvider = Provider<SynchronizationState>((ref) {
  final session = ref.watch(offlineControllerProvider);
  return session.synchronizationState;
});
