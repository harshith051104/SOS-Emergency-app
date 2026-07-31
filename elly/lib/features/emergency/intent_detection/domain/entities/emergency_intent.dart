/// emergency_intent.dart
///
/// Typed enums for emergency intent classification categories and processing methods.

library;

enum EmergencyIntent {
  emergency,
  possibleEmergency,
  nonEmergency,
  unknown,
}

enum IntentProcessingMethod {
  ruleBased,
  localModel,
  mock,
}
