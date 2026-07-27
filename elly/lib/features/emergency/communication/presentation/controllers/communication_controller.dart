/// communication_controller.dart
///
/// StateNotifier controller managing CommunicationResult history and dispatch actions.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_request.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_result.dart';
import 'package:elly/features/emergency/communication/domain/services/communication_engine.dart';

class CommunicationController extends StateNotifier<CommunicationResult?> {
  CommunicationController(this._engine) : super(null);

  final CommunicationEngine _engine;

  Future<CommunicationResult> sendAlert(CommunicationRequest request) async {
    final result = await _engine.dispatch(request);
    state = result;
    return result;
  }

  // Alias method for backwards compatibility with legacy emergency activation flows
  Future<CommunicationResult> executeDispatch(CommunicationRequest request) async {
    return sendAlert(request);
  }

  // Reset method for backwards compatibility
  void reset() {
    state = null;
  }
}
