/// emergency_data_packet_validator.dart
///
/// Pure domain validator checking EmergencyDataPacket structural integrity and version compliance.

library;

import 'package:elly/features/emergency/packet/domain/entities/emergency_data_packet.dart';

class PacketValidationReport {
  const PacketValidationReport._(this.isValid, this.warnings);

  factory PacketValidationReport.valid() => const PacketValidationReport._(true, []);

  factory PacketValidationReport.invalid(List<String> warnings) => PacketValidationReport._(false, warnings);

  final bool isValid;
  final List<String> warnings;
}

class EmergencyDataPacketValidator {
  static const String currentVersion = '1.0';

  static PacketValidationReport validate(EmergencyDataPacket packet) {
    final warnings = <String>[];

    if (packet.packetId.isEmpty) {
      warnings.add('Packet ID is empty.');
    }

    if (packet.sessionId.isEmpty) {
      warnings.add('Session ID is empty.');
    }

    if (packet.packetVersion != currentVersion) {
      warnings.add('Packet version mismatch: expected $currentVersion, found ${packet.packetVersion}.');
    }

    if (packet.name.isEmpty) {
      warnings.add('Health profile name is empty.');
    }

    if (warnings.isNotEmpty) {
      return PacketValidationReport.invalid(warnings);
    }
    return PacketValidationReport.valid();
  }
}
