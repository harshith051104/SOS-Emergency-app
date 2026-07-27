/// communication_manager_service.dart
///
/// Primary Gateway orchestrating transport scoring, dispatch execution, delivery tracking, and escalation.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/communication_state.dart';
import '../../domain/entities/communication_event.dart';
import '../../domain/entities/delivery_status.dart';

import '../../domain/entities/escalation_policy.dart';
import '../transports/base_transport.dart';
import '../transports/internet_transport.dart';
import '../transports/sms_transport.dart';
import '../transports/phone_transport.dart';
import '../transports/email_transport.dart';
import '../transports/bluetooth_relay_transport.dart';
import '../transports/mesh_transport.dart';
import 'transport_selection_engine.dart';
import 'transport_health_monitor.dart';
import 'delivery_tracker_service.dart';
import 'escalation_engine.dart';
import 'communication_state_machine.dart';
import 'communication_event_bus.dart';

class CommunicationManagerService {
  CommunicationManagerService({
    TransportSelectionEngine? selectionEngine,
    TransportHealthMonitor? healthMonitor,
    DeliveryTrackerService? trackerService,
    EscalationEngine? escalationEngine,
    CommunicationStateMachine? stateMachine,
    CommunicationEventBus? eventBus,
    Map<String, BaseTransport>? transports,
  })  : _selectionEngine = selectionEngine ?? TransportSelectionEngine(),
        _healthMonitor = healthMonitor ?? TransportHealthMonitor(),
        _trackerService = trackerService ?? DeliveryTrackerService(),
        _stateMachine = stateMachine ?? CommunicationStateMachine(),
        _eventBus = eventBus ?? CommunicationEventBus() {
    _escalationEngine = escalationEngine ?? EscalationEngine(eventBus: _eventBus, healthMonitor: _healthMonitor);
    _transports = transports ?? {
      'internet': InternetTransport(),
      'sms': SmsTransport(),
      'phone': PhoneTransport(),
      'email': EmailTransport(),
      'bluetooth': BluetoothRelayTransport(),
      'mesh': MeshTransport(),
    };
  }

  final TransportSelectionEngine _selectionEngine;
  final TransportHealthMonitor _healthMonitor;
  final DeliveryTrackerService _trackerService;
  late final EscalationEngine _escalationEngine;
  final CommunicationStateMachine _stateMachine;
  final CommunicationEventBus _eventBus;
  late final Map<String, BaseTransport> _transports;

  TransportSelectionEngine get selectionEngine => _selectionEngine;
  TransportHealthMonitor get healthMonitor => _healthMonitor;
  DeliveryTrackerService get trackerService => _trackerService;
  CommunicationStateMachine get stateMachine => _stateMachine;
  CommunicationEventBus get eventBus => _eventBus;

  Future<bool> sendCommunication(CommunicationRequest request) async {
    _stateMachine.transitionTo(CommunicationStatus.preparing, requestId: request.requestId);

    // 1. Transport Selection
    _stateMachine.transitionTo(CommunicationStatus.selectingTransport, requestId: request.requestId);
    final bestTransportScore = _selectionEngine.selectBestTransport();

    _eventBus.publish(TransportSelectedEvent(
      requestId: request.requestId,
      selectedTransport: bestTransportScore.transportType,
      score: bestTransportScore.score.toDouble(),
    ));


    // 2. Dispatch Execution
    _stateMachine.transitionTo(
      CommunicationStatus.sending,
      requestId: request.requestId,
      transport: bestTransportScore.transportType,
    );
    _eventBus.publish(MessageSendingEvent(requestId: request.requestId, transport: bestTransportScore.transportType));

    final transportAdaptor = _transports[bestTransportScore.transportType];

    DeliveryStatus status;
    if (transportAdaptor != null && transportAdaptor.isAvailable) {
      status = await transportAdaptor.send(request);
    } else {
      status = DeliveryStatus(
        requestId: request.requestId,
        transportUsed: bestTransportScore.transportType,
        state: DeliveryState.failed,
        attempts: 1,
        roundTripTimeMs: 0,
        errorReason: 'Selected transport unavailable',
      );
    }

    // 3. Escalation Fallback if Failed
    if (status.state == DeliveryState.failed) {
      _stateMachine.transitionTo(
        CommunicationStatus.escalating,
        requestId: request.requestId,
        transport: bestTransportScore.transportType,
      );

      status = await _escalationEngine.executeEscalation(
        request: request,
        policy: EscalationPolicy.defaultEmergency(),
        transportMap: _transports,
      );
    }

    // 4. Record Tracking & Update State
    _trackerService.recordStatus(status);

    if (status.state == DeliveryState.delivered || status.state == DeliveryState.acknowledged) {
      _stateMachine.transitionTo(
        CommunicationStatus.completed,
        requestId: request.requestId,
        transport: status.transportUsed,
      );
      _eventBus.publish(MessageDeliveredEvent(status));
      return true;
    } else {
      _stateMachine.transitionTo(
        CommunicationStatus.failed,
        requestId: request.requestId,
        error: status.errorReason,
      );
      return false;
    }
  }

  void injectTransportOverride(String name, BaseTransport transport) {
    _transports[name] = transport;
  }
}
