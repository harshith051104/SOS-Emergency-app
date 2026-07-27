/// emergency_communication_controller.dart
///
/// Controller managing presentation state for the Emergency Communication Engine.
/// Bridges communication events to the master EmergencySessionController.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';

import '../../../sos/domain/entities/emergency_service_model.dart';
import '../../../sos/presentation/controllers/emergency_session_controller.dart';
import '../../../sos/presentation/providers/emergency_service_provider.dart';
import '../../../sos/presentation/providers/emergency_providers.dart';
import '../../domain/entities/emergency_dispatch_request.dart';
import '../../domain/entities/dispatch_result.dart';
import '../../domain/entities/communication_event.dart';
import '../../domain/repositories/emergency_communication_repository.dart';
import '../../data/repositories/emergency_communication_repository_impl.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';





enum CommunicationEngineStatus {
  idle,
  preparing,
  dialerLaunching,
  active,
  failed,
}

class EmergencyCommunicationState {
  const EmergencyCommunicationState({
    this.status = CommunicationEngineStatus.idle,
    this.lastRequest,
    this.lastResult,
    this.currentPreparingStep = '',
    this.errorMessage,
    this.hasError = false,
  });

  final CommunicationEngineStatus status;
  final EmergencyDispatchRequest? lastRequest;
  final DispatchResult? lastResult;
  final String currentPreparingStep;
  final String? errorMessage;
  final bool hasError;

  EmergencyCommunicationState copyWith({
    CommunicationEngineStatus? status,
    EmergencyDispatchRequest? lastRequest,
    DispatchResult? lastResult,
    String? currentPreparingStep,
    String? errorMessage,
    bool? hasError,
  }) {
    return EmergencyCommunicationState(
      status: status ?? this.status,
      lastRequest: lastRequest ?? this.lastRequest,
      lastResult: lastResult ?? this.lastResult,
      currentPreparingStep: currentPreparingStep ?? this.currentPreparingStep,
      errorMessage: errorMessage ?? this.errorMessage,
      hasError: hasError ?? this.hasError,
    );
  }
}

class EmergencyCommunicationController extends StateNotifier<EmergencyCommunicationState> {
  EmergencyCommunicationController(this._repository, this._ref)
      : super(const EmergencyCommunicationState()) {
    _streamSub = _repository.eventStream.listen(_handleEvent);
  }

  final EmergencyCommunicationRepository _repository;
  final Ref _ref;
  late final StreamSubscription<CommunicationEvent> _streamSub;

  void _handleEvent(CommunicationEvent event) {
    if (!mounted) return;

    switch (event) {
      case DispatchPreparingEvent(:final stepName):
        state = state.copyWith(
          status: CommunicationEngineStatus.preparing,
          currentPreparingStep: stepName,
          hasError: false,
        );
        _ref.read(emergencySessionControllerProvider.notifier).startDispatchPreparing();

      case DialerLaunchingEvent():
        state = state.copyWith(
          status: CommunicationEngineStatus.dialerLaunching,
          hasError: false,
        );
        _ref.read(emergencySessionControllerProvider.notifier).startDialerLaunching();

      case DialerLaunchedEvent():
        appLogger.info('EmergencyCommunicationController: Dialer launched successfully');

      case DispatchCompletedEvent(:final result):
        state = state.copyWith(
          status: CommunicationEngineStatus.active,
          lastResult: result,
          hasError: false,
        );
        _ref.read(emergencySessionControllerProvider.notifier).startEmergencySession();
        _ref.read(sosCircleControllerProvider.notifier).triggerSOSNotifications(
              sessionId: 'EL-${DateTime.now().millisecondsSinceEpoch}',
              emergencyType: 'Emergency Dispatch',
              selectedService: result.communicationMethod,
            );


      case DispatchFailedEvent(:final reason):
        state = state.copyWith(
          status: CommunicationEngineStatus.failed,
          errorMessage: reason,
          hasError: true,
        );
        appLogger.error('EmergencyCommunicationController: Dispatch failed - $reason');

      case EmergencySessionStartedEvent():
        state = state.copyWith(status: CommunicationEngineStatus.active);

      default:
        break;
    }
  }


  /// High-level entry point to execute emergency dispatch via the Communication Engine.
  Future<DispatchResult> executeDispatch({
    required String triggerSource,
    EmergencyService? selectedService,
  }) async {
    final serviceSelection = _ref.read(emergencyServiceProvider);
    final activeService = selectedService ?? serviceSelection.selectedService;

    final number = activeService?.emergencyNumber ?? '112';
    final sessionId = 'EL-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final request = EmergencyDispatchRequest(
      sessionId: sessionId,
      triggerSource: triggerSource,
      selectedService: activeService ??
          const EmergencyService(
            id: 'srv_universal',
            name: 'Universal Helpline',
            description: 'National Unified Emergency Response Standard',
            emergencyNumber: '112',
            icon: Icons.emergency_rounded,
            category: 'universal',
            priority: 6,
          ),

      selectedEmergencyNumber: number,
      selectedAt: DateTime.now(),
    );

    state = state.copyWith(
      status: CommunicationEngineStatus.preparing,
      lastRequest: request,
      hasError: false,
    );

    // Also trigger emergency packet generator in EmergencyController
    _ref.read(emergencyControllerProvider.notifier).startGeneratingPacket(category: request.selectedService.name);

    return await _repository.startEmergencyCommunication(request);
  }

  void reset() {
    state = const EmergencyCommunicationState();
  }

  @override
  void dispose() {
    _streamSub.cancel();
    super.dispose();
  }
}

final emergencyCommunicationRepositoryProvider = Provider<EmergencyCommunicationRepository>((ref) {
  return EmergencyCommunicationRepositoryImpl();
});

final emergencyCommunicationControllerProvider =
    StateNotifierProvider<EmergencyCommunicationController, EmergencyCommunicationState>((ref) {
  final repo = ref.watch(emergencyCommunicationRepositoryProvider);
  return EmergencyCommunicationController(repo, ref);
});


