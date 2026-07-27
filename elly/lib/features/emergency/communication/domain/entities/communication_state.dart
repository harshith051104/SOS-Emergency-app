/// communication_state.dart
///
/// Deterministic Communication State Machine status entity.

library;

import 'package:equatable/equatable.dart';

enum CommunicationStatus {
  idle,
  preparing,
  selectingTransport,
  sending,
  awaitingAcknowledgement,
  delivered,
  escalating,
  completed,
  failed,
}

class CommunicationState extends Equatable {
  const CommunicationState({
    required this.status,
    this.activeRequestId,
    this.activeTransport,
    this.lastTransitionTime,
    this.lastError,
  });

  final CommunicationStatus status;
  final String? activeRequestId;
  final String? activeTransport;
  final DateTime? lastTransitionTime;
  final String? lastError;

  bool get isSending => status == CommunicationStatus.sending || status == CommunicationStatus.awaitingAcknowledgement;

  @override
  List<Object?> get props => [
        status,
        activeRequestId,
        activeTransport,
        lastTransitionTime,
        lastError,
      ];
}
