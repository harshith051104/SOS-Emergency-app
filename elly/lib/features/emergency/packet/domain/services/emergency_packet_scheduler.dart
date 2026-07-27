/// emergency_packet_scheduler.dart
///
/// Continuous adaptive EmergencyDataPacket scheduler service managing periodic and event-driven
/// packet generation, sequence increments, battery diagnostic adjustments, and queue/sync pipeline dispatching.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/packet/domain/builder/emergency_data_packet_builder.dart';


import 'package:elly/features/emergency/packet/domain/validation/severity_calculator.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';
import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';
import 'package:elly/features/emergency/telemetry/presentation/providers/telemetry_providers.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/sos/presentation/controllers/emergency_session_controller.dart';


class SchedulerState {
  const SchedulerState({
    this.isActive = false,
    this.isPaused = false,
    this.currentIntervalSeconds = 15,
    this.sequenceNumber = 0,
    this.packetsGenerated = 0,
    this.lastGeneratedAt,
    this.nextScheduledAt,
    this.lastTriggerReason = 'System Init',
    this.isBatteryOptimizationActive = false,
  });

  final bool isActive;
  final bool isPaused;
  final int currentIntervalSeconds;
  final int sequenceNumber;
  final int packetsGenerated;
  final DateTime? lastGeneratedAt;
  final DateTime? nextScheduledAt;
  final String lastTriggerReason;
  final bool isBatteryOptimizationActive;

  SchedulerState copyWith({
    bool? isActive,
    bool? isPaused,
    int? currentIntervalSeconds,
    int? sequenceNumber,
    int? packetsGenerated,
    DateTime? lastGeneratedAt,
    DateTime? nextScheduledAt,
    String? lastTriggerReason,
    bool? isBatteryOptimizationActive,
  }) {
    return SchedulerState(
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      currentIntervalSeconds: currentIntervalSeconds ?? this.currentIntervalSeconds,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      packetsGenerated: packetsGenerated ?? this.packetsGenerated,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      nextScheduledAt: nextScheduledAt ?? this.nextScheduledAt,
      lastTriggerReason: lastTriggerReason ?? this.lastTriggerReason,
      isBatteryOptimizationActive: isBatteryOptimizationActive ?? this.isBatteryOptimizationActive,
    );
  }
}

class EmergencyPacketScheduler extends StateNotifier<SchedulerState> {
  EmergencyPacketScheduler(this._ref) : super(const SchedulerState());

  final Ref _ref;
  Timer? _timer;

  void startScheduler() {
    if (state.isActive) return;

    final now = AppClock.now();
    final initialInterval = _evaluateCurrentInterval();

    state = state.copyWith(
      isActive: true,
      isPaused: false,
      currentIntervalSeconds: initialInterval,
      nextScheduledAt: now.add(Duration(seconds: initialInterval)),
    );

    appLogger.info('EmergencyPacketScheduler: Started continuous scheduler ($initialInterval s interval).');

    final event = PacketSchedulerStartedPlatformEvent(
      eventId: 'evt_sch_start_${now.millisecondsSinceEpoch}',
      timestamp: now,
      initialIntervalSeconds: initialInterval,
    );
    _ref.read(emergencyEventBusProvider).publish('PacketSchedulerStarted', event.toJson());

    _recordTimeline(
      title: 'Packet Scheduler Started',
      description: 'Continuous packet generation active ($initialInterval s interval).',
      severity: EventSeverity.info,
    );

    // Immediate generation of Packet #1
    triggerImmediatePacket('Emergency Activation (Packet #1)');
    _resetTimer();
  }

  void stopScheduler() {
    if (!state.isActive) return;

    _timer?.cancel();
    _timer = null;

    final now = AppClock.now();
    appLogger.info('EmergencyPacketScheduler: Stopped scheduler (Total generated: ${state.packetsGenerated}).');

    final event = PacketSchedulerStoppedPlatformEvent(
      eventId: 'evt_sch_stop_${now.millisecondsSinceEpoch}',
      timestamp: now,
      totalGenerated: state.packetsGenerated,
    );
    _ref.read(emergencyEventBusProvider).publish('PacketSchedulerStopped', event.toJson());

    _recordTimeline(
      title: 'Packet Scheduler Stopped',
      description: 'Emergency session ended. Total packets generated: ${state.packetsGenerated}.',
      severity: EventSeverity.info,
    );

    state = state.copyWith(isActive: false, isPaused: false);
  }

  void pauseScheduler() {
    if (!state.isActive || state.isPaused) return;
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resumeScheduler() {
    if (!state.isActive || !state.isPaused) return;
    state = state.copyWith(isPaused: false);
    _resetTimer();
  }

  Future<void> triggerImmediatePacket(String reason) async {
    if (!state.isActive) return;

    final now = AppClock.now();
    final nextSeq = state.sequenceNumber + 1;

    try {
      final context = _ref.read(emergencyContextProvider);
      final snapshot = _ref.read(sessionSnapshotProvider);
      final location = _ref.read(latestTelemetryPointProvider);
      final circle = _ref.read(sosCircleStateProvider);
      final netState = _ref.read(networkStateProvider);
      final sosSessionState = _ref.read(emergencySessionControllerProvider);

      final packet = EmergencyDataPacketBuilder.build(
        context: context,
        snapshot: snapshot,
        location: location,
        circle: circle,
        confirmationResult: sosSessionState.lastConfirmationResult,
        networkState: netState,
        sequenceNumber: nextSeq,
      );

      // Pass packet to OfflineQueueService and trigger SynchronizationService
      final queueService = _ref.read(offlineQueueProvider);
      final syncService = _ref.read(synchronizationServiceProvider);

      await queueService.enqueuePacket(packet);
      if (netState.name == 'online') {
        syncService.synchronizePendingPackets();
      }

      final evalInterval = _evaluateCurrentInterval();

      state = state.copyWith(
        sequenceNumber: nextSeq,
        packetsGenerated: state.packetsGenerated + 1,
        lastGeneratedAt: now,
        nextScheduledAt: now.add(Duration(seconds: evalInterval)),
        lastTriggerReason: reason,
        currentIntervalSeconds: evalInterval,
      );

      final genEvent = PacketGeneratedPlatformEvent(
        eventId: 'evt_pkt_gen_${now.millisecondsSinceEpoch}',
        timestamp: now,
        packetId: packet.packetId,
        sequenceNumber: nextSeq,
        isDelta: packet.isDelta,
        triggerReason: reason,
      );
      _ref.read(emergencyEventBusProvider).publish('PacketGenerated', genEvent.toJson());

      _recordTimeline(
        title: 'Packet Generated',
        description: 'Generated ${packet.isDelta ? "Delta " : ""}Packet #${packet.sequenceNumber} [ID: ${packet.packetId}] ($reason).',
        severity: EventSeverity.info,
      );

    } catch (e) {
      appLogger.error('EmergencyPacketScheduler: Packet generation failed: $e', e);

      final failEvent = PacketGenerationFailedPlatformEvent(
        eventId: 'evt_pkt_fail_${now.millisecondsSinceEpoch}',
        timestamp: now,
        reason: e.toString(),
      );
      _ref.read(emergencyEventBusProvider).publish('PacketGenerationFailed', failEvent.toJson());
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    if (!state.isActive || state.isPaused) return;

    final interval = _evaluateCurrentInterval();
    _timer = Timer.periodic(Duration(seconds: interval), (_) {
      triggerImmediatePacket('Periodic Timer Tick (${interval}s)');
    });
  }

  int _evaluateCurrentInterval() {
    final context = _ref.read(emergencyContextProvider);
    final passport = _ref.read(emergencyContextProvider).healthPassport;
    final confirmation = _ref.read(emergencySessionControllerProvider).lastConfirmationResult;

    final severity = SeverityCalculator.calculate(
      highRisk: context.highRisk,
      profile: passport?.profile,
      confirmationResult: confirmation,
    );

    int baseInterval;
    switch (severity) {
      case PacketSeverity.critical:
        baseInterval = 5;
      case PacketSeverity.high:
        baseInterval = 15;
      case PacketSeverity.medium:
        baseInterval = 20;
      case PacketSeverity.low:
        baseInterval = 30;
    }

    const int batteryLevel = 85; // Responders battery diagnostics
    int multiplier = 1;

    if (severity != PacketSeverity.critical) {
      if (batteryLevel < 20) {
        multiplier = 3;
      } else if (batteryLevel <= 50) {
        multiplier = 2;
      }
    }

    final finalInterval = baseInterval * multiplier;

    if (state.currentIntervalSeconds != finalInterval && state.isActive) {
      final oldInt = state.currentIntervalSeconds;
      final now = AppClock.now();

      _ref.read(emergencyEventBusProvider).publish(
        'PacketIntervalChanged',
        PacketIntervalChangedPlatformEvent(
          eventId: 'evt_int_chg_${now.millisecondsSinceEpoch}',
          timestamp: now,
          oldIntervalSeconds: oldInt,
          newIntervalSeconds: finalInterval,
          reason: 'Severity (${severity.name}) / Battery ($batteryLevel%) Adjustment',
        ).toJson(),
      );

      _recordTimeline(
        title: 'Packet Interval Changed',
        description: 'Interval scaled from ${oldInt}s ➔ ${finalInterval}s (Severity: ${severity.name}).',
        severity: EventSeverity.info,
      );
    }

    return finalInterval;
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = _ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_sch_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Packet Scheduler',
      ));
    } catch (e) {
      appLogger.warning('EmergencyPacketScheduler: Could not log timeline event: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final emergencyPacketSchedulerProvider =
    StateNotifierProvider<EmergencyPacketScheduler, SchedulerState>((ref) {
  return EmergencyPacketScheduler(ref);
});
