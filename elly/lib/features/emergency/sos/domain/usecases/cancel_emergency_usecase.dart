/// cancel_emergency_usecase.dart
///
/// Use case that orchestrates cancelling an active [EmergencyEvent].

library;

import '../entities/emergency_event.dart';
import '../repositories/emergency_repository.dart';

/// Cancels an existing emergency event by its ID.
class CancelEmergencyUseCase {
  const CancelEmergencyUseCase(this._repository);

  final EmergencyRepository _repository;

  /// Executes the cancellation for the event identified by [eventId].
  ///
  /// Returns the updated [EmergencyEvent] with cancelled status.
  Future<EmergencyEvent> call(String eventId) {
    return _repository.cancelEmergency(eventId);
  }
}
