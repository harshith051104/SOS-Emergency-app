/// offline_session_summary.dart
///
/// Summary report generated when connectivity returns after an offline period.

library;

import 'package:equatable/equatable.dart';

class OfflineSessionSummary extends Equatable {
  const OfflineSessionSummary({
    required this.sessionId,
    required this.offlineDuration,
    required this.packetsGeneratedOffline,
    required this.packetsUploaded,
    required this.syncDuration,
    required this.reconnectedAt,
  });

  final String sessionId;
  final Duration offlineDuration;
  final int packetsGeneratedOffline;
  final int packetsUploaded;
  final Duration syncDuration;
  final DateTime reconnectedAt;

  @override
  List<Object?> get props => [
        sessionId,
        offlineDuration,
        packetsGeneratedOffline,
        packetsUploaded,
        syncDuration,
        reconnectedAt,
      ];
}
