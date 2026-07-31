/// confirmation_outcome.dart
///
/// Enumeration of possible confirmation outcomes produced by the Confirmation Engine.

library;

enum ConfirmationOutcome {
  /// User explicitly confirmed the emergency via voice or button
  confirmed,

  /// User explicitly cancelled/denied the emergency via voice or button
  cancelled,

  /// Countdown timer expired with no explicit user response
  timedOut,

  /// Confirmation process was interrupted (app suspension, battery/crash/kill)
  interrupted,

  /// Decision recommendation baseline indicated no user confirmation required
  noConfirmationRequired,
}
