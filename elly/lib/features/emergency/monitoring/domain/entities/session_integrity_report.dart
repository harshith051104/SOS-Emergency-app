/// session_integrity_report.dart
///
/// Domain entity representing a finalized emergency session summary report.

library;

import 'package:equatable/equatable.dart';

class SessionIntegrityReport extends Equatable {
  const SessionIntegrityReport({
    required this.sessionId,
    required this.sessionDuration,
    required this.totalPacketsGenerated,
    required this.packetsStored,
    required this.corruptedPacketsDetected,
    required this.offlineDuration,
    required this.gpsAvailabilityPercent,
    required this.averageConfidencePercent,
    required this.highestSeverityLevel,
    required this.finalizedAt,
  });

  final String sessionId;
  final Duration sessionDuration;
  final int totalPacketsGenerated;
  final int packetsStored;
  final int corruptedPacketsDetected;
  final Duration offlineDuration;
  final double gpsAvailabilityPercent;
  final int averageConfidencePercent;
  final String highestSeverityLevel;
  final DateTime finalizedAt;

  @override
  List<Object?> get props => [
        sessionId,
        sessionDuration,
        totalPacketsGenerated,
        packetsStored,
        corruptedPacketsDetected,
        offlineDuration,
        gpsAvailabilityPercent,
        averageConfidencePercent,
        highestSeverityLevel,
        finalizedAt,
      ];
}
