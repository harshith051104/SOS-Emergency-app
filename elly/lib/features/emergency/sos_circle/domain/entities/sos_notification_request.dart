/// sos_notification_request.dart
///
/// Immutable domain request payload for orchestrating SOS Circle notifications.

library;

import 'package:flutter/foundation.dart';
import 'emergency_contact.dart';

@immutable
class SOSNotificationRequest {
  const SOSNotificationRequest({
    required this.dispatchId,
    required this.sessionId,
    required this.emergencyType,
    required this.selectedService,
    required this.triggeredAt,
    required this.contacts,
    this.currentLocation,
    this.healthPassportReference,
  });

  final String dispatchId;
  final String sessionId;
  final String emergencyType;
  final String selectedService;
  final DateTime triggeredAt;
  final List<EmergencyContact> contacts;
  final String? currentLocation;
  final String? healthPassportReference;
}
