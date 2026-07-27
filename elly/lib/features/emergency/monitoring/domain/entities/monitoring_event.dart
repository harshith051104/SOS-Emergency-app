/// monitoring_event.dart
///
/// Event Bus payload domain classes for reactive pub-sub monitoring updates.

library;

import 'package:equatable/equatable.dart';
import 'packet_record.dart';
import 'sensor_health.dart';
import 'emergency_severity.dart';
import 'timeline_entry.dart';
import 'monitoring_state.dart';

abstract class MonitoringEvent extends Equatable {
  const MonitoringEvent();

  @override
  List<Object?> get props => [];
}

class PacketGeneratedEvent extends MonitoringEvent {
  const PacketGeneratedEvent(this.packet);

  final PacketRecord packet;

  @override
  List<Object?> get props => [packet];
}

class SensorHealthChangedEvent extends MonitoringEvent {
  const SensorHealthChangedEvent(this.sensorHealth);

  final SensorHealth sensorHealth;

  @override
  List<Object?> get props => [sensorHealth];
}

class SeverityChangedEvent extends MonitoringEvent {
  const SeverityChangedEvent(this.severity);

  final EmergencySeverity severity;

  @override
  List<Object?> get props => [severity];
}

class TimelineAppendedEvent extends MonitoringEvent {
  const TimelineAppendedEvent(this.timelineEntry);

  final TimelineEntry timelineEntry;

  @override
  List<Object?> get props => [timelineEntry];
}

class EngineStateChangedEvent extends MonitoringEvent {
  const EngineStateChangedEvent(this.state);

  final MonitoringEngineState state;

  @override
  List<Object?> get props => [state];
}
