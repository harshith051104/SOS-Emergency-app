/// recovery_info.dart
///
/// Entity providing session state required to resume monitoring after app restart.

library;

import 'package:equatable/equatable.dart';
import 'session_metadata.dart';
import 'packet_record.dart';

class RecoveryInfo extends Equatable {
  const RecoveryInfo({
    required this.hasActiveSession,
    this.sessionMetadata,
    this.lastPacket,
    required this.recoveredAt,
  });

  final bool hasActiveSession;
  final SessionMetadata? sessionMetadata;
  final PacketRecord? lastPacket;
  final DateTime recoveredAt;

  @override
  List<Object?> get props => [
        hasActiveSession,
        sessionMetadata,
        lastPacket,
        recoveredAt,
      ];
}
