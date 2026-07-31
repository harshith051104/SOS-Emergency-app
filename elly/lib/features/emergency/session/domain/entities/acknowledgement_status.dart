/// acknowledgement_status.dart
///
/// Enumeration tracking receipt/acknowledgement status of emergency session execution.

library;

enum AcknowledgementStatus {
  /// Emergency payload delivered to channels
  delivered,

  /// Recipient acknowledged receipt of emergency alert
  acknowledged,

  /// Delivery failed to one or more channels
  failed,

  /// Waiting for acknowledgement timed out
  timedOut,

  /// Unknown or unconfirmed status
  unknown,
}
