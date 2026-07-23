/// get_emergency_state_usecase.dart
///
/// Use case for retrieving the most recent [EmergencyEvent].
/// Useful for restoring UI state after app restarts.

library;

import '../entities/emergency_event.dart';
import '../repositories/emergency_repository.dart';

/// Retrieves the latest [EmergencyEvent] from the repository.
class GetEmergencyStateUseCase {
  const GetEmergencyStateUseCase(this._repository);

  final EmergencyRepository _repository;

  /// Returns the most recent [EmergencyEvent], or null if none exists.
  Future<EmergencyEvent?> call() {
    return _repository.getLatestEmergency();
  }
}
