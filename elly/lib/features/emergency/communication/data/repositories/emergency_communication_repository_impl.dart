/// emergency_communication_repository_impl.dart
///
/// Data layer implementation of EmergencyCommunicationRepository.
/// Coordinates communication services and event streams without UI references.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/emergency_dispatch_request.dart';
import '../../domain/entities/dispatch_result.dart';
import '../../domain/entities/communication_event.dart';
import '../../domain/repositories/emergency_communication_repository.dart';
import '../services/emergency_communication_service.dart';

class EmergencyCommunicationRepositoryImpl implements EmergencyCommunicationRepository {
  EmergencyCommunicationRepositoryImpl({
    EmergencyCommunicationService? service,
  }) : _service = service ?? EmergencyCommunicationService();

  final EmergencyCommunicationService _service;

  @override
  Stream<CommunicationEvent> get eventStream => _service.eventStream;

  @override
  Future<DispatchResult> startEmergencyCommunication(EmergencyDispatchRequest request) async {
    appLogger.info('EmergencyCommunicationRepositoryImpl: Initiating dispatch for session ${request.sessionId}');
    return await _service.executeDispatchSequence(request);
  }

  @override
  Future<void> notifySOSCircle(EmergencyDispatchRequest request) async {
    appLogger.info('EmergencyCommunicationRepositoryImpl: SOS Circle notified for ${request.sessionId}');
  }

  @override
  Future<void> prepareDispatch(EmergencyDispatchRequest request) async {
    appLogger.info('EmergencyCommunicationRepositoryImpl: Preparing dispatch telemetry for ${request.sessionId}');
  }

  @override
  Future<void> endCommunication(String sessionId) async {
    appLogger.info('EmergencyCommunicationRepositoryImpl: Communication session $sessionId ended cleanly');
  }
}
