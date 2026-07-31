/// emergency_session_controller.dart
///
/// Master presentation StateNotifier controller managing Phase 8 Emergency Session Activation,
/// action execution orchestration, execution timeline logging, and event publishing over EmergencyEventBus.

library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_result.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_method.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/session_lifecycle_state.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/sos/presentation/providers/emergency_service_provider.dart';

import '../../domain/entities/emergency_session_state.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/entities/emergency_session_result.dart';

import '../../domain/entities/emergency_execution_error.dart';
import '../../domain/entities/emergency_session_events.dart';
import '../../data/services/emergency_session_service.dart';

class EmergencySessionController extends StateNotifier<EmergencySessionState> {
  EmergencySessionController(
    this._ref, {
    required EmergencySessionService service,
  })  : _service = service,
        super(const EmergencySessionState()) {
    _initEventBusListener();
  }

  final Ref _ref;
  final EmergencySessionService _service;
  StreamSubscription<PlatformEvent>? _busSubscription;
  final List<String> _executionTimeline = [];

  void _initEventBusListener() {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      _busSubscription = bus.events.listen((event) {
        if (event.eventName == 'ConfirmationCompleted') {
          _handleConfirmationCompletedEvent(event);
        }
      });
    } catch (e) {
      appLogger.warning('EmergencySessionController: Could not subscribe to EmergencyEventBus: $e');
    }
  }

  void _handleConfirmationCompletedEvent(PlatformEvent event) {
    final payload = event.payload;
    final sessionId = payload['sessionId'] as String? ?? 'sess_act_${DateTime.now().millisecondsSinceEpoch}';
    final outcomeName = payload['confirmationOutcome'] as String? ?? 'confirmed';
    final methodName = payload['confirmationMethod'] as String? ?? 'button';
    final responseText = payload['userResponse'] as String?;

    final outcome = ConfirmationOutcome.values.firstWhere(
      (o) => o.name == outcomeName,
      orElse: () => ConfirmationOutcome.confirmed,
    );

    final method = ConfirmationMethod.values.firstWhere(
      (m) => m.name == methodName,
      orElse: () => ConfirmationMethod.button,
    );

    final confResult = ConfirmationResult(
      sessionId: sessionId,
      confirmationOutcome: outcome,
      sessionLifecycleState: SessionLifecycleState.confirmed,
      confirmationMethod: method,
      responseTimeMs: (payload['responseTimeMs'] as num?)?.toInt() ?? 100,
      userResponse: responseText,
      timestamp: DateTime.now(),
    );

    if (outcome == ConfirmationOutcome.confirmed || outcome == ConfirmationOutcome.timedOut) {
      // Read the actual confidence from the event payload; fall back to 0.85 if missing.
      final confidence = (payload['emergencyConfidence'] as num?)?.toDouble() ?? 0.85;
      final reasons = (payload['decisionReasons'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          ['User confirmed emergency or countdown timed out.'];
      startSession(
        sessionId: sessionId,
        confirmationResult: confResult,
        emergencyConfidence: confidence,
        confirmationOutcome: outcome,
        decisionReasons: reasons,
      );
    } else {
      _addTimelineEntry('Session bypassed (Outcome: ${outcome.name.toUpperCase()})');
      state = state.copyWith(
        status: EmergencySessionStatus.cancelled,
        activeSessionId: sessionId,
        executionTimeline: List.from(_executionTimeline),
      );
    }
  }

  Future<void> startSession({
    required String sessionId,
    required ConfirmationResult confirmationResult,
    required double emergencyConfidence,
    required ConfirmationOutcome confirmationOutcome,
    List<String> decisionReasons = const [],
  }) async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    _addTimelineEntry('$timeStr — 🚀 Emergency Session Activated: $sessionId');

    state = state.copyWith(
      status: EmergencySessionStatus.executing,
      activeSessionId: sessionId,
      executionTimeline: List.from(_executionTimeline),
      clearError: true,
    );

    // 1. Emit EmergencySessionStartedPlatformEvent
    final startEvent = EmergencySessionStartedPlatformEvent(
      sessionId: sessionId,
      triggerOutcome: confirmationOutcome.name,
      timestamp: now,
    );
    _publishEvent(startEvent);

    // Gather real emergency contacts from the SOS Circle
    final sosCircle = _ref.read(sosCircleStateProvider);
    final contactPhones = sosCircle.contacts
        .where((c) => c.isEnabled && c.primaryPhone.isNotEmpty)
        .map((c) => c.primaryPhone)
        .toList();

    // Gather emergency number from the selected service
    final selectedService = _ref.read(emergencyServiceProvider).selectedService;
    final emergencyNumber = selectedService?.emergencyNumber ?? '112';

    // Build a mutable profile map so LocationSharingAction can write GPS into it
    final profile = <String, dynamic>{
      'emergencyNumber': emergencyNumber,
      'sessionId': sessionId,
      'triggerOutcome': confirmationOutcome.name,
      'confidence': emergencyConfidence,
    };

    // Optionally include health passport summary
    try {
      final passportState = _ref.read(healthPassportControllerProvider);
      final passport = passportState.passport;
      if (passport != null) {
        profile['bloodType'] = passport.profile.bloodGroup;
        profile['allergies'] = passport.profile.allergies;
        profile['conditions'] = passport.profile.chronicConditions;
      }
    } catch (_) {}

    final request = EmergencySessionRequest(
      sessionId: sessionId,
      confirmationResult: confirmationResult,
      emergencyConfidence: emergencyConfidence,
      confirmationOutcome: confirmationOutcome,
      decisionReasons: decisionReasons,
      emergencyProfile: profile,
      emergencyContacts: contactPhones,
      timestamp: now,
    );

    try {
      // 2. Execute Emergency Action Pipeline
      final result = await _service.processRequest(request);

      for (final actRes in result.actionResults) {
        final actTimeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
        _addTimelineEntry('$actTimeStr — ${actRes.success ? "✅" : "❌"} ${actRes.actionName}: ${actRes.message}');

        final actCompEvent = EmergencyActionCompletedPlatformEvent(
          sessionId: sessionId,
          actionId: actRes.actionId,
          success: actRes.success,
          executionTimeMs: actRes.executionTimeMs,
          timestamp: DateTime.now(),
        );
        _publishEvent(actCompEvent);
      }

      // 3. Emit Acknowledgement Platform Event
      final ackEvent = EmergencyAcknowledgementPlatformEvent(
        sessionId: sessionId,
        status: result.acknowledgementStatus.name,
        timestamp: DateTime.now(),
      );
      _publishEvent(ackEvent);

      // 4. Emit EmergencySessionCompletedPlatformEvent
      final compEvent = EmergencySessionCompletedPlatformEvent(
        result: result,
        timestamp: DateTime.now(),
      );
      _publishEvent(compEvent);

      final compTimeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
      _addTimelineEntry('$compTimeStr — 🏁 Session Completed Successfully (${result.executionDurationMs}ms)');

      state = state.copyWith(
        status: result.sessionState == SessionState.completed ? EmergencySessionStatus.completed : EmergencySessionStatus.failed,
        lastResult: result,
        telemetry: _service.telemetry,
        executionTimeline: List.from(_executionTimeline),
      );

      appLogger.info(
        'EmergencySessionController: 🚨 Emergency Session Completed: State=${result.sessionState.name.toUpperCase()}, '
        'Executed=${result.executedActions.length}, Successful=${result.successfulActions.length}, Duration=${result.executionDurationMs}ms',
      );
    } on EmergencyExecutionError catch (e) {
      _handleError(e.category, e.message);
    } catch (e) {
      _handleError(EmergencyExecutionErrorCategory.executionFailure, e.toString());
    }
  }

  void cancelSession() {
    _addTimelineEntry('Session manually cancelled by user.');
    state = state.copyWith(
      status: EmergencySessionStatus.cancelled,
      executionTimeline: List.from(_executionTimeline),
    );
  }

  void _addTimelineEntry(String entry) {
    _executionTimeline.add(entry);
    if (_executionTimeline.length > 25) {
      _executionTimeline.removeAt(0);
    }
  }

  void _handleError(EmergencyExecutionErrorCategory category, String message) {
    state = state.copyWith(
      status: EmergencySessionStatus.failed,
      errorCategory: category,
      errorMessage: message,
      telemetry: _service.telemetry,
      executionTimeline: List.from(_executionTimeline),
    );

    appLogger.error('EmergencySessionController: Execution Error [${category.name}]: $message');
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('EmergencySessionController: Could not publish Session event to EmergencyEventBus: $e');
    }
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
