/// mock_emergency_response_engine.dart
///
/// Simulates the full emergency response loop:
///   generate summary → notify responders → wait for acknowledgement → escalate
///
/// Does NOT contact real services. Every action is simulated with delays
/// and probabilistic outcomes so the UI shows realistic behaviour.
///
/// Acknowledgement behaviour:
///   - Each responder has a [acknowledgementProbability] chance (default 70%)
///     of responding within [mockAcknowledgementDelayMs] (default 4000ms).
///   - Emergency Services always acknowledge (ensures the demo completes).

library;

import 'dart:async';
import 'dart:math';

import '../../domain/enums/responder_type.dart';
import '../../domain/services/emergency_response_engine.dart';
import '../../domain/services/notification_service.dart';
import '../../../sos/domain/entities/emergency_event.dart';

/// Mock implementation of [EmergencyResponseEngine].
class MockEmergencyResponseEngine implements EmergencyResponseEngine {
  MockEmergencyResponseEngine({
    required NotificationService notificationService,
    this.acknowledgementProbability = 0.70,
    this.mockAcknowledgementDelayMs = 4000,
  }) : _notificationService = notificationService;

  final NotificationService _notificationService;

  /// Probability (0–1) that a responder acknowledges the emergency.
  final double acknowledgementProbability;

  /// Milliseconds the mock waits before deciding on acknowledgement.
  /// Production uses [Responder.acknowledgementTimeoutSeconds].
  final int mockAcknowledgementDelayMs;

  final _random = Random();
  StreamController<ResponseEngineUpdate>? _controller;
  bool _cancelled = false;

  // ── EmergencyResponseEngine ───────────────────────────────────────────────

  @override
  Stream<ResponseEngineUpdate> execute({
    required EmergencyEvent event,
    required EmergencyResponsePlan plan,
  }) {
    _cancelled = false;
    _controller = StreamController<ResponseEngineUpdate>();
    _run(event, plan);
    return _controller!.stream;
  }

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _emit(ResponseEngineUpdate.cancelled());
    _cancelled = true;
    await _controller?.close();
    _controller = null;
  }

  // ── Internal Execution ────────────────────────────────────────────────────

  Future<void> _run(EmergencyEvent event, EmergencyResponsePlan plan) async {
    try {
      // Step 1: Signal engine start.
      _emit(ResponseEngineUpdate.started());
      await _delay(300);
      if (_cancelled) return;

      // Step 2: Generate the emergency summary.
      final summary = _generateSummary(event);
      _emit(ResponseEngineUpdate.generatingSummary(summary));
      await _delay(800);
      if (_cancelled) return;

      // Step 3: Notify responders in priority order.
      bool emergencyAcknowledged = false;

      for (var i = 0; i < plan.responders.length; i++) {
        if (_cancelled) break;
        final responder = plan.responders[i];

        // Send all configured notification methods for this responder.
        for (final method in responder.notificationMethods) {
          if (_cancelled) break;

          _emit(ResponseEngineUpdate.notifying(responder, method));
          await _delay(200);

          final result = await _notificationService.send(
            responder: responder,
            method: method,
            message: summary,
          );

          _emit(ResponseEngineUpdate.notified(
            responder,
            method,
            success: result.success,
          ));

          if (_cancelled) break;
          await _delay(400);
        }

        if (_cancelled) break;

        // Wait for acknowledgement (simulated).
        await _delay(mockAcknowledgementDelayMs);
        if (_cancelled) break;

        // Emergency Services always acknowledges to ensure demo completes.
        final willAcknowledge =
            responder.type == ResponderType.emergencyService ||
                _random.nextDouble() < acknowledgementProbability;

        if (willAcknowledge) {
          _emit(ResponseEngineUpdate.acknowledged(responder));
          emergencyAcknowledged = true;
          break; // Stop escalation — someone responded.
        } else {
          _emit(ResponseEngineUpdate.timedOut(responder));
          await _delay(500);

          // Escalate to next if available.
          final next = i + 1 < plan.responders.length
              ? plan.responders[i + 1]
              : null;
          _emit(ResponseEngineUpdate.escalating(responder, next));
          await _delay(600);
        }
      }

      if (!_cancelled) {
        _emit(
          ResponseEngineUpdate.completed(
            acknowledged: emergencyAcknowledged,
          ),
        );
      }
    } catch (e) {
      if (!_cancelled) {
        _emit(ResponseEngineUpdate.failed('Engine error: $e'));
      }
    } finally {
      await _controller?.close();
      _controller = null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _emit(ResponseEngineUpdate update) {
    if (!_cancelled) _controller?.add(update);
  }

  Future<void> _delay(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  String _generateSummary(EmergencyEvent event) {
    final t = event.activatedAt ?? event.createdAt;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final dd = '${t.day}/${t.month}/${t.year}';
    final refId = event.id.substring(0, 8).toUpperCase();
    return '🆘 EMERGENCY ALERT — Elly SOS activated at $hh:$mm on $dd. '
        'Trigger: ${event.type.name.toUpperCase()}. '
        'Reference: #$refId. '
        'The user may be in danger. Please respond immediately.';
  }
}
