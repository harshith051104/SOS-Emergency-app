/// generate_packet_usecase.dart
///
/// Use case orchestrating the generation of an Emergency Data Packet.

library;

import '../entities/emergency_packet.dart';
import '../repositories/packet_repository.dart';

class GeneratePacketUseCase {
  const GeneratePacketUseCase(this._repository);

  final PacketRepository _repository;

  Future<EmergencyPacket> call({
    required String id,
    required String sessionId,
    required String type,
  }) {
    return _repository.generatePacket(
      id: id,
      sessionId: sessionId,
      type: type,
    );
  }
}
