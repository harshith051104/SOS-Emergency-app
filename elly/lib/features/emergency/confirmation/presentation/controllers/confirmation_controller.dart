/// confirmation_controller.dart
///
/// Master presentation StateNotifier controller managing Confirmation Engine lifecycle,
/// countdown timers, strategy selection, user interactions, and event publishing over EmergencyEventBus.

library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/decision_recommendation.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

import '../../domain/entities/confirmation_state.dart';
import '../../domain/entities/confirmation_strategy.dart';
import '../../domain/entities/confirmation_request.dart';
import '../../domain/entities/confirmation_outcome.dart';
import '../../domain/entities/confirmation_method.dart';
import '../../domain/entities/confirmation_error.dart';
import '../../domain/entities/confirmation_events.dart';
import '../../domain/entities/session_lifecycle_state.dart';
import '../../domain/entities/interruption_reason.dart';
import '../../data/services/confirmation_service.dart';

class ConfirmationController extends StateNotifier<ConfirmationState> {
  ConfirmationController(
    this._ref, {
    required ConfirmationService service,
  })  : _service = service,
        super(const ConfirmationState()) {
    _initEventBusListener();
  }

  final Ref _ref;
  final ConfirmationService _service;
  StreamSubscription<PlatformEvent>? _busSubscription;
  Timer? _countdownTimer;

  void _initEventBusListener() {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      _busSubscription = bus.events.listen((event) {
        // Only react to the full EmergencyDecision payload (which includes emergencyConfidence).
        // DecisionCompleted is a redundant summary event; handling it causes duplicate evaluations.
        if (event.eventName == 'EmergencyDecision') {
          _handleDecisionEvent(event);
        }
      });
    } catch (e) {
      appLogger.warning('ConfirmationController: Could not subscribe to EmergencyEventBus: $e');
    }
  }

  void _handleDecisionEvent(PlatformEvent event) {
    final payload = event.payload;
    final sessionId = payload['sessionId'] as String? ?? 'sess_conf_${DateTime.now().millisecondsSinceEpoch}';
    final recName = payload['recommendation'] as String? ?? 'normal';
    final confidence = (payload['emergencyConfidence'] as num?)?.toDouble() ?? (payload['confidence'] as num?)?.toDouble() ?? 0.0;
    final reasons = (payload['decisionReasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

    final recommendation = DecisionRecommendation.values.firstWhere(
      (r) => r.name == recName,
      orElse: () => DecisionRecommendation.normal,
    );

    startConfirmationFlow(
      sessionId: sessionId,
      recommendation: recommendation,
      confidence: confidence,
      decisionReasons: reasons,
    );
  }

  void startConfirmationFlow({
    required String sessionId,
    required DecisionRecommendation recommendation,
    required double confidence,
    List<String> decisionReasons = const [],
  }) {
    // Fix Issue 3 & 4: Don't restart countdown if already waiting, confirmed, or timer running
    if (state.status == ConfirmationStatus.waiting ||
        state.status == ConfirmationStatus.confirmed ||
        _countdownTimer != null) {
      appLogger.info('ConfirmationController: Countdown flow active or confirmed. Skipping duplicate trigger.');
      return;
    }

    _cancelTimer();

    final ConfirmationStrategy strategy = _selectStrategy(recommendation);

    final isInteractive = strategy.timeout > Duration.zero;

    state = state.copyWith(
      status: isInteractive ? ConfirmationStatus.waiting : ConfirmationStatus.idle,
      sessionLifecycleState: isInteractive ? SessionLifecycleState.waitingForConfirmation : SessionLifecycleState.created,
      activeStrategy: strategy,
      activeSessionId: sessionId,
      remainingSeconds: strategy.timeout.inSeconds,
      clearError: true,
    );

    if (isInteractive) {
      // 1. Emit ConfirmationStartedPlatformEvent
      final startEvent = ConfirmationStartedPlatformEvent(
        sessionId: sessionId,
        strategyName: strategy.name,
        timeoutSeconds: strategy.timeout.inSeconds,
        timestamp: DateTime.now(),
      );
      _publishEvent(startEvent);

      // 2. Start Countdown Timer
      _startTimer(sessionId, recommendation, confidence, decisionReasons);
    } else {
      // Immediate resolution for Normal / Monitor
      final request = ConfirmationRequest(
        sessionId: sessionId,
        recommendation: recommendation,
        emergencyConfidence: confidence,
        decisionReasons: decisionReasons,
        timestamp: DateTime.now(),
      );
      evaluateConfirmation(request);
    }
  }

  void _startTimer(
    String sessionId,
    DecisionRecommendation recommendation,
    double confidence,
    List<String> decisionReasons,
  ) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _cancelTimer();

        // Timeout Reached
        state = state.copyWith(
          status: ConfirmationStatus.timedOut,
          sessionLifecycleState: SessionLifecycleState.timedOut,
          remainingSeconds: 0,
        );

        final timeoutEvent = ConfirmationTimeoutPlatformEvent(
          sessionId: sessionId,
          timestamp: DateTime.now(),
        );
        _publishEvent(timeoutEvent);

        final request = ConfirmationRequest(
          sessionId: sessionId,
          recommendation: recommendation,
          emergencyConfidence: confidence,
          decisionReasons: decisionReasons,
          wasTimedOut: true,
          timestamp: DateTime.now(),
        );

        evaluateConfirmation(request);
      }
    });
  }

  void confirmUserResponse({
    required ConfirmationMethod method,
    required String text,
  }) {
    _cancelTimer();

    final sessionId = state.activeSessionId ?? 'sess_conf_${DateTime.now().millisecondsSinceEpoch}';

    final recvEvent = ConfirmationReceivedPlatformEvent(
      sessionId: sessionId,
      method: method.name,
      responseText: text,
      timestamp: DateTime.now(),
    );
    _publishEvent(recvEvent);

    final request = ConfirmationRequest(
      sessionId: sessionId,
      recommendation: DecisionRecommendation.requestConfirmation,
      emergencyConfidence: 0.90,
      userResponse: text,
      responseMethod: method,
      timestamp: DateTime.now(),
    );

    evaluateConfirmation(request);
  }

  void cancelConfirmation() {
    _cancelTimer();

    final sessionId = state.activeSessionId ?? 'sess_conf_${DateTime.now().millisecondsSinceEpoch}';

    final recvEvent = ConfirmationReceivedPlatformEvent(
      sessionId: sessionId,
      method: ConfirmationMethod.button.name,
      responseText: 'CANCEL SOS',
      timestamp: DateTime.now(),
    );
    _publishEvent(recvEvent);

    final request = ConfirmationRequest(
      sessionId: sessionId,
      recommendation: DecisionRecommendation.requestConfirmation,
      emergencyConfidence: 0.90,
      userResponse: 'cancel',
      responseMethod: ConfirmationMethod.button,
      timestamp: DateTime.now(),
    );

    evaluateConfirmation(request);
  }

  void interruptConfirmation({InterruptionReason reason = InterruptionReason.unknown}) {
    _cancelTimer();

    final sessionId = state.activeSessionId ?? 'sess_conf_${DateTime.now().millisecondsSinceEpoch}';

    state = state.copyWith(
      status: ConfirmationStatus.interrupted,
      sessionLifecycleState: SessionLifecycleState.interrupted,
      interruptionReason: reason,
    );

    final request = ConfirmationRequest(
      sessionId: sessionId,
      recommendation: DecisionRecommendation.requestConfirmation,
      emergencyConfidence: 0.90,
      wasInterrupted: true,
      interruptionReason: reason,
      timestamp: DateTime.now(),
    );

    evaluateConfirmation(request);
  }

  Future<void> evaluateConfirmation(ConfirmationRequest request) async {
    try {
      final result = await _service.processRequest(request);

      ConfirmationStatus nextStatus = ConfirmationStatus.completed;
      final SessionLifecycleState nextLifecycle = result.sessionLifecycleState;

      if (result.confirmationOutcome == ConfirmationOutcome.confirmed) {
        nextStatus = ConfirmationStatus.confirmed;
      } else if (result.confirmationOutcome == ConfirmationOutcome.cancelled) {
        nextStatus = ConfirmationStatus.cancelled;
      } else if (result.confirmationOutcome == ConfirmationOutcome.timedOut) {
        nextStatus = ConfirmationStatus.timedOut;
      } else if (result.confirmationOutcome == ConfirmationOutcome.interrupted) {
        nextStatus = ConfirmationStatus.interrupted;
      }

      // Emit ConfirmationCompletedPlatformEvent
      final compEvent = ConfirmationCompletedPlatformEvent(
        result: result,
        timestamp: DateTime.now(),
      );
      _publishEvent(compEvent);

      state = state.copyWith(
        status: nextStatus,
        sessionLifecycleState: nextLifecycle,
        lastResult: result,
        interruptionReason: result.interruptionReason,
        telemetry: _service.telemetry,
      );

      appLogger.info(
        'ConfirmationController: 🖐️ Confirmation Evaluated: Outcome=${result.confirmationOutcome.name.toUpperCase()}, '
        'Lifecycle=${result.sessionLifecycleState.name.toUpperCase()}, Method=${result.confirmationMethod.name.toUpperCase()} (${result.responseTimeMs}ms)',
      );
    } on ConfirmationError catch (e) {
      _handleError(e.category, e.message);
    } catch (e) {
      _handleError(ConfirmationErrorCategory.processingFailure, e.toString());
    }
  }

  ConfirmationStrategy _selectStrategy(DecisionRecommendation rec) {
    switch (rec) {
      case DecisionRecommendation.normal:
        return const NormalStrategy();
      case DecisionRecommendation.monitor:
        return const MonitorStrategy();
      case DecisionRecommendation.requestConfirmation:
        return const RequestConfirmationStrategy();
      case DecisionRecommendation.highRisk:
        return const HighRiskStrategy();
    }
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _handleError(ConfirmationErrorCategory category, String message) {
    state = state.copyWith(
      status: ConfirmationStatus.failed,
      errorCategory: category,
      errorMessage: message,
      telemetry: _service.telemetry,
    );

    appLogger.error('ConfirmationController: Confirmation Error [${category.name}]: $message');
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('ConfirmationController: Could not publish Confirmation event to EmergencyEventBus: $e');
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    _busSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
