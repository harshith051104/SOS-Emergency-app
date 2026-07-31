/// phone_call_action.dart
///
/// Production implementation of [EmergencyAction] for launching the native
/// phone dialer to the resolved regional emergency number (112/911/999/000)
/// using the [EmergencyDialerService] via url_launcher.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/communication/data/services/emergency_dialer_service.dart';
import '../../domain/entities/action_result.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/interfaces/emergency_action.dart';

class PhoneCallAction implements EmergencyAction {
  PhoneCallAction({EmergencyDialerService? dialerService})
      : _dialerService = dialerService ?? const EmergencyDialerService();

  final EmergencyDialerService _dialerService;

  @override
  String get actionId => 'phone_call';

  @override
  String get actionName => 'Initiate Emergency Phone Call';

  @override
  Future<ActionResult> execute(EmergencySessionRequest request) async {
    final sw = Stopwatch()..start();

    // Use the emergency number from the session profile if available,
    // otherwise fall back to the global standard 112.
    final emergencyNumber =
        (request.emergencyProfile['emergencyNumber'] as String?)?.trim() ??
            '112';

    bool launched = false;
    String resultMessage;

    try {
      appLogger.info(
          'PhoneCallAction: Launching dialer for $emergencyNumber');
      launched = await _dialerService.launchDialer(emergencyNumber);
      resultMessage = launched
          ? 'Native dialer launched for $emergencyNumber.'
          : 'Dialer could not be launched for $emergencyNumber on this device.';
    } catch (e, st) {
      appLogger.error('PhoneCallAction: Dialer launch failed', e, st);
      launched = false;
      resultMessage = 'Phone call failed: ${e.toString()}';
    }

    sw.stop();
    return ActionResult(
      actionId: actionId,
      actionName: actionName,
      success: launched,
      message: resultMessage,
      executionTimeMs: sw.elapsedMilliseconds,
      timestamp: DateTime.now(),
    );
  }
}
