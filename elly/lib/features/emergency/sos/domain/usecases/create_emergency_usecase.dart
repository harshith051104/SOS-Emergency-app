/// create_emergency_usecase.dart
///
/// Use case that orchestrates creating a new [EmergencyEvent].
/// Encapsulates domain business logic — the presentation layer calls this
/// instead of the repository directly.

library;

import '../entities/emergency_event.dart';
import '../enums/emergency_type.dart';
import '../repositories/emergency_repository.dart';

/// Creates a new [EmergencyEvent] via the [EmergencyRepository].
class CreateEmergencyUseCase {
  const CreateEmergencyUseCase(this._repository);

  final EmergencyRepository _repository;

  /// Executes the use case with the given [EmergencyType].
  ///
  /// Returns the newly created [EmergencyEvent].
  /// Propagates any exceptions from the repository layer.
  Future<EmergencyEvent> call(EmergencyType type) {
    return _repository.createEmergency(type);
  }
}
