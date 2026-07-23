/// responder_section.dart
///
/// Part of the versioned Emergency Data Packet.
/// Contains responder notification tracking properties.

library;

import 'package:equatable/equatable.dart';

enum ResponderNotificationStatus {
  pending,
  notified,
  accepted,
  timedOut,
}

class EmergencyResponder extends Equatable {
  const EmergencyResponder({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.notificationStatus,
    required this.isAcknowledged,
    this.acknowledgedTime,
  });

  final String id;
  final String name;
  final String relationship;
  final String phone;
  final ResponderNotificationStatus notificationStatus;
  final bool isAcknowledged;
  final DateTime? acknowledgedTime;

  EmergencyResponder copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phone,
    ResponderNotificationStatus? notificationStatus,
    bool? isAcknowledged,
    DateTime? acknowledgedTime,
  }) {
    return EmergencyResponder(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedTime: acknowledgedTime ?? this.acknowledgedTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        relationship,
        phone,
        notificationStatus,
        isAcknowledged,
        acknowledgedTime,
      ];
}

class ResponderSection extends Equatable {
  const ResponderSection({
    required this.responders,
  });

  final List<EmergencyResponder> responders;

  ResponderSection copyWith({
    List<EmergencyResponder>? responders,
  }) {
    return ResponderSection(
      responders: responders ?? this.responders,
    );
  }

  @override
  List<Object?> get props => [responders];
}
