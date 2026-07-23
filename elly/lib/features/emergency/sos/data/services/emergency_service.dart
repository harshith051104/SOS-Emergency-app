/// emergency_service.dart
///
/// Abstract service interface for the Emergency feature.
/// This sits in the data layer and defines the contract for all
/// future integrations (backend API, location, contacts, wearable, AI).
///
/// Phase 1: Only [createEmergency] and [cancelEmergency] are implemented
/// (via mock). All other methods throw [UnimplementedError] as explicit
/// future placeholders.

library;

import '../../domain/entities/emergency_event.dart';
import '../../domain/enums/emergency_type.dart';

/// Service contract for all emergency-related operations.
///
/// The concrete implementation in Phase 1 is a mock.
/// Phase 2+ replaces the implementation with a real backend client
/// without touching any domain or presentation code.
abstract class EmergencyService {
  // ── Phase 1 — Implemented ─────────────────────────────────────────────────

  /// Creates a new emergency event of the given [type].
  Future<EmergencyEvent> createEmergency(EmergencyType type);

  /// Cancels an emergency event identified by [eventId].
  Future<void> cancelEmergency(String eventId);

  // ── Phase 2 — Contact & Location ─────────────────────────────────────────

  /// Notifies the user's emergency contacts of the active emergency.
  Future<void> notifyContacts(String eventId);

  /// Shares the user's current location with responders and contacts.
  Future<void> shareLocation(String eventId);

  // ── Phase 3 — Live Tracking ───────────────────────────────────────────────

  /// Begins a live tracking session for the emergency [eventId].
  Future<void> startTracking(String eventId);

  /// Ends the live tracking session for the emergency [eventId].
  Future<void> endTracking(String eventId);

  // ── Phase 4 — Alternative Triggers ───────────────────────────────────────

  /// Triggers an emergency from a voice command.
  Future<void> triggerFromVoice();

  /// Triggers an emergency automatically via AI/ML detection.
  Future<void> triggerAutomatically();

  /// Triggers an emergency from a connected wearable device.
  Future<void> triggerFromWearable();
}
