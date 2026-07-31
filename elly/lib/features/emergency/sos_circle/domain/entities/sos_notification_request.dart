/// sos_notification_request.dart
///
/// Immutable domain request payload for orchestrating SOS Circle notifications.

library;

import 'package:flutter/foundation.dart';
import 'emergency_contact.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_data_packet.dart';

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
    this.emergencyPacket,
  });

  final String dispatchId;
  final String sessionId;
  final String emergencyType;
  final String selectedService;
  final DateTime triggeredAt;
  final List<EmergencyContact> contacts;
  final String? currentLocation;
  final String? healthPassportReference;

  /// Full real-time emergency data packet built by the backend engines.
  /// When provided, the SMS channel uses this for rich, accurate data.
  final EmergencyDataPacket? emergencyPacket;
}
