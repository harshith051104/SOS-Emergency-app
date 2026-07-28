/// emergency_session_controller.dart
///
/// Master Emergency Session Controller orchestrating high-level lifecycle steps,
/// anti-false trigger confirmation policy checks, voice confirmation endpoints,
/// strongly-typed EventBus publishing, unique confirmationId tracking, and metrics collection.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import '../../domain/entities/emergency_service_model.dart';
import '../../domain/entities/sos_countdown_state.dart';
import '../../domain/entities/confirmation_state.dart';
import '../../domain/entities/confirmation_metrics.dart';
import '../../domain/entities/emergency_platform_events.dart';
import '../../domain/entities/sos_trigger_config.dart';
import '../../domain/validation/confirmation_policy.dart';
import '../providers/sos_countdown_provider.dart';
import '../providers/emergency_service_provider.dart';

import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/global/domain/services/country_resolver.dart';
import 'package:elly/features/emergency/global/domain/entities/emergency_service_directory.dart';
import 'package:elly/features/emergency/telemetry/presentation/providers/telemetry_providers.dart';

enum EmergencySessionStep {
  idle,
  countdownRunning,
  preparingDispatch,
  dialerLaunching,
  emergencyActive,
  emergencyEnded,
  cancelled,
}

class EmergencySessionState {
  const EmergencySessionState({
    this.step = EmergencySessionStep.idle,
    this.selectedService,
    this.sessionId,
    this.lastConfirmationResult,
    this.metrics = const ConfirmationMetrics(),
  });

  final EmergencySessionStep step;
  final EmergencyService? selectedService;
  final String? sessionId;
  final ConfirmationResult? lastConfirmationResult;
  final ConfirmationMetrics metrics;

  EmergencySessionState copyWith({
    EmergencySessionStep? step,
    EmergencyService? selectedService,
    String? sessionId,
    ConfirmationResult? lastConfirmationResult,
    ConfirmationMetrics? metrics,
  }) {
    return EmergencySessionState(
      step: step ?? this.step,
      selectedService: selectedService ?? this.selectedService,
      sessionId: sessionId ?? this.sessionId,
      lastConfirmationResult: lastConfirmationResult ?? this.lastConfirmationResult,
      metrics: metrics ?? this.metrics,
    );
  }
}

final emergencySessionControllerProvider =
    StateNotifierProvider<EmergencySessionController, EmergencySessionState>((ref) {
  return EmergencySessionController(ref);
});

class EmergencySessionController extends StateNotifier<EmergencySessionState> {
  EmergencySessionController(this._ref) : super(const EmergencySessionState()) {
    // Subscribe to countdown events
    _ref.listen(sosCountdownEventStreamProvider, (previous, next) {
      next.whenData((event) {
        if (event is CountdownCompletedEvent) {
          onCountdownCompleted();
        }
      });
    });
  }

  final Ref _ref;

  void startSos({
    String source = 'MANUAL SOS',
    SosTriggerConfig config = const SosTriggerConfig(),
  }) {
    if (state.step == EmergencySessionStep.countdownRunning ||
        state.step == EmergencySessionStep.preparingDispatch ||
        state.step == EmergencySessionStep.emergencyActive) {
      return; // Guard against rapid duplicate calls
    }

    final emergencyContext = _ref.read(emergencyContextProvider);

    // Evaluate ConfirmationPolicy (handles highRisk, skipConfirmation, config)
    final needsConfirmation = ConfirmationPolicy.shouldConfirm(
      context: emergencyContext,
      config: config,
    );

    final now = AppClock.now();
    final confId = 'CONF_${now.millisecondsSinceEpoch}';

    if (!needsConfirmation) {
      appLogger.info('EmergencySessionController: High Risk or Confirmation Disabled. Bypassing confirmation screen.');
      
      final bypassedEvent = HighRiskBypassedPlatformEvent(
        eventId: 'evt_bypass_${now.millisecondsSinceEpoch}',
        timestamp: now,
        reason: emergencyContext.highRisk ? 'High Risk Assessed' : 'Confirmation Disabled',
      );

      _ref.read(emergencyEventBusProvider).publish(bypassedEvent.toJson()['type'] as String, bypassedEvent.toJson());

      state = state.copyWith(
        metrics: state.metrics.copyWith(
          highRiskBypasses: state.metrics.highRiskBypasses + 1,
        ),
      );

      _recordTimeline(
        title: 'High Risk Confirmation Bypassed',
        description: 'Skipped confirmation screen due to high risk assessment (ID: $confId).',
        severity: EventSeverity.warning,
      );

      _finalizeSelectionAndProceed();
      startEmergencySession();
      return;
    }

    state = state.copyWith(step: EmergencySessionStep.countdownRunning);

    // Auto-select emergency helpline based on live GPS location coordinates
    final telemetryState = _ref.read(telemetryControllerProvider);
    final countryResult = CountryResolver.resolve(location: telemetryState.latestPoint);
    final countryProfile = EmergencyServiceDirectory.getProfile(countryResult.countryCode);
    final resolvedNumber = countryProfile.universalNumber;



    final autoSelectedService = EmergencyService(
      id: 'srv_universal_${countryProfile.countryCode}',
      name: 'Universal Emergency (${countryProfile.countryName})',
      description: 'Live GPS Emergency Line for ${countryProfile.countryName}',
      emergencyNumber: resolvedNumber,
      icon: Icons.emergency_rounded,
      category: 'universal',
      priority: 6,
    );

    _ref.read(emergencyServiceProvider.notifier).selectService(autoSelectedService);
    state = state.copyWith(selectedService: autoSelectedService);


    _ref.read(emergencyEventBusProvider).publish('ConfirmationStarted', {
      'confirmationId': confId,
      'source': source,
      'durationSeconds': config.confirmationDurationSeconds,
      'timestamp': now.toIso8601String(),
    });

    _recordTimeline(
      title: 'Confirmation Started',
      description: 'Anti-false trigger countdown started (${config.confirmationDurationSeconds}s) [ID: $confId].',
      severity: EventSeverity.info,
    );

    _ref.read(sosCountdownStateProvider.notifier).startCountdown(
          source: source,
          durationSeconds: config.confirmationDurationSeconds,
        );
  }

  void selectService(EmergencyService service) {
    _ref.read(emergencyServiceProvider.notifier).selectService(service);
    state = state.copyWith(selectedService: service);
  }

  void completeServiceSelection(EmergencyService service) {
    selectService(service);
    _finalizeSelectionAndProceed();
  }

  void startDispatchPreparing() {
    state = state.copyWith(step: EmergencySessionStep.preparingDispatch);
  }

  void startDialerLaunching() {
    state = state.copyWith(step: EmergencySessionStep.dialerLaunching);
  }

  void onCountdownCompleted() {
    final now = AppClock.now();
    appLogger.info('EmergencySessionController: Confirmation Countdown Timeout occurred.');
    
    final result = ConfirmationResult(
      confirmationId: 'CONF_${now.millisecondsSinceEpoch}',
      response: ConfirmationResponse.none,
      duration: const Duration(seconds: 10),
      timeoutOccurred: true,
      emergencyTriggered: true,
      confirmationMethod: 'automatic_timeout',
      timestamp: now,
    );

    final event = ConfirmationTimeoutPlatformEvent(
      eventId: 'evt_timeout_${now.millisecondsSinceEpoch}',
      timestamp: now,
      result: result,
    );

    state = state.copyWith(
      lastConfirmationResult: result,
      metrics: state.metrics.copyWith(
        totalConfirmations: state.metrics.totalConfirmations + 1,
        timeouts: state.metrics.timeouts + 1,
      ),
    );

    _ref.read(emergencyEventBusProvider).publish('ConfirmationTimeout', event.toJson());
    _recordTimeline(
      title: 'Confirmation Timeout',
      description: 'No response received before countdown expired. Proceeding to automatic emergency dispatch. [ID: ${result.confirmationId}]',
      severity: EventSeverity.warning,
    );

    _finalizeSelectionAndProceed();
    startEmergencySession();
  }

  void sendNow() {
    _ref.read(sosCountdownStateProvider.notifier).cancelCountdown();
    _finalizeSelectionAndProceed();
    startEmergencySession();
  }

  /// User explicitly confirmed safe ("I'M SAFE 💚"): cancels countdown and publishes strongly typed event
  void confirmSafe({String method = 'button', double? confidence}) {
    final now = AppClock.now();
    _ref.read(sosCountdownStateProvider.notifier).cancelCountdown();
    _ref.read(emergencyServiceProvider.notifier).clearSelection();

    final result = ConfirmationResult(
      confirmationId: 'CONF_${now.millisecondsSinceEpoch}',
      response: ConfirmationResponse.safe,
      cancellationReason: CancellationReason.userConfirmedSafe,
      duration: const Duration(seconds: 3),
      timeoutOccurred: false,
      emergencyTriggered: false,
      confirmationMethod: method,
      confidence: confidence,
      timestamp: now,
    );

    final event = SafeConfirmedPlatformEvent(
      eventId: 'evt_safe_${now.millisecondsSinceEpoch}',
      timestamp: now,
      result: result,
    );

    state = state.copyWith(
      step: EmergencySessionStep.cancelled,
      lastConfirmationResult: result,
      metrics: state.metrics.copyWith(
        totalConfirmations: state.metrics.totalConfirmations + 1,
        safeConfirmations: state.metrics.safeConfirmations + 1,
      ),
    );

    _ref.read(emergencyEventBusProvider).publish('SafeConfirmed', event.toJson());
    _recordTimeline(
      title: 'User Confirmed Safe',
      description: 'User confirmed safety via $method. SOS activation cancelled. [ID: ${result.confirmationId}]',
      severity: EventSeverity.info,
    );
  }

  /// User explicitly confirmed emergency ("NEED HELP NOW 🛑"): bypasses remaining countdown & starts SOS
  void confirmEmergency({String method = 'button', double? confidence}) {
    final now = AppClock.now();
    _ref.read(sosCountdownStateProvider.notifier).cancelCountdown();

    final result = ConfirmationResult(
      confirmationId: 'CONF_${now.millisecondsSinceEpoch}',
      response: ConfirmationResponse.emergency,
      duration: const Duration(seconds: 2),
      timeoutOccurred: false,
      emergencyTriggered: true,
      confirmationMethod: method,
      confidence: confidence,
      timestamp: now,
    );

    final event = EmergencyConfirmedPlatformEvent(
      eventId: 'evt_emg_${now.millisecondsSinceEpoch}',
      timestamp: now,
      result: result,
    );

    state = state.copyWith(
      lastConfirmationResult: result,
      metrics: state.metrics.copyWith(
        totalConfirmations: state.metrics.totalConfirmations + 1,
        emergencyConfirmations: state.metrics.emergencyConfirmations + 1,
      ),
    );

    _ref.read(emergencyEventBusProvider).publish('EmergencyConfirmed', event.toJson());
    _recordTimeline(
      title: 'User Confirmed Emergency',
      description: 'User confirmed emergency via $method. Bypassing remaining countdown. [ID: ${result.confirmationId}]',
      severity: EventSeverity.warning,
    );

    _finalizeSelectionAndProceed();
    startEmergencySession();
  }

  /// Voice Confirmation Endpoint for Sprint 11 Voice Trigger integration
  void submitVoiceConfirmation({
    required String transcript,
    required double confidence,
    required ConfirmationResponse response,
  }) {
    appLogger.info('EmergencySessionController: Voice confirmation received: "$transcript" (confidence: $confidence)');
    if (response == ConfirmationResponse.safe) {
      confirmSafe(method: 'voice', confidence: confidence);
    } else if (response == ConfirmationResponse.emergency) {
      confirmEmergency(method: 'voice', confidence: confidence);
    }
  }

  void _finalizeSelectionAndProceed() {
    if (state.step == EmergencySessionStep.preparingDispatch ||
        state.step == EmergencySessionStep.emergencyActive) {
      return; // Guard against duplicate finalization
    }

    final currentSelected = _ref.read(emergencyServiceProvider).selectedService;

    const universalFallback = EmergencyService(
      id: 'srv_universal',
      name: 'Universal Helpline',
      description: 'National Unified Emergency Response Standard',
      emergencyNumber: '112',
      icon: Icons.emergency_rounded,
      category: 'universal',
      priority: 6,
    );

    final finalService = currentSelected ?? universalFallback;
    _ref.read(emergencyServiceProvider.notifier).selectService(finalService);
    _ref.read(emergencyServiceProvider.notifier).confirmSelection();

    state = state.copyWith(
      step: EmergencySessionStep.preparingDispatch,
      selectedService: finalService,
    );
  }

  void startCommunicationStarted() {
    state = state.copyWith(step: EmergencySessionStep.dialerLaunching);
  }

  void startEmergencySession() {
    state = state.copyWith(step: EmergencySessionStep.emergencyActive);
    final context = _ref.read(emergencyContextProvider);
    _ref.read(activeEmergencySessionControllerProvider.notifier).createAndStartSession(context);
  }

  void cancelEmergency() {
    _ref.read(sosCountdownStateProvider.notifier).cancelCountdown();
    _ref.read(emergencyServiceProvider.notifier).clearSelection();
    _ref.read(activeEmergencySessionControllerProvider.notifier).endSession();
    state = state.copyWith(step: EmergencySessionStep.cancelled);
  }

  void resetToIdle() {
    _ref.read(sosCountdownStateProvider.notifier).resetToIdle();
    _ref.read(emergencyServiceProvider.notifier).clearSelection();
    _ref.read(activeEmergencySessionControllerProvider.notifier).endSession();
    state = const EmergencySessionState();
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = _ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_conf_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.lifecycle,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Confirmation System',
      ));
    } catch (e) {
      appLogger.warning('EmergencySessionController: Could not log timeline event: $e');
    }
  }
}
