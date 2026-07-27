/// resilience_providers.dart
///
/// Riverpod dependency injection definitions exposing QueueRecoveryService,
/// StorageManager, OfflineHealthMonitor, and OfflineResilienceController.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/offline_resilience/domain/entities/offline_health_report.dart';
import 'package:elly/features/emergency/offline_resilience/domain/services/queue_recovery_service.dart';
import 'package:elly/features/emergency/offline_resilience/domain/services/storage_manager.dart';
import 'package:elly/features/emergency/offline_resilience/domain/services/offline_health_monitor.dart';
import 'package:elly/features/emergency/offline_resilience/presentation/controllers/offline_resilience_controller.dart';

final queueRecoveryServiceProvider = Provider<QueueRecoveryService>((ref) {
  return QueueRecoveryService(ref);
});

final storageManagerProvider = Provider<StorageManager>((ref) {
  return StorageManager(ref);
});

final offlineHealthMonitorProvider = Provider<OfflineHealthMonitor>((ref) {
  final storageManager = ref.watch(storageManagerProvider);
  return OfflineHealthMonitor(ref, storageManager);
});

final offlineResilienceControllerProvider =
    StateNotifierProvider<OfflineResilienceController, OfflineHealthReport?>((ref) {
  final recovery = ref.watch(queueRecoveryServiceProvider);
  final storage = ref.watch(storageManagerProvider);
  final health = ref.watch(offlineHealthMonitorProvider);
  return OfflineResilienceController(ref, recovery, storage, health);
});
