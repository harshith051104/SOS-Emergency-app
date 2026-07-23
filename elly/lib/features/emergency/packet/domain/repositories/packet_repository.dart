/// packet_repository.dart
///
/// Interface defining contract for packet generation, caching,
/// and local medical profile persistence.

library;

import '../entities/emergency_packet.dart';
import '../entities/medical_section.dart';

abstract interface class PacketRepository {
  /// Compiles a fresh versioned packet by orchestrating the contributors.
  Future<EmergencyPacket> generatePacket({
    required String id,
    required String sessionId,
    required String type,
  });

  /// Retrieves the cached packet for the given session ID, if any.
  Future<EmergencyPacket?> getCachedPacket(String sessionId);

  /// Loads the locally stored medical profile.
  Future<MedicalSection> getMedicalProfile();

  /// Persists modifications to the user's local medical profile.
  Future<void> saveMedicalProfile(MedicalSection profile);
}
