/// response_update_type.dart
///
/// Discriminator for [ResponseEngineUpdate] events emitted by the
/// [EmergencyResponseEngine] stream.

library;

/// The type of event emitted by [EmergencyResponseEngine.execute].
enum ResponseUpdateType {
  /// Engine has started processing the emergency event.
  started,

  /// Engine is generating the emergency summary message.
  generatingSummary,

  /// About to dispatch a notification to a responder via a specific channel.
  notifying,

  /// A notification was dispatched (may have succeeded or failed).
  notified,

  /// A responder acknowledged the emergency.
  acknowledged,

  /// The acknowledgement window expired without a response from this responder.
  timedOut,

  /// Moving to the next responder in the priority queue.
  escalating,

  /// All responders processed — engine has completed.
  completed,

  /// Engine encountered an unrecoverable error.
  failed,

  /// The user or system cancelled the response.
  cancelled,
}

extension ResponseUpdateTypeX on ResponseUpdateType {
  String get displayLabel {
    switch (this) {
      case ResponseUpdateType.started:
        return 'Response started';
      case ResponseUpdateType.generatingSummary:
        return 'Generating summary';
      case ResponseUpdateType.notifying:
        return 'Notifying';
      case ResponseUpdateType.notified:
        return 'Notification sent';
      case ResponseUpdateType.acknowledged:
        return 'Acknowledged';
      case ResponseUpdateType.timedOut:
        return 'No response — escalating';
      case ResponseUpdateType.escalating:
        return 'Escalating to next responder';
      case ResponseUpdateType.completed:
        return 'Response complete';
      case ResponseUpdateType.failed:
        return 'Response failed';
      case ResponseUpdateType.cancelled:
        return 'Response cancelled';
    }
  }

  bool get isTerminal =>
      this == ResponseUpdateType.completed ||
      this == ResponseUpdateType.failed ||
      this == ResponseUpdateType.cancelled;
}
