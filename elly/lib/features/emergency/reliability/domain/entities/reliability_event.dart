/// reliability_event.dart
///
/// Event Bus domain events for the Reliability Engine.

library;

import 'package:equatable/equatable.dart';
import 'connectivity_state.dart';
import 'disconnect_info.dart';
import 'reliability_state.dart';

abstract class ReliabilityEvent extends Equatable {
  const ReliabilityEvent();

  @override
  List<Object?> get props => [];
}

class InternetLostEvent extends ReliabilityEvent {
  const InternetLostEvent(this.connectivityState);
  final ConnectivityState connectivityState;
  @override
  List<Object?> get props => [connectivityState];
}

class InternetRestoredEvent extends ReliabilityEvent {
  const InternetRestoredEvent(this.connectivityState);
  final ConnectivityState connectivityState;
  @override
  List<Object?> get props => [connectivityState];
}

class AirplaneModeEnabledEvent extends ReliabilityEvent {
  const AirplaneModeEnabledEvent(this.timestamp);
  final DateTime timestamp;
  @override
  List<Object?> get props => [timestamp];
}

class AirplaneModeDisabledEvent extends ReliabilityEvent {
  const AirplaneModeDisabledEvent(this.timestamp);
  final DateTime timestamp;
  @override
  List<Object?> get props => [timestamp];
}

class PredictiveDisconnectWarningEvent extends ReliabilityEvent {
  const PredictiveDisconnectWarningEvent(this.warningReason);
  final String warningReason;
  @override
  List<Object?> get props => [warningReason];
}

class QueueOverflowEvent extends ReliabilityEvent {
  const QueueOverflowEvent({required this.droppedItemCount});
  final int droppedItemCount;
  @override
  List<Object?> get props => [droppedItemCount];
}

class SynchronizationStartedEvent extends ReliabilityEvent {
  const SynchronizationStartedEvent(this.pendingItemsCount);
  final int pendingItemsCount;
  @override
  List<Object?> get props => [pendingItemsCount];
}

class SynchronizationCompletedEvent extends ReliabilityEvent {
  const SynchronizationCompletedEvent({required this.syncedCount, required this.failedCount});
  final int syncedCount;
  final int failedCount;
  @override
  List<Object?> get props => [syncedCount, failedCount];
}

class SessionRecoveredEvent extends ReliabilityEvent {
  const SessionRecoveredEvent(this.sessionId);
  final String sessionId;
  @override
  List<Object?> get props => [sessionId];
}

class DisconnectDetectedEvent extends ReliabilityEvent {
  const DisconnectDetectedEvent(this.disconnectInfo);
  final DisconnectInfo disconnectInfo;
  @override
  List<Object?> get props => [disconnectInfo];
}

class ReliabilityStateChangedEvent extends ReliabilityEvent {
  const ReliabilityStateChangedEvent(this.state);
  final ReliabilityState state;
  @override
  List<Object?> get props => [state];
}
