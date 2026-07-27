/// monitoring_provider.dart
///
/// Riverpod providers exposing the Emergency Monitoring Engine subsystems to UI components.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/monitoring_state.dart';
import '../../domain/entities/monitoring_metrics.dart';
import '../../domain/entities/packet_record.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/entities/monitoring_event.dart';
import '../../domain/repositories/i_monitoring_repository.dart';
import '../../domain/repositories/i_packet_storage_repository.dart';
import '../../domain/usecases/start_monitoring_usecase.dart';
import '../../domain/usecases/stop_monitoring_usecase.dart';
import '../../domain/usecases/update_monitoring_config_usecase.dart';
import '../../domain/usecases/recover_monitoring_session_usecase.dart';
import '../../domain/usecases/get_monitoring_status_usecase.dart';
import '../../data/services/monitoring_storage_service.dart';
import '../../data/services/monitoring_event_bus.dart';
import '../../data/services/monitoring_engine_service.dart';
import '../../data/repositories/monitoring_repository_impl.dart';
import '../../data/repositories/packet_storage_repository_impl.dart';

final monitoringStorageServiceProvider = Provider<MonitoringStorageService>((ref) {
  return MonitoringStorageService();
});

final monitoringEventBusProvider = Provider<MonitoringEventBus>((ref) {
  final bus = MonitoringEventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
});

final monitoringEngineServiceProvider = Provider<MonitoringEngineService>((ref) {
  final storage = ref.watch(monitoringStorageServiceProvider);
  final bus = ref.watch(monitoringEventBusProvider);
  final engine = MonitoringEngineService(
    storageService: storage,
    eventBus: bus,
  );
  ref.onDispose(() => engine.dispose());
  return engine;
});

final monitoringRepositoryProvider = Provider<IMonitoringRepository>((ref) {
  final engine = ref.watch(monitoringEngineServiceProvider);
  return MonitoringRepositoryImpl(engine);
});

final packetStorageRepositoryProvider = Provider<IPacketStorageRepository>((ref) {
  final storage = ref.watch(monitoringStorageServiceProvider);
  return PacketStorageRepositoryImpl(storage);
});

// ── Use Cases ───────────────────────────────────────────────

final startMonitoringUseCaseProvider = Provider<StartMonitoringUseCase>((ref) {
  return StartMonitoringUseCase(ref.watch(monitoringRepositoryProvider));
});

final stopMonitoringUseCaseProvider = Provider<StopMonitoringUseCase>((ref) {
  return StopMonitoringUseCase(ref.watch(monitoringRepositoryProvider));
});

final updateMonitoringConfigUseCaseProvider = Provider<UpdateMonitoringConfigUseCase>((ref) {
  return UpdateMonitoringConfigUseCase(ref.watch(monitoringRepositoryProvider));
});

final recoverMonitoringSessionUseCaseProvider = Provider<RecoverMonitoringSessionUseCase>((ref) {
  return RecoverMonitoringSessionUseCase(ref.watch(monitoringRepositoryProvider));
});

final getMonitoringStatusUseCaseProvider = Provider<GetMonitoringStatusUseCase>((ref) {
  return GetMonitoringStatusUseCase(ref.watch(monitoringRepositoryProvider));
});

// ── Reactive Stream Providers ───────────────────────────────

final monitoringEngineStateProvider = StreamProvider<MonitoringEngineState>((ref) {
  final repository = ref.watch(monitoringRepositoryProvider);
  return repository.stateStream;
});

final packetStreamProvider = StreamProvider<PacketRecord>((ref) {
  final repository = ref.watch(monitoringRepositoryProvider);
  return repository.packetStream;
});

final monitoringEventStreamProvider = StreamProvider<MonitoringEvent>((ref) {
  final repository = ref.watch(monitoringRepositoryProvider);
  return repository.eventStream;
});

final timelineEventsProvider = Provider<List<TimelineEntry>>((ref) {
  final engine = ref.watch(monitoringEngineServiceProvider);
  return engine.currentTimeline;
});

final monitoringMetricsProvider = Provider<MonitoringMetrics>((ref) {
  final repository = ref.watch(monitoringRepositoryProvider);
  return repository.currentMetrics;
});
