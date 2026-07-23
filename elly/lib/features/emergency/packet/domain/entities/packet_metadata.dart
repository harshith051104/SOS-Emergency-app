/// packet_metadata.dart
///
/// Part of the versioned Emergency Data Packet.
/// Holds compilation analytics, schema versions, and audit hashes.

library;

import 'package:equatable/equatable.dart';

class PacketMetadata extends Equatable {
  const PacketMetadata({
    required this.created,
    required this.updated,
    required this.version,
    required this.generatedBy,
    required this.packetSize,
    required this.checksum,
  });

  /// Timestamp of initial packet instantiation.
  final DateTime created;

  /// Timestamp of last incremental section update.
  final DateTime updated;

  /// Revision schema version of the document.
  final int version;

  /// System component ID generating this packet (e.g. "ELLY_SOS_V1").
  final String generatedBy;

  /// Formatted size estimate of payload (e.g. "12.4 KB").
  final String packetSize;

  /// Cryptographic SHA-256 integrity hash of serialization string.
  final String checksum;

  PacketMetadata copyWith({
    DateTime? created,
    DateTime? updated,
    int? version,
    String? generatedBy,
    String? packetSize,
    String? checksum,
  }) {
    return PacketMetadata(
      created: created ?? this.created,
      updated: updated ?? this.updated,
      version: version ?? this.version,
      generatedBy: generatedBy ?? this.generatedBy,
      packetSize: packetSize ?? this.packetSize,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  List<Object?> get props => [
        created,
        updated,
        version,
        generatedBy,
        packetSize,
        checksum,
      ];
}
