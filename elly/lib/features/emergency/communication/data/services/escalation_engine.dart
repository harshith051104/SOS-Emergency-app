/// escalation_engine.dart
///
/// Multi-step transport escalation engine handling automatic fallback policies.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/communication_event.dart';
import '../../domain/entities/delivery_status.dart';

import '../../domain/entities/escalation_policy.dart';
import '../transports/base_transport.dart';
import '../transports/internet_transport.dart';
import '../transports/sms_transport.dart';
import '../transports/phone_transport.dart';
import 'communication_event_bus.dart';
import 'transport_health_monitor.dart';

class EscalationEngine {
  EscalationEngine({
    CommunicationEventBus? eventBus,
    TransportHealthMonitor? healthMonitor,
  })  : _eventBus = eventBus ?? CommunicationEventBus(),
        _healthMonitor = healthMonitor ?? TransportHealthMonitor();

  final CommunicationEventBus _eventBus;
  final TransportHealthMonitor _healthMonitor;

  Future<DeliveryStatus> executeEscalation({
    required CommunicationRequest request,
    required EscalationPolicy policy,
    Map<String, BaseTransport>? transportMap,
  }) async {
    final transports = transportMap ?? {
      'internet': InternetTransport(),
      'sms': SmsTransport(),
      'phone': PhoneTransport(),
    };

    String currentTransport = policy.primaryTransport;
    DeliveryStatus? lastStatus;

    for (int i = 0; i < policy.fallbackSequence.length; i++) {
      currentTransport = policy.fallbackSequence[i];

      if (i > 0) {
        final prevTransport = policy.fallbackSequence[i - 1];
        _eventBus.publish(EscalationStartedEvent(
          requestId: request.requestId,
          fromTransport: prevTransport,
          toTransport: currentTransport,
        ));
      }

      final transportAdaptor = transports[currentTransport];
      if (transportAdaptor == null || !transportAdaptor.isAvailable) {
        continue;
      }

      int attempts = 0;
      while (attempts < policy.maxRetriesPerTransport) {
        attempts++;
        try {
          final result = await transportAdaptor.send(request);
          lastStatus = result;

          if (result.state == DeliveryState.delivered || result.state == DeliveryState.acknowledged) {
            _healthMonitor.recordSuccess(currentTransport);
            _eventBus.publish(EscalationCompletedEvent(
              requestId: request.requestId,
              finalTransport: currentTransport,
            ));
            return result;
          } else {
            _healthMonitor.recordFailure(currentTransport);
          }
        } catch (e) {
          _healthMonitor.recordFailure(currentTransport);
        }
      }

      _eventBus.publish(TransportFailedEvent(
        requestId: request.requestId,
        transport: currentTransport,
        reason: lastStatus?.errorReason ?? 'Max retries exceeded',
      ));
    }

    return lastStatus ?? DeliveryStatus(
      requestId: request.requestId,
      transportUsed: currentTransport,
      state: DeliveryState.failed,
      attempts: policy.maxRetriesPerTransport,
      roundTripTimeMs: 0,
      errorReason: 'All fallback transports in escalation sequence failed',
    );
  }
}
