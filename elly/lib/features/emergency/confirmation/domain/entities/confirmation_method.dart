/// confirmation_method.dart
///
/// Enumeration of confirmation channels/methods used by the user or system.

library;

enum ConfirmationMethod {
  /// User responded via spoken voice phrase
  voice,

  /// User responded via manual UI button press
  button,

  /// Countdown timer expired automatically
  autoTimeout,

  /// No interactive method was invoked
  none,
}
