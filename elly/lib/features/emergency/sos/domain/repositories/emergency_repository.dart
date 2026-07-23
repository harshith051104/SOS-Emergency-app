/// emergency_repository.dart
///
/// Abstract repository interface for the Emergency domain.
/// The domain layer depends only on this interface — never on any
/// concrete implementation (Dependency Inversion Principle).
///
/// Phase 1: Implemented by [EmergencyRepositoryImpl] (mock/local).
/// Phase 2: Replaced by a network implementation without touching domain code.

library;

import '../entities/emergency_event.dart';
import '../enums/emergency_type.dart';

/// Contract for all emergency data operations.
abstract interface class EmergencyRepository {
  /// Creates and persists a new [EmergencyEvent] of the given [type].
  ///
  /// Returns the created event with a UUID, creation timestamp, and
  /// initial [EmergencyStatus.activating] status.
  ///
  /// Throws an [EmergencyException] on failure.
  Future<EmergencyEvent> createEmergency(EmergencyType type);

  /// Cancels an active emergency identified by [eventId].
  ///
  /// Returns the updated [EmergencyEvent] with [EmergencyStatus.cancelled].
  Future<EmergencyEvent> cancelEmergency(String eventId);

  /// Retrieves the most recent [EmergencyEvent], or null if none exists.
  Future<EmergencyEvent?> getLatestEmergency();
}
