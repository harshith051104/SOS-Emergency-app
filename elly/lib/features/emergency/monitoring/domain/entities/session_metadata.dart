/// session_metadata.dart
///
/// Persistent metadata describing an active emergency session.

library;

import 'package:equatable/equatable.dart';

class SessionMetadata extends Equatable {
  const SessionMetadata({
    required this.sessionId,
    required this.startedAt,
    required this.isSessionActive,
    required this.triggerType,
    required this.lastPacketNumber,
    required this.lastUpdatedUtc,
  });

  final String sessionId;
  final DateTime startedAt;
  final bool isSessionActive;
  final String triggerType;
  final int lastPacketNumber;
  final DateTime lastUpdatedUtc;

  SessionMetadata copyWith({
    String? sessionId,
    DateTime? startedAt,
    bool? isSessionActive,
    String? triggerType,
    int? lastPacketNumber,
    DateTime? lastUpdatedUtc,
  }) {
    return SessionMetadata(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      triggerType: triggerType ?? this.triggerType,
      lastPacketNumber: lastPacketNumber ?? this.lastPacketNumber,
      lastUpdatedUtc: lastUpdatedUtc ?? this.lastUpdatedUtc,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        startedAt,
        isSessionActive,
        triggerType,
        lastPacketNumber,
        lastUpdatedUtc,
      ];
}
