/// response_engine_controller.dart
///
/// StateNotifier that manages a live emergency response execution.
/// Subscribes to the [TriggerResponseUseCase] stream and accumulates
/// [ResponseEngineUpdate] events into a timeline for the UI.

library;

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/utils/app_logger.dart';

import '../../domain/entities/response_engine_update.dart';
import '../../domain/enums/response_update_type.dart';
import '../../domain/usecases/trigger_response_usecase.dart';
import '../../../sos/domain/entities/emergency_event.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ResponseEngineState extends Equatable {
  const ResponseEngineState({
    this.updates = const [],
    this.isRunning = false,
    this.isCompleted = false,
    this.emergencySummary,
  });

  /// Chronological list of engine events — rendered as a timeline.
  final List<ResponseEngineUpdate> updates;

  /// True while the engine stream is open.
  final bool isRunning;

  /// True after a terminal event (completed / failed / cancelled).
  final bool isCompleted;

  /// The generated emergency summary, extracted from the stream.
  final String? emergencySummary;

  ResponseEngineState copyWith({
    List<ResponseEngineUpdate>? updates,
    bool? isRunning,
    bool? isCompleted,
    String? emergencySummary,
  }) {
    return ResponseEngineState(
      updates: updates ?? this.updates,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      emergencySummary: emergencySummary ?? this.emergencySummary,
    );
  }

  @override
  List<Object?> get props =>
      [updates, isRunning, isCompleted, emergencySummary];
}

// ── Controller ────────────────────────────────────────────────────────────────

class ResponseEngineController extends StateNotifier<ResponseEngineState> {
  ResponseEngineController({required TriggerResponseUseCase triggerResponseUseCase})
      : _triggerResponseUseCase = triggerResponseUseCase,
        super(const ResponseEngineState());

  final TriggerResponseUseCase _triggerResponseUseCase;
  StreamSubscription<ResponseEngineUpdate>? _subscription;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> start(EmergencyEvent event, {String? category}) async {
    // Cancel any previous run.
    await _subscription?.cancel();
    _subscription = null;

    if (!mounted) return;

    state = const ResponseEngineState(isRunning: true);
    appLogger.info('ResponseEngineController: starting for event ${event.id} with category $category');

    final stream = _triggerResponseUseCase(event, category: category);

    _subscription = stream.listen(
      (update) {
        if (!mounted) return;

        final updatedList = [...state.updates, update];

        // Extract the emergency summary when it is generated.
        final summary = update.type == ResponseUpdateType.generatingSummary
            ? update.message
            : state.emergencySummary;

        final isTerminal = update.type.isTerminal;

        state = state.copyWith(
          updates: updatedList,
          emergencySummary: summary,
          isRunning: !isTerminal,
          isCompleted: isTerminal,
        );

        if (isTerminal) {
          appLogger.info(
            'ResponseEngineController: terminal event received — ${update.type}',
          );
        }
      },
      onError: (Object e, StackTrace st) {
        appLogger.error('ResponseEngineController: stream error', e, st);
        if (mounted) {
          state = state.copyWith(
            isRunning: false,
            isCompleted: true,
            updates: [
              ...state.updates,
              ResponseEngineUpdate.failed('Unexpected engine error: $e'),
            ],
          );
        }
      },
      onDone: () {
        if (mounted && !state.isCompleted) {
          state = state.copyWith(isRunning: false, isCompleted: true);
        }
      },
    );
  }

  /// Clears the state so the controller is ready for the next emergency.
  void reset() {
    _subscription?.cancel();
    _subscription = null;
    if (mounted) state = const ResponseEngineState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
