/// offline_controller.dart
///
/// Master presentation controller for offline emergency mode, queue management, and synchronization.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/offline/domain/entities/offline_session.dart';
import 'package:elly/features/emergency/offline/domain/entities/pending_operation.dart';
import 'package:elly/features/emergency/offline/domain/entities/sync_result.dart';
import 'package:elly/features/emergency/offline/domain/repositories/offline_repository.dart';

class OfflineController extends StateNotifier<OfflineSession> {
  OfflineController(this._repository)
      : super(OfflineSession(
          sessionId: 'off_session_init',
          startedAt: DateTime.now(),
        )) {
    _init();
  }

  final OfflineRepository _repository;
  StreamSubscription<OfflineSession>? _sessionSub;

  Future<void> _init() async {
    appLogger.info('OfflineController: Initializing offline controller...');
    await _repository.initialize();
    _sessionSub = _repository.watchSession().listen((updatedSession) {
      if (!mounted) return;
      state = updatedSession;
    });
  }

  Future<void> enqueueOperation(PendingOperation op) async {
    appLogger.info('OfflineController: Enqueuing operation ${op.id}');
    await _repository.enqueue(op);
  }

  Future<SyncResult> retrySynchronization() async {
    appLogger.info('OfflineController: Manual retry synchronization requested');
    return await _repository.sync();
  }

  Future<void> clearQueue() async {
    appLogger.info('OfflineController: Clearing offline queue');
    await _repository.clear();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }
}
