/// responder.dart
///
/// Core domain entity representing a single emergency responder.
/// Responders are notified in [priority] order (0 = highest).

library;

import 'package:equatable/equatable.dart';

import '../enums/notification_method.dart';
import '../enums/responder_type.dart';

/// An immutable emergency responder contact.
class Responder extends Equatable {
  const Responder({
    required this.id,
    required this.name,
    required this.type,
    required this.notificationMethods,
    this.phoneNumber,
    this.email,
    this.priority = 0,
    this.isEnabled = true,
    this.acknowledgementTimeoutSeconds = 30,
  });

  /// UUID v4 — unique identifier.
  final String id;

  /// Display name (e.g. "Mom", "Dr. Sharma").
  final String name;

  /// Relationship / role category.
  final ResponderType type;

  /// Ordered list of channels to use when notifying this responder.
  /// All channels in this list are tried; order determines priority.
  final List<NotificationMethod> notificationMethods;

  /// Phone number (required for [NotificationMethod.sms] / [phoneCall]).
  final String? phoneNumber;

  /// Email address (required for [NotificationMethod.email]).
  final String? email;

  /// Position in the escalation queue — lower value = notified sooner.
  final int priority;

  /// When false, this responder is skipped during emergency response.
  final bool isEnabled;

  /// Seconds the engine waits for acknowledgement before escalating.
  final int acknowledgementTimeoutSeconds;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true if this responder has the minimum data needed for at
  /// least one notification method.
  bool get isActionable {
    if (notificationMethods.isEmpty) return false;
    if (notificationMethods.any((m) => m.requiresPhone) &&
        (phoneNumber == null || phoneNumber!.isEmpty)) {
      return false;
    }
    if (notificationMethods.any((m) => m.requiresEmail) &&
        (email == null || email!.isEmpty)) {
      return false;
    }
    return true;
  }

  Responder copyWith({
    String? id,
    String? name,
    ResponderType? type,
    List<NotificationMethod>? notificationMethods,
    String? phoneNumber,
    String? email,
    int? priority,
    bool? isEnabled,
    int? acknowledgementTimeoutSeconds,
  }) {
    return Responder(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      notificationMethods: notificationMethods ?? this.notificationMethods,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      priority: priority ?? this.priority,
      isEnabled: isEnabled ?? this.isEnabled,
      acknowledgementTimeoutSeconds:
          acknowledgementTimeoutSeconds ?? this.acknowledgementTimeoutSeconds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        notificationMethods,
        phoneNumber,
        email,
        priority,
        isEnabled,
        acknowledgementTimeoutSeconds,
      ];
}
