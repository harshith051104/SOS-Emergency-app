/// get_medical_profile_usecase.dart
///
/// Use case loading the user's local medical profile.

library;

import '../entities/medical_section.dart';
import '../repositories/packet_repository.dart';

class GetMedicalProfileUseCase {
  const GetMedicalProfileUseCase(this._repository);

  final PacketRepository _repository;

  Future<MedicalSection> call() {
    return _repository.getMedicalProfile();
  }
}
