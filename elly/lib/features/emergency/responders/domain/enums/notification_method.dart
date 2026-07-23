/// notification_method.dart
///
/// The channel through which a responder is contacted when an emergency
/// is activated. Ordered from most to least intrusive by default.

library;

/// How the system contacts an emergency responder.
enum NotificationMethod {
  /// In-app or FCM push notification (lowest disruption).
  pushNotification,

  /// SMS text message.
  sms,

  /// Outbound phone call (most intrusive — highest attention probability).
  phoneCall,

  /// Email message (useful for hospitals / formal contacts).
  email,

  /// Webhook / REST API call to an external system (Phase 2+ placeholder).
  api;

  // ── Display Helpers ──────────────────────────────────────────────────────

  String get displayName {
    switch (this) {
      case NotificationMethod.pushNotification:
        return 'Push Notification';
      case NotificationMethod.sms:
        return 'SMS';
      case NotificationMethod.phoneCall:
        return 'Phone Call';
      case NotificationMethod.email:
        return 'Email';
      case NotificationMethod.api:
        return 'API (Webhook)';
    }
  }

  String get shortName {
    switch (this) {
      case NotificationMethod.pushNotification:
        return 'Push';
      case NotificationMethod.sms:
        return 'SMS';
      case NotificationMethod.phoneCall:
        return 'Call';
      case NotificationMethod.email:
        return 'Email';
      case NotificationMethod.api:
        return 'API';
    }
  }

  /// Whether this method requires a phone number to function.
  bool get requiresPhone =>
      this == NotificationMethod.sms || this == NotificationMethod.phoneCall;

  /// Whether this method requires an email address to function.
  bool get requiresEmail => this == NotificationMethod.email;
}
