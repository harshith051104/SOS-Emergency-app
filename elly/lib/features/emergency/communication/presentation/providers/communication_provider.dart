/// communication_provider.dart
///
/// Riverpod Providers for Phase 2.0 Communication Manager.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/communication_state.dart';
import '../../domain/entities/communication_event.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/transport_score.dart';
import '../../domain/entities/transport_health.dart';
import '../../domain/repositories/i_communication_repository.dart';
import '../../domain/repositories/i_transport_repository.dart';
import '../../domain/repositories/i_delivery_tracker_repository.dart';
import '../../domain/usecases/send_emergency_communication_usecase.dart';
import '../../domain/usecases/select_optimal_transport_usecase.dart';
import '../../domain/usecases/track_delivery_status_usecase.dart';
import '../../domain/usecases/escalate_communication_usecase.dart';
import '../../domain/usecases/get_transport_health_usecase.dart';
import '../../data/services/communication_manager_service.dart';
import '../../data/repositories/communication_repository_impl.dart';
import '../../data/repositories/transport_repository_impl.dart';
import '../../data/repositories/delivery_tracker_repository_impl.dart';

final communicationManagerServiceProvider = Provider<CommunicationManagerService>((ref) {
  return CommunicationManagerService();
});

final communicationRepositoryProvider = Provider<ICommunicationRepository>((ref) {
  final service = ref.watch(communicationManagerServiceProvider);
  return CommunicationRepositoryImpl(service: service);
});

final transportRepositoryProvider = Provider<ITransportRepository>((ref) {
  final service = ref.watch(communicationManagerServiceProvider);
  return TransportRepositoryImpl(
    selectionEngine: service.selectionEngine,
    healthMonitor: service.healthMonitor,
  );
});

final deliveryTrackerRepositoryProvider = Provider<IDeliveryTrackerRepository>((ref) {
  final service = ref.watch(communicationManagerServiceProvider);
  return DeliveryTrackerRepositoryImpl(trackerService: service.trackerService);
});

final sendEmergencyCommunicationUseCaseProvider = Provider<SendEmergencyCommunicationUseCase>((ref) {
  return SendEmergencyCommunicationUseCase(ref.watch(communicationRepositoryProvider));
});

final selectOptimalTransportUseCaseProvider = Provider<SelectOptimalTransportUseCase>((ref) {
  return SelectOptimalTransportUseCase(ref.watch(transportRepositoryProvider));
});

final trackDeliveryStatusUseCaseProvider = Provider<TrackDeliveryStatusUseCase>((ref) {
  return TrackDeliveryStatusUseCase(ref.watch(deliveryTrackerRepositoryProvider));
});

final escalateCommunicationUseCaseProvider = Provider<EscalateCommunicationUseCase>((ref) {
  return EscalateCommunicationUseCase(ref.watch(communicationRepositoryProvider));
});

final getTransportHealthUseCaseProvider = Provider<GetTransportHealthUseCase>((ref) {
  return GetTransportHealthUseCase(ref.watch(transportRepositoryProvider));
});

final communicationStateStreamProvider = StreamProvider<CommunicationState>((ref) {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.stateStream;
});

final communicationEventStreamProvider = StreamProvider<CommunicationEvent>((ref) {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.eventStream;
});

final deliveryTrackerStreamProvider = StreamProvider<DeliveryStatus>((ref) {
  final repo = ref.watch(deliveryTrackerRepositoryProvider);
  return repo.deliveryStream;
});

final transportScoresProvider = FutureProvider<List<TransportScore>>((ref) async {
  final repo = ref.watch(transportRepositoryProvider);
  return await repo.evaluateAllTransports();
});

final transportHealthMatrixProvider = FutureProvider<Map<String, TransportHealth>>((ref) async {
  final repo = ref.watch(transportRepositoryProvider);
  return await repo.getTransportHealthMatrix();
});
