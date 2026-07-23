/// responder_type.dart
///
/// Categorises each emergency responder by their relationship to the user.
/// The [type] drives the icon, colour, and display label in the UI.

library;

/// The relationship category of an emergency responder.
enum ResponderType {
  /// A family member (parent, spouse, sibling, child, etc.).
  family,

  /// A personal caregiver, nurse, or support worker.
  caregiver,

  /// A medical doctor or healthcare professional.
  doctor,

  /// A hospital or medical facility.
  hospital,

  /// An official emergency service (police, fire, ambulance, 112/911).
  emergencyService;

  // ── Display Helpers ──────────────────────────────────────────────────────

  String get displayName {
    switch (this) {
      case ResponderType.family:
        return 'Family';
      case ResponderType.caregiver:
        return 'Caregiver';
      case ResponderType.doctor:
        return 'Doctor';
      case ResponderType.hospital:
        return 'Hospital';
      case ResponderType.emergencyService:
        return 'Emergency Service';
    }
  }

  /// Material icon that represents this type.
  String get iconCodePoint {
    switch (this) {
      case ResponderType.family:
        return 'family_restroom';
      case ResponderType.caregiver:
        return 'support_agent';
      case ResponderType.doctor:
        return 'medical_services';
      case ResponderType.hospital:
        return 'local_hospital';
      case ResponderType.emergencyService:
        return 'emergency';
    }
  }
}
