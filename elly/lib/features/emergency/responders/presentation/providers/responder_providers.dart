/// responder_providers.dart
///
/// All Riverpod providers for the Responders feature.
/// Single DI wiring file — widgets reference providers, never constructors.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/responder_local_datasource.dart';
import '../../data/repositories/responder_repository_impl.dart';
import '../../data/services/mock_emergency_response_engine.dart';
import '../../data/services/mock_notification_service.dart';
import '../../domain/repositories/responder_repository.dart';
import '../../domain/services/emergency_response_engine.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/usecases/delete_responder_usecase.dart';
import '../../domain/usecases/get_responders_usecase.dart';
import '../../domain/usecases/reorder_responders_usecase.dart';
import '../../domain/usecases/save_responder_usecase.dart';
import '../../domain/usecases/trigger_response_usecase.dart';
import '../controllers/responders_controller.dart';
import '../controllers/response_engine_controller.dart';

import '../../../packet/presentation/providers/packet_providers.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final responderLocalDataSourceProvider =
    Provider<ResponderLocalDataSource>((ref) {
  return ResponderLocalDataSourceImpl();
});

final responderRepositoryProvider = Provider<ResponderRepository>((ref) {
  return ResponderRepositoryImpl(
    dataSource: ref.watch(responderLocalDataSourceProvider),
  );
});

// ── Services ──────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return MockNotificationService();
});

final emergencyResponseEngineProvider =
    Provider<EmergencyResponseEngine>((ref) {
  return MockEmergencyResponseEngine(
    notificationService: ref.watch(notificationServiceProvider),
  );
});

// ── Use Cases ─────────────────────────────────────────────────────────────────

final getRespondersUseCaseProvider = Provider<GetRespondersUseCase>((ref) {
  return GetRespondersUseCase(ref.watch(responderRepositoryProvider));
});

final saveResponderUseCaseProvider = Provider<SaveResponderUseCase>((ref) {
  return SaveResponderUseCase(ref.watch(responderRepositoryProvider));
});

final deleteResponderUseCaseProvider = Provider<DeleteResponderUseCase>((ref) {
  return DeleteResponderUseCase(ref.watch(responderRepositoryProvider));
});

final reorderRespondersUseCaseProvider =
    Provider<ReorderRespondersUseCase>((ref) {
  return ReorderRespondersUseCase(ref.watch(responderRepositoryProvider));
});

final triggerResponseUseCaseProvider =
    Provider<TriggerResponseUseCase>((ref) {
  return TriggerResponseUseCase(
    repository: ref.watch(responderRepositoryProvider),
    engine: ref.watch(emergencyResponseEngineProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});

// ── Controllers ───────────────────────────────────────────────────────────────

/// Manages the list of responders (CRUD + reorder).
final respondersControllerProvider =
    StateNotifierProvider<RespondersController, RespondersState>((ref) {
  return RespondersController(
    getRespondersUseCase: ref.watch(getRespondersUseCaseProvider),
    saveResponderUseCase: ref.watch(saveResponderUseCaseProvider),
    deleteResponderUseCase: ref.watch(deleteResponderUseCaseProvider),
    reorderRespondersUseCase: ref.watch(reorderRespondersUseCaseProvider),
  );
});

/// Manages the live engine execution state (timeline of events).
final responseEngineControllerProvider =
    StateNotifierProvider<ResponseEngineController, ResponseEngineState>((ref) {
  return ResponseEngineController(
    triggerResponseUseCase: ref.watch(triggerResponseUseCaseProvider),
  );
});
