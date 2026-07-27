/// packet_record.dart
///
/// Immutable Emergency Packet compiled per monitoring cycle.

library;

import 'package:equatable/equatable.dart';
import 'telemetry_snapshot.dart';

class PacketRecord extends Equatable {
  const PacketRecord({
    this.schemaVersion = '1.0',
    required this.packetNumber,
    required this.reasonCode,
    required this.sessionId,
    required this.utcTime,
    required this.localTime,
    required this.monotonicElapsedMs,
    required this.sessionDuration,
    required this.checksum,
    required this.telemetry,
  });

  /// Schema version for forward/backward compatibility (e.g. "1.0").
  final String schemaVersion;

  /// Sequential packet index (1, 2, 3...).
  final int packetNumber;

  /// Rationale for packet generation (e.g. "periodic_cycle", "battery_changed", "internet_lost").
  final String reasonCode;

  /// Active emergency session ID.
  final String sessionId;

  /// UTC Timestamp.
  final DateTime utcTime;

  /// Local Device Timestamp.
  final DateTime localTime;

  /// Monotonic elapsed time in ms since session launch or system boot.
  final int monotonicElapsedMs;

  /// Accumulated duration of the current emergency session.
  final Duration sessionDuration;

  /// FNV-1a or SHA-256 integrity checksum.
  final String checksum;

  /// Complete telemetry snapshot.
  final TelemetrySnapshot telemetry;

  @override
  List<Object?> get props => [
        schemaVersion,
        packetNumber,
        reasonCode,
        sessionId,
        utcTime,
        localTime,
        monotonicElapsedMs,
        sessionDuration,
        checksum,
        telemetry,
      ];
}
