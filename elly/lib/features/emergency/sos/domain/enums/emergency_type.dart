/// emergency_type.dart
///
/// Categorises the trigger source of an emergency event.
/// Phase 1 only uses [manual].
/// All other values are stubs for future capabilities.

library;

/// The trigger type that initiated an [EmergencyEvent].
enum EmergencyType {
  /// Phase 1 — User-initiated via the SOS button.
  manual,

  /// Phase 2 — Voice command detection.
  voice,

  /// Phase 3 — AI / ML automatic detection.
  automatic,

  /// Phase 4 — Wearable device trigger (e.g., Apple Watch, Garmin).
  wearable,

  /// Phase 5 — Fall detection sensor trigger.
  fallDetection,

  /// Phase 5 — Health metric alert (e.g., abnormal heart rate).
  healthAlert,
}
