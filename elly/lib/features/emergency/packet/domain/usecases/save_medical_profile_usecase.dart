/// save_medical_profile_usecase.dart
///
/// Use case saving modifications to the local medical profile.

library;

import '../entities/medical_section.dart';
import '../repositories/packet_repository.dart';

class SaveMedicalProfileUseCase {
  const SaveMedicalProfileUseCase(this._repository);

  final PacketRepository _repository;

  Future<void> call(MedicalSection profile) {
    return _repository.saveMedicalProfile(profile);
  }
}
