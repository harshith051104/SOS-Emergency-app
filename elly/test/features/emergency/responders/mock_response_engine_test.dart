/// mock_response_engine_test.dart
///
/// Unit tests for [MockEmergencyResponseEngine].
/// Verifies event order, acknowledgement, and escalation logic.

library;

import 'package:elly/features/emergency/responders/data/services/mock_emergency_response_engine.dart';
import 'package:elly/features/emergency/responders/data/services/mock_notification_service.dart';
import 'package:elly/features/emergency/responders/domain/entities/emergency_response_plan.dart';
import 'package:elly/features/emergency/responders/domain/entities/responder.dart';
import 'package:elly/features/emergency/responders/domain/enums/notification_method.dart';
import 'package:elly/features/emergency/responders/domain/enums/responder_type.dart';
import 'package:elly/features/emergency/responders/domain/enums/response_update_type.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_event.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_type.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

EmergencyEvent _event() => EmergencyEvent(
      id: 'test-event-id',
      type: EmergencyType.manual,
      status: EmergencyStatus.active,
      createdAt: DateTime(2025, 1, 1, 12),
      activatedAt: DateTime(2025, 1, 1, 12, 0, 5),
    );

Responder _responder({
  String id = 'r1',
  String name = 'Test Responder',
  ResponderType type = ResponderType.family,
  int priority = 0,
}) =>
    Responder(
      id: id,
      name: name,
      type: type,
      notificationMethods: const [NotificationMethod.sms],
      phoneNumber: '+1 555 000 0001',
      priority: priority,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockEmergencyResponseEngine engine;

  setUp(() {
    engine = MockEmergencyResponseEngine(
      notificationService: MockNotificationService(
        successRate: 1.0, // always succeed in tests
        minDelayMs: 1,
        maxDelayMs: 2,
      ),
      // 100% acknowledgement probability so engine always completes.
      acknowledgementProbability: 1.0,
      mockAcknowledgementDelayMs: 10, // fast for tests
    );
  });

  group('MockEmergencyResponseEngine', () {
    test('emits started and generatingSummary as first two events', () async {
      final plan = EmergencyResponsePlan(responders: [_responder()]);
      final updates = await engine
          .execute(event: _event(), plan: plan)
          .toList();

      expect(updates.first.type, ResponseUpdateType.started);
      expect(updates[1].type, ResponseUpdateType.generatingSummary);
      expect(updates[1].message, isNotEmpty);
    });

    test('emits notifying → notified for each method', () async {
      final plan = EmergencyResponsePlan(responders: [_responder()]);
      final types = await engine
          .execute(event: _event(), plan: plan)
          .map((u) => u.type)
          .toList();

      expect(types, contains(ResponseUpdateType.notifying));
      expect(types, contains(ResponseUpdateType.notified));
    });

    test('emits acknowledged when responder responds', () async {
      final plan = EmergencyResponsePlan(responders: [_responder()]);
      final types = await engine
          .execute(event: _event(), plan: plan)
          .map((u) => u.type)
          .toList();

      expect(types, contains(ResponseUpdateType.acknowledged));
    });

    test('last event is completed', () async {
      final plan = EmergencyResponsePlan(responders: [_responder()]);
      final updates = await engine
          .execute(event: _event(), plan: plan)
          .toList();

      expect(updates.last.type, ResponseUpdateType.completed);
    });

    test('escalates when first responder does not acknowledge', () async {
      final noAckEngine = MockEmergencyResponseEngine(
        notificationService: MockNotificationService(
          successRate: 1.0,
          minDelayMs: 1,
          maxDelayMs: 2,
        ),
        // 0% → never acknowledges (except emergencyService).
        acknowledgementProbability: 0.0,
        mockAcknowledgementDelayMs: 10,
      );

      final r1 = _responder();
      final r2 = _responder(
        id: 'r2',
        name: 'Emergency Services',
        type: ResponderType.emergencyService,
        priority: 1,
      );

      final plan = EmergencyResponsePlan(responders: [r1, r2]);
      final updates = await noAckEngine
          .execute(event: _event(), plan: plan)
          .toList();

      final types = updates.map((u) => u.type).toList();

      // First responder should time out.
      expect(types, contains(ResponseUpdateType.timedOut));
      // Engine should escalate.
      expect(types, contains(ResponseUpdateType.escalating));
      // Emergency Services always acknowledges.
      expect(types, contains(ResponseUpdateType.acknowledged));
      // Should complete.
      expect(types.last, ResponseUpdateType.completed);
    });

    test('emitting cancelled on cancel() before completion', () async {
      final neverAckEngine = MockEmergencyResponseEngine(
        notificationService: MockNotificationService(
          successRate: 1.0,
          minDelayMs: 500, // slow so we can cancel
          maxDelayMs: 600,
        ),
        acknowledgementProbability: 0.0,
        mockAcknowledgementDelayMs: 10000, // very long — cancel before this
      );

      final plan = EmergencyResponsePlan(responders: [_responder()]);
      final updates = <ResponseUpdateType>[];

      final stream = neverAckEngine.execute(event: _event(), plan: plan);
      final subscription = stream.listen((u) => updates.add(u.type));

      // Wait briefly then cancel.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await neverAckEngine.cancel();
      await subscription.cancel();

      expect(updates, contains(ResponseUpdateType.cancelled));
    });

    test('emergency summary contains event type and reference', () async {
      final plan = EmergencyResponsePlan(responders: [_responder()]);
      final updates = await engine
          .execute(event: _event(), plan: plan)
          .toList();

      final summaryUpdate = updates.firstWhere(
        (u) => u.type == ResponseUpdateType.generatingSummary,
      );

      expect(summaryUpdate.message, contains('MANUAL'));
      expect(summaryUpdate.message, contains('TEST-EV')); // first 8 of id
    });
  });
}
