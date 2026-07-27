/// offline_survival_engine.dart
///
/// Primary coordinator managing offline mode activation, queue routing, and recovery sync.

library;

import 'dart:async';
import '../../domain/entities/connectivity_state.dart';
import '../../domain/entities/emergency_queue_item.dart';
import '../../domain/entities/queue_priority.dart';
import '../../domain/entities/delivery_guarantee.dart';
import '../../domain/entities/transport_config.dart';
import '../../domain/entities/reliability_state.dart';
import '../../domain/entities/reliability_event.dart';
import '../monitors/connectivity_monitor.dart';
import '../monitors/network_quality_monitor.dart';
import '../monitors/airplane_mode_monitor.dart';
import '../monitors/predictive_disconnect_monitor.dart';
import 'emergency_queue_manager.dart';
import 'synchronization_engine.dart';
import 'disconnect_protection_service.dart';
import 'reliability_state_machine.dart';
import 'reliability_event_bus.dart';

class OfflineSurvivalEngine {
  OfflineSurvivalEngine({
    ConnectivityMonitor? connectivityMonitor,
    NetworkQualityMonitor? qualityMonitor,
    AirplaneModeMonitor? airplaneModeMonitor,
    PredictiveDisconnectMonitor? predictiveMonitor,
    EmergencyQueueManager? queueManager,
    SynchronizationEngine? syncEngine,
    DisconnectProtectionService? disconnectService,
    ReliabilityStateMachine? stateMachine,
    ReliabilityEventBus? eventBus,
  })  : _connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor(),
        _qualityMonitor = qualityMonitor ?? NetworkQualityMonitor(),
        _airplaneModeMonitor = airplaneModeMonitor ?? AirplaneModeMonitor(),
        _predictiveMonitor = predictiveMonitor ?? PredictiveDisconnectMonitor(),
        _queueManager = queueManager ?? EmergencyQueueManager(),
        _disconnectService = disconnectService ?? DisconnectProtectionService(),
        _stateMachine = stateMachine ?? ReliabilityStateMachine(),
        _eventBus = eventBus ?? ReliabilityEventBus() {
    _syncEngine = syncEngine ?? SynchronizationEngine(queueManager: _queueManager);
  }

  final ConnectivityMonitor _connectivityMonitor;
  final NetworkQualityMonitor _qualityMonitor;
  final AirplaneModeMonitor _airplaneModeMonitor;
  final PredictiveDisconnectMonitor _predictiveMonitor;
  final EmergencyQueueManager _queueManager;
  late final SynchronizationEngine _syncEngine;
  final DisconnectProtectionService _disconnectService;
  final ReliabilityStateMachine _stateMachine;
  final ReliabilityEventBus _eventBus;

  AirplaneModeMonitor get airplaneModeMonitor => _airplaneModeMonitor;


  StreamSubscription? _connectivitySubscription;
  String? _activeSessionId;
  DateTime? _offlineStartTime;
  int _sequenceCounter = 0;

  ReliabilityStateMachine get stateMachine => _stateMachine;
  ReliabilityEventBus get eventBus => _eventBus;
  SynchronizationEngine get syncEngine => _syncEngine;
  ConnectivityMonitor get connectivityMonitor => _connectivityMonitor;
  NetworkQualityMonitor get qualityMonitor => _qualityMonitor;
  EmergencyQueueManager get queueManager => _queueManager;

  Future<void> startEngine({required String sessionId}) async {
    _activeSessionId = sessionId;
    _sequenceCounter = 0;
    _stateMachine.transitionTo(ReliabilityStatus.preparing, sessionId: sessionId);

    _connectivityMonitor.startMonitoring();
    _qualityMonitor.startProbing();

    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivityMonitor.connectivityStream.listen((state) {
      _handleConnectivityStateChange(state);
    });

    final initial = await _connectivityMonitor.checkConnectivityNow();
    if (initial.isInternetAvailable) {
      _stateMachine.transitionTo(ReliabilityStatus.onlineMonitoring, sessionId: sessionId);
    } else {
      _offlineStartTime = DateTime.now();
      _stateMachine.transitionTo(ReliabilityStatus.offlineMonitoring, sessionId: sessionId);
      _eventBus.publish(InternetLostEvent(initial));
    }
  }

  Future<void> enqueuePacket({
    required String payloadJson,
    String itemType = 'packet',
    QueuePriority priority = QueuePriority.critical,
    DeliveryGuaranteeLevel guaranteeLevel = DeliveryGuaranteeLevel.mustDeliver,
  }) async {
    if (_activeSessionId == null) return;
    _sequenceCounter++;

    final item = EmergencyQueueItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_$_sequenceCounter',
      sessionId: _activeSessionId!,
      sequenceNumber: _sequenceCounter,
      itemType: itemType,
      payloadJson: payloadJson,
      idempotencyKey: '${_activeSessionId}_$_sequenceCounter',
      priority: priority,
      guaranteeLevel: guaranteeLevel,
      transportConfig: TransportConfig.defaultHttpWithSmsFallback(),
      attempts: 0,
      createdAt: DateTime.now(),
      status: QueueItemStatus.pending,
      checksum: '',
    );

    await _queueManager.enqueue(item);

    if (_connectivityMonitor.currentState.isInternetAvailable) {
      // Auto sync immediately if online
      await _syncEngine.synchronizeSession(sessionId: _activeSessionId!);
    } else {
      _stateMachine.transitionTo(ReliabilityStatus.queueing, sessionId: _activeSessionId);
    }
  }

  void checkPredictiveDisconnect({required int batteryPercent, required int networkFailures}) {
    final warning = _predictiveMonitor.evaluateWarning(
      batteryPercent: batteryPercent,
      networkQuality: _qualityMonitor.currentQuality,
      consecutiveNetworkFailures: networkFailures,
    );

    if (warning) {
      _eventBus.publish(const PredictiveDisconnectWarningEvent('Battery critical or link degraded'));
      if (_activeSessionId != null) {
        _disconnectService.protectAndRecord(
          sessionId: _activeSessionId!,
          reason: 'predictive_disconnect_warning',
          lastKnownBattery: batteryPercent,
          pendingQueueSize: _sequenceCounter,
        );
      }
    }
  }

  Future<void> stopEngine() async {
    _connectivitySubscription?.cancel();
    _connectivityMonitor.dispose();
    _qualityMonitor.stopProbing();
    _stateMachine.transitionTo(ReliabilityStatus.completed, sessionId: _activeSessionId);
  }

  void _handleConnectivityStateChange(ConnectivityState state) {
    if (state.isInternetAvailable) {
      if (_stateMachine.currentState.isOfflineMode || _stateMachine.currentState.status == ReliabilityStatus.queueing) {
        _stateMachine.transitionTo(ReliabilityStatus.synchronizing, sessionId: _activeSessionId);
        _eventBus.publish(InternetRestoredEvent(state));

        if (_activeSessionId != null) {
          _syncEngine.synchronizeSession(
            sessionId: _activeSessionId!,
            offlineStartTime: _offlineStartTime,
          ).then((summary) {
            _stateMachine.transitionTo(ReliabilityStatus.onlineMonitoring, sessionId: _activeSessionId);
          });
        }
      }
    } else {
      if (!_stateMachine.currentState.isOfflineMode) {
        _offlineStartTime = DateTime.now();
        _stateMachine.transitionTo(ReliabilityStatus.offlineMonitoring, sessionId: _activeSessionId);
        _eventBus.publish(InternetLostEvent(state));
      }
    }
  }
}
