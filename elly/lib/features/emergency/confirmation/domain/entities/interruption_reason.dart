/// interruption_reason.dart
///
/// Enumeration of reasons why a confirmation session was interrupted.

library;

enum InterruptionReason {
  /// Operating system or user killed the app process
  appKilled,

  /// App lost foreground focus/priority during confirmation
  appBackgrounded,

  /// Device experienced a reboot or restart
  deviceRestart,

  /// Device shutdown due to low battery power
  batteryLoss,

  /// Unhandled/unknown interruption
  unknown,

  /// No interruption occurred
  none,
}
