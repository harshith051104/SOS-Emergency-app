/// escalation_engine_test.dart
///
/// Unit tests for EscalationEngine fallback execution.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_request.dart';
import 'package:elly/features/emergency/communication/domain/entities/delivery_status.dart';
import 'package:elly/features/emergency/communication/domain/entities/escalation_policy.dart';
import 'package:elly/features/emergency/communication/data/transports/internet_transport.dart';
import 'package:elly/features/emergency/communication/data/transports/sms_transport.dart';
import 'package:elly/features/emergency/communication/data/services/escalation_engine.dart';

void main() {
  group('EscalationEngine', () {
    final escalationEngine = EscalationEngine();

    test('should escalate from Internet to SMS when Internet fails', () async {
      final request = CommunicationRequest(
        requestId: 'req_esc_1',
        sessionId: 'sess_1',
        payloadJson: '{}',
        priority: 'critical',
        guaranteeLevel: 'mustDeliver',
        recipientTargets: const ['+18005550199'],
        createdAt: DateTime.now(),
      );

      final result = await escalationEngine.executeEscalation(
        request: request,
        policy: EscalationPolicy.defaultEmergency(),
        transportMap: {
          'internet': InternetTransport(forceFailure: true),
          'sms': SmsTransport(),
        },
      );

      expect(result.transportUsed, equals('sms'));
      expect(result.state, equals(DeliveryState.delivered));
    });
  });
}
