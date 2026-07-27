/// monitoring_engine_service.dart
///
/// Production-grade Emergency Monitoring Engine core service. Runs continuous periodic monitoring loop,
/// applies adaptive intervals, calculates confidence & severity scores, generates immutable packets with FNV-1a checksums,
/// appends timeline entries, persists data locally, publishes events, uses Watchdog for health, and supports seamless restart recovery.

library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/monitoring_config.dart';
import '../../domain/entities/monitoring_state.dart';
import '../../domain/entities/monitoring_metrics.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import '../../domain/entities/packet_record.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/entities/session_metadata.dart';
import '../../domain/entities/recovery_info.dart';
import '../../domain/entities/monitoring_event.dart';
import '../../domain/entities/emergency_severity.dart';
import '../../domain/entities/session_integrity_report.dart';
import '../collectors/telemetry_aggregator.dart';
import 'event_detector_service.dart';
import 'timeline_generator_service.dart';
import 'monitoring_event_bus.dart';
import 'monitoring_storage_service.dart';
import 'battery_budget_manager.dart';
import 'monitoring_watchdog.dart';

class MonitoringEngineService {
  MonitoringEngineService({
    TelemetryAggregator? aggregator,
    EventDetectorService? eventDetector,
    TimelineGeneratorService? timelineGenerator,
    MonitoringEventBus? eventBus,
    MonitoringStorageService? storageService,
    BatteryBudgetManager? batteryBudgetManager,
  })  : _aggregator = aggregator ?? TelemetryAggregator(),
        _eventDetector = eventDetector ?? EventDetectorService(),
        _timelineGenerator = timelineGenerator ?? TimelineGeneratorService(),
        _eventBus = eventBus ?? MonitoringEventBus(),
        _storageService = storageService ?? MonitoringStorageService(),
        _batteryBudgetManager = batteryBudgetManager ?? const BatteryBudgetManager(),
        _stateController = StreamController<MonitoringEngineState>.broadcast(),
        _packetController = StreamController<PacketRecord>.broadcast() {
    _watchdog = MonitoringWatchdog(
      onStallDetected: _handleWatchdogStall,
    );
  }

  final TelemetryAggregator _aggregator;
  final EventDetectorService _eventDetector;
  final TimelineGeneratorService _timelineGenerator;
  final MonitoringEventBus _eventBus;
  final MonitoringStorageService _storageService;
  final BatteryBudgetManager _batteryBudgetManager;
  late final MonitoringWatchdog _watchdog;

  final StreamController<MonitoringEngineState> _stateController;
  final StreamController<PacketRecord> _packetController;

  Timer? _loopTimer;
  MonitoringEngineState _state = const MonitoringEngineState(
    status: MonitoringStatus.idle,
    activeConfig: MonitoringConfig(),
  );

  MonitoringMetrics _metrics = MonitoringMetrics.zero();
  TelemetrySnapshot? _lastSnapshot;
  DateTime? _sessionStartedAt;
  int _packetSequence = 0;
  final List<double> _collectionTimeHistoryMs = [];

  Stream<MonitoringEngineState> get stateStream => _stateController.stream;
  Stream<PacketRecord> get packetStream => _packetController.stream;
  Stream<MonitoringEvent> get eventStream => _eventBus.eventStream;

  MonitoringEngineState get currentState => _state;
  MonitoringMetrics get currentMetrics => _metrics;
  List<TimelineEntry> get currentTimeline => _timelineGenerator.entries;
  MonitoringWatchdog get watchdog => _watchdog;

  /// Starts continuous monitoring for an emergency session.
  Future<void> startMonitoring({
    required String sessionId,
    required String triggerType,
    MonitoringConfig? config,
  }) async {
    if (_state.isRunning) {
      debugPrint('MonitoringEngineService: Engine already running for session ${_state.sessionId}');
      return;
    }

    final activeConfig = config ?? const MonitoringConfig();
    _sessionStartedAt = DateTime.now();
    _packetSequence = 0;
    _collectionTimeHistoryMs.clear();
    _timelineGenerator.clear();

    _updateState(MonitoringEngineState(
      status: MonitoringStatus.initializing,
      sessionId: sessionId,
      startedAt: _sessionStartedAt,
      activeConfig: activeConfig,
    ));

    // Save session metadata for restart recovery
    final meta = SessionMetadata(
      sessionId: sessionId,
      startedAt: _sessionStartedAt!,
      isSessionActive: true,
      triggerType: triggerType,
      lastPacketNumber: 0,
      lastUpdatedUtc: DateTime.now().toUtc(),
    );
    await _storageService.saveSessionMetadata(meta);

    _updateState(_state.copyWith(status: MonitoringStatus.active));
    _eventBus.publish(EngineStateChangedEvent(_state));

    // Perform initial collection cycle immediately
    await _executeCycle(reasonCodeOverride: 'sos_activated');

    // Launch periodic collection loop & watchdog
    _scheduleLoopTimer(activeConfig.normalInterval);
    _watchdog.startWatchdog(activeConfig.normalInterval);
  }

  /// Evaluates telemetry and executes a single monitoring cycle.
  Future<PacketRecord?> executeCycleManual({String reasonCode = 'manual_trigger'}) async {
    if (!_state.isRunning) return null;
    return await _executeCycle(reasonCodeOverride: reasonCode);
  }

  /// Updates adaptive configuration intervals dynamically.
  void updateConfig(MonitoringConfig newConfig) {
    _state = _state.copyWith(activeConfig: newConfig);
    if (_state.isRunning && _loopTimer != null) {
      _scheduleLoopTimer(newConfig.normalInterval);
      _watchdog.updateInterval(newConfig.normalInterval);
    }
  }

  /// Stops continuous monitoring, finalizes session, and generates a SessionIntegrityReport.
  Future<SessionIntegrityReport?> stopMonitoring() async {
    if (!_state.isRunning) return null;

    final activeSessionId = _state.sessionId;

    _loopTimer?.cancel();
    _loopTimer = null;
    _watchdog.stopWatchdog();

    _updateState(_state.copyWith(status: MonitoringStatus.stopping));

    // Log session finalized timeline event
    final finalEntry = TimelineEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      utcTime: DateTime.now().toUtc(),
      localTime: DateTime.now(),
      monotonicElapsedMs: DateTime.now().millisecondsSinceEpoch - (_sessionStartedAt?.millisecondsSinceEpoch ?? 0),
      title: 'Emergency Session Finalized',
      description: 'Monitoring engine stopped gracefully. Total packets generated: $_packetSequence.',
      eventType: 'session_finalized',
    );
    _timelineGenerator.append(finalEntry);
    if (activeSessionId != null) {
      await _storageService.saveTimelineEntry(activeSessionId, finalEntry);
    }
    _eventBus.publish(TimelineAppendedEvent(finalEntry));

    // Generate Session Integrity Report
    SessionIntegrityReport? report;
    if (activeSessionId != null) {
      report = await _storageService.generateSessionIntegrityReport(activeSessionId);
    }

    // Clear active session recovery marker
    await _storageService.clearActiveSessionMetadata();

    _updateState(_state.copyWith(
      status: MonitoringStatus.idle,
      currentPacketNumber: 0,
    ));

    _eventBus.publish(EngineStateChangedEvent(_state));
    return report;
  }

  /// Auto-recovers an active session after application restart.
  Future<RecoveryInfo> recoverActiveSession() async {
    final meta = await _storageService.getActiveSessionMetadata();
    if (meta == null || !meta.isSessionActive) {
      return RecoveryInfo(
        hasActiveSession: false,
        recoveredAt: DateTime.now(),
      );
    }

    _sessionStartedAt = meta.startedAt;
    _packetSequence = meta.lastPacketNumber;
    final sessionId = meta.sessionId;

    // Load saved timeline and latest packet
    final timeline = await _storageService.getTimeline(sessionId);
    _timelineGenerator.loadExisting(timeline);
    final packets = await _storageService.getPackets(sessionId);
    final lastPacket = packets.isNotEmpty ? packets.last : null;

    _updateState(MonitoringEngineState(
      status: MonitoringStatus.recovering,
      sessionId: sessionId,
      startedAt: _sessionStartedAt,
      activeConfig: const MonitoringConfig(),
      currentPacketNumber: _packetSequence,
    ));

    // Append recovery event to timeline
    final recoveryEntry = TimelineEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      utcTime: DateTime.now().toUtc(),
      localTime: DateTime.now(),
      monotonicElapsedMs: DateTime.now().millisecondsSinceEpoch - _sessionStartedAt!.millisecondsSinceEpoch,
      title: 'Monitoring Engine Session Recovered',
      description: 'Resumed monitoring after app restart. Resuming sequence from packet #${_packetSequence + 1}.',
      eventType: 'session_recovered',
    );
    _timelineGenerator.append(recoveryEntry);
    await _storageService.saveTimelineEntry(sessionId, recoveryEntry);
    _eventBus.publish(TimelineAppendedEvent(recoveryEntry));

    _updateState(_state.copyWith(status: MonitoringStatus.active));
    _eventBus.publish(EngineStateChangedEvent(_state));

    // Execute collection cycle for recovery
    await _executeCycle(reasonCodeOverride: 'session_recovered');

    // Launch loop timer & watchdog
    _scheduleLoopTimer(_state.activeConfig.normalInterval);
    _watchdog.startWatchdog(_state.activeConfig.normalInterval);

    return RecoveryInfo(
      hasActiveSession: true,
      sessionMetadata: meta,
      lastPacket: lastPacket,
      recoveredAt: DateTime.now(),
    );
  }

  Future<PacketRecord?> _executeCycle({String? reasonCodeOverride}) async {
    final cycleStart = DateTime.now();

    try {
      final sessionId = _state.sessionId ?? 'UNKNOWN_SESSION';
      final config = _state.activeConfig;

      // Evaluate Battery Budget Manager rules
      final lastBat = _lastSnapshot?.device.batteryPercent ?? 100;
      final lastChg = _lastSnapshot?.device.isCharging ?? false;
      final batteryPolicy = _batteryBudgetManager.evaluatePolicy(
        batteryPercent: lastBat,
        isCharging: lastChg,
      );

      final enableMotion = config.enableMotionCollector && batteryPolicy.shouldCollectMotion;
      final enableHealth = config.enableHealthCollector && batteryPolicy.shouldCollectHealth;

      // 1. Aggregated sensor collection
      final snapshot = await _aggregator.aggregate(
        sessionStartedAt: _sessionStartedAt ?? cycleStart,
        locationTimeout: config.collectorTimeoutBudget,
        enableHealth: enableHealth,
        enableMotion: enableMotion,
      );

      // 2. Detect events and state shifts
      final eventResult = _eventDetector.detectStateChanges(
        current: snapshot,
        previous: _lastSnapshot,
        monotonicMs: snapshot.monotonicElapsedMs,
      );

      for (final event in eventResult.detectedEvents) {
        _timelineGenerator.append(event);
        await _storageService.saveTimelineEntry(sessionId, event);
        _eventBus.publish(TimelineAppendedEvent(event));
      }

      // Check for severity shift event
      if (_lastSnapshot != null && _lastSnapshot!.severity.level != snapshot.severity.level) {
        _eventBus.publish(SeverityChangedEvent(snapshot.severity));
      }

      final reasonCode = reasonCodeOverride ?? eventResult.reasonCode;

      // 3. Compile immutable packet record
      _packetSequence++;
      final duration = snapshot.localTime.difference(_sessionStartedAt ?? cycleStart);

      final payloadForHash = '$sessionId|$_packetSequence|$reasonCode|${snapshot.utcTime.toIso8601String()}|${snapshot.location.latitude},${snapshot.location.longitude}|${snapshot.device.batteryPercent}|${snapshot.confidence.overallConfidence}|${snapshot.severity.score}';
      final checksum = _storageService.calculateFnv1aChecksum(payloadForHash);

      final packet = PacketRecord(
        packetNumber: _packetSequence,
        reasonCode: reasonCode,
        sessionId: sessionId,
        utcTime: snapshot.utcTime,
        localTime: snapshot.localTime,
        monotonicElapsedMs: snapshot.monotonicElapsedMs,
        sessionDuration: duration,
        checksum: checksum,
        telemetry: snapshot,
      );

      // 4. Save locally
      await _storageService.savePacket(packet);

      // Update active session metadata
      await _storageService.saveSessionMetadata(SessionMetadata(
        sessionId: sessionId,
        startedAt: _sessionStartedAt ?? cycleStart,
        isSessionActive: true,
        triggerType: 'sos',
        lastPacketNumber: _packetSequence,
        lastUpdatedUtc: DateTime.now().toUtc(),
      ));

      _lastSnapshot = snapshot;

      // 5. Publish to streams & Event Bus
      if (!_packetController.isClosed) {
        Future<void>(() {
          if (!_packetController.isClosed) {
            _packetController.add(packet);
          }
        });
      }
      _eventBus.publish(PacketGeneratedEvent(packet));

      // Update Engine state packet counter & Ping Watchdog heartbeat
      _updateState(_state.copyWith(currentPacketNumber: _packetSequence));
      _watchdog.pingHeartbeat();

      // 6. Update reliability metrics & adaptive interval calculation
      final cycleDurationMs = DateTime.now().difference(cycleStart).inMilliseconds.toDouble();
      _updateMetrics(cycleDurationMs, snapshot);

      // Adjust adaptive loop frequency based on policy
      final nextIntervalMs = _calculateAdaptiveInterval(snapshot);
      if (nextIntervalMs != _metrics.currentIntervalMs) {
        final nextDuration = Duration(milliseconds: nextIntervalMs);
        _scheduleLoopTimer(nextDuration);
        _watchdog.updateInterval(nextDuration);
      }

      return packet;
    } catch (e) {
      debugPrint('MonitoringEngineService: Cycle execution error: $e');
      _updateState(_state.copyWith(lastError: e.toString()));
      return null;
    }
  }

  void _scheduleLoopTimer(Duration interval) {
    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(interval, (_) {
      _executeCycle();
    });
  }

  int _calculateAdaptiveInterval(TelemetrySnapshot snapshot) {
    final cfg = _state.activeConfig;

    if (snapshot.severity.level == EmergencySeverityLevel.critical) {
      return cfg.criticalInterval.inMilliseconds;
    } else if (snapshot.motion.motionState == 'vehicle' || snapshot.motion.motionState == 'running') {
      return cfg.fastMotionInterval.inMilliseconds;
    } else if (snapshot.device.isBatterySaverEnabled) {
      return cfg.batterySaverInterval.inMilliseconds;
    } else if (snapshot.motion.motionState == 'stationary') {
      return cfg.stationaryInterval.inMilliseconds;
    } else {
      return cfg.normalInterval.inMilliseconds;
    }
  }

  Future<void> _handleWatchdogStall() async {
    debugPrint('MonitoringEngineService: Watchdog detected stall. Auto-restarting monitoring timer...');
    if (_state.isRunning) {
      final currentInterval = Duration(milliseconds: _metrics.currentIntervalMs > 0 ? _metrics.currentIntervalMs : 10000);
      _scheduleLoopTimer(currentInterval);
      await _executeCycle(reasonCodeOverride: 'watchdog_auto_restart');
    }
  }

  void _updateMetrics(double cycleMs, TelemetrySnapshot snapshot) {
    _collectionTimeHistoryMs.add(cycleMs);
    if (_collectionTimeHistoryMs.length > 50) {
      _collectionTimeHistoryMs.removeAt(0);
    }

    final avgMs = _collectionTimeHistoryMs.reduce((a, b) => a + b) / _collectionTimeHistoryMs.length;
    final uptime = DateTime.now().difference(_sessionStartedAt ?? DateTime.now());
    final rate = uptime.inMinutes > 0 ? _packetSequence / uptime.inMinutes : _packetSequence.toDouble();

    _metrics = _metrics.copyWith(
      packetsGenerated: _packetSequence,
      packetsStored: _packetSequence,
      currentIntervalMs: _metrics.currentIntervalMs,
      averageCollectionTimeMs: avgMs,
      lastGpsAccuracy: snapshot.location.accuracy,
      batteryConsumptionPercent: snapshot.device.batteryPercent,
      lastLocationUpdateTime: snapshot.location.timestamp,
      monitoringUptime: uptime,
      lastSuccessfulCollectionTime: DateTime.now(),
      packetGenerationRatePerMin: rate,
    );
  }

  void _updateState(MonitoringEngineState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      Future<void>(() {
        if (!_stateController.isClosed) {
          _stateController.add(_state);
        }
      });
    }
  }

  Future<void> dispose() async {
    _loopTimer?.cancel();
    _watchdog.stopWatchdog();
    await _stateController.close();
    await _packetController.close();
    await _eventBus.dispose();
  }
}
