/// communication_channel.dart
///
/// Abstract provider-agnostic interface for emergency dispatch channels (SMS, Phone Call, Email, Push Notification).

library;

import 'package:elly/features/emergency/communication/domain/entities/communication_request.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_result.dart';

abstract class CommunicationChannel {
  String get channelType;
  Future<bool> isAvailable();
  Future<CommunicationResult> send(CommunicationRequest request);
}
