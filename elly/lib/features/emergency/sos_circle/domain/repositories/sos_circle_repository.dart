/// sos_circle_repository.dart
///
/// Abstract repository contract for SOS Circle management and notification dispatching.

library;

import 'package:elly/features/emergency/sos_circle/domain/entities/emergency_contact.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_circle.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_notification_request.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_notification_result.dart';
import 'package:elly/features/emergency/sos_circle/domain/validation/sos_circle_validator.dart';


abstract class SOSCircleRepository {
  Future<List<EmergencyContact>> getContacts();
  Future<SOSCircle> getSOSCircle();
  Future<void> saveContact(EmergencyContact contact);
  Future<void> updateContact(EmergencyContact contact);
  Future<void> deleteContact(String id);
  Future<SOSNotificationResult> notifyContacts(SOSNotificationRequest request);
  ValidationResult validateContacts(List<EmergencyContact> contacts);
}
