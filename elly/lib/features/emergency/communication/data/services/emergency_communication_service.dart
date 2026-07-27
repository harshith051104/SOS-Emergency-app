/// emergency_communication_service.dart
///
/// Core communication service orchestrating sequential preparation steps,
/// native dialer execution, and future plug-in hooks for SMS and Internet dispatches.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/emergency_dispatch_request.dart';
import '../../domain/entities/dispatch_result.dart';
import '../../domain/entities/communication_event.dart';
import 'emergency_dialer_service.dart';

class EmergencyCommunicationService {
  EmergencyCommunicationService({
    EmergencyDialerService? dialerService,
  }) : _dialerService = dialerService ?? const EmergencyDialerService();

  final EmergencyDialerService _dialerService;
  final _eventController = StreamController<CommunicationEvent>.broadcast();

  Stream<CommunicationEvent> get eventStream => _eventController.stream;

  /// Executes sequential preparation and initiates emergency phone dialer.
  Future<DispatchResult> executeDispatchSequence(EmergencyDispatchRequest request) async {
    appLogger.info('EmergencyCommunicationService: Starting dispatch sequence for Session ${request.sessionId}');

    // Step 1: Initializing Engine
    _eventController.add(DispatchPreparingEvent(request: request, stepName: 'Initializing Monitoring Engine'));
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 2: Compiling Telemetry Packet
    _eventController.add(DispatchPreparingEvent(request: request, stepName: 'Compiling Telemetry Packet'));
    await Future.delayed(const Duration(milliseconds: 350));

    // Step 3: Selecting Communication Channel
    _eventController.add(DispatchPreparingEvent(request: request, stepName: 'Selecting Communication Channel'));
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 4: Future Extension Hooks (Future SMS & Internet Plug-ins)
    await _executeFutureSMSHook(request);
    await _executeFutureBackendHook(request);

    // Step 5: Launch Phone Dialer
    _eventController.add(DialerLaunchingEvent(emergencyNumber: request.selectedEmergencyNumber));
    appLogger.info('EmergencyCommunicationService: Launching dialer for ${request.selectedEmergencyNumber}');

    final dialerSuccess = await _dialerService.launchDialer(request.selectedEmergencyNumber);

    if (dialerSuccess) {
      _eventController.add(DialerLaunchedEvent(emergencyNumber: request.selectedEmergencyNumber));
      
      final result = DispatchResult.successResult(
        emergencyNumber: request.selectedEmergencyNumber,
      );

      _eventController.add(DispatchCompletedEvent(result: result));
      _eventController.add(EmergencySessionStartedEvent(sessionId: request.sessionId));
      
      appLogger.info('EmergencyCommunicationService: Dispatch SUCCESS for ${request.selectedEmergencyNumber}');
      return result;
    } else {
      final failureReason = 'Platform unable to launch emergency phone dialer for ${request.selectedEmergencyNumber}';
      _eventController.add(DispatchFailedEvent(reason: failureReason, emergencyNumber: request.selectedEmergencyNumber));
      
      appLogger.error('EmergencyCommunicationService: Dispatch FAILED for ${request.selectedEmergencyNumber}');
      return DispatchResult.failureResult(
        emergencyNumber: request.selectedEmergencyNumber,
        reason: failureReason,
      );
    }
  }

  /// Future Plug-in Hook: SMS Integration (Sprint 6+)
  Future<void> _executeFutureSMSHook(EmergencyDispatchRequest request) async {
    // Extensible hook for background SMS dispatch to SOS Circle
    appLogger.info('EmergencyCommunicationService [Hook]: SMS dispatch ready for future implementation');
  }

  /// Future Plug-in Hook: Backend API / Live Internet Dispatch (Sprint 6+)
  Future<void> _executeFutureBackendHook(EmergencyDispatchRequest request) async {
    // Extensible hook for HTTPS/WebSocket telemetry dispatch to ELLY cloud backend
    appLogger.info('EmergencyCommunicationService [Hook]: Internet telemetry dispatch ready for future implementation');
  }

  void dispose() {
    _eventController.close();
  }
}
