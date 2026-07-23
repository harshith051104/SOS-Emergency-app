/// packet_repository_impl.dart
///
/// Concrete implementation of PacketRepository managing packet compilation
/// pipelines, serialization, storage caches, and local medical profile storage.

library;

import 'package:elly/features/emergency/packet/data/services/medical_profile_service.dart';
import '../../domain/entities/emergency_packet.dart';
import '../../domain/entities/medical_section.dart';
import '../../domain/repositories/packet_repository.dart';
import '../services/packet_builder.dart';
import '../services/packet_serializer.dart';
import '../services/packet_storage.dart';

class PacketRepositoryImpl implements PacketRepository {
  PacketRepositoryImpl({
    required EmergencyPacketBuilder builder,
    required EmergencyPacketSerializer serializer,
    required EmergencyPacketStorage storage,
    required MedicalProfileService medicalProfileService,
  })  : _builder = builder,
        _serializer = serializer,
        _storage = storage,
        _medicalProfileService = medicalProfileService;

  final EmergencyPacketBuilder _builder;
  final EmergencyPacketSerializer _serializer;
  final EmergencyPacketStorage _storage;
  final MedicalProfileService _medicalProfileService;

  @override
  Future<EmergencyPacket> generatePacket({
    required String id,
    required String sessionId,
    required String type,
  }) async {
    final packet = await _builder.build(
      id: id,
      sessionId: sessionId,
      type: type,
    );

    // Save to local cache
    final serialized = _serializer.serialize(packet);
    await _storage.save(sessionId, serialized);

    return packet;
  }

  @override
  Future<EmergencyPacket?> getCachedPacket(String sessionId) async {
    final serialized = await _storage.load(sessionId);
    if (serialized == null) return null;
    return _serializer.deserialize(serialized);
  }

  @override
  Future<MedicalSection> getMedicalProfile() async {
    return _medicalProfileService.getMedicalProfile();
  }

  @override
  Future<void> saveMedicalProfile(MedicalSection profile) async {
    return _medicalProfileService.saveMedicalProfile(profile);
  }
}
