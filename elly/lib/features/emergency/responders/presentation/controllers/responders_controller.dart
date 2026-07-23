/// responders_controller.dart
///
/// StateNotifier managing the list of emergency responders.
/// Handles load, add, edit, delete, and drag-and-drop reorder.

library;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/utils/app_logger.dart';

import '../../domain/entities/responder.dart';
import '../../domain/usecases/delete_responder_usecase.dart';
import '../../domain/usecases/get_responders_usecase.dart';
import '../../domain/usecases/reorder_responders_usecase.dart';
import '../../domain/usecases/save_responder_usecase.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class RespondersState extends Equatable {
  const RespondersState({
    this.responders = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Responder> responders;
  final bool isLoading;
  final String? error;

  RespondersState copyWith({
    List<Responder>? responders,
    bool? isLoading,
    String? error,
  }) {
    return RespondersState(
      responders: responders ?? this.responders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [responders, isLoading, error];
}

// ── Controller ────────────────────────────────────────────────────────────────

class RespondersController extends StateNotifier<RespondersState> {
  RespondersController({
    required GetRespondersUseCase getRespondersUseCase,
    required SaveResponderUseCase saveResponderUseCase,
    required DeleteResponderUseCase deleteResponderUseCase,
    required ReorderRespondersUseCase reorderRespondersUseCase,
  })  : _getRespondersUseCase = getRespondersUseCase,
        _saveResponderUseCase = saveResponderUseCase,
        _deleteResponderUseCase = deleteResponderUseCase,
        _reorderRespondersUseCase = reorderRespondersUseCase,
        super(const RespondersState()) {
    // Load responders immediately on construction.
    loadResponders();
  }

  final GetRespondersUseCase _getRespondersUseCase;
  final SaveResponderUseCase _saveResponderUseCase;
  final DeleteResponderUseCase _deleteResponderUseCase;
  final ReorderRespondersUseCase _reorderRespondersUseCase;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Loads all responders from the repository.
  Future<void> loadResponders() async {
    state = state.copyWith(isLoading: true);
    try {
      final responders = await _getRespondersUseCase();
      if (mounted) state = state.copyWith(responders: responders, isLoading: false);
    } on Exception catch (e, st) {
      appLogger.error('RespondersController: loadResponders failed', e, st);
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load responders.',
        );
      }
    }
  }

  /// Inserts or updates a responder.
  Future<void> saveResponder(Responder responder) async {
    try {
      await _saveResponderUseCase(responder);
      await loadResponders();
    } on Exception catch (e, st) {
      appLogger.error('RespondersController: saveResponder failed', e, st);
      if (mounted) state = state.copyWith(error: 'Failed to save responder.');
    }
  }

  /// Permanently removes a responder by ID.
  Future<void> deleteResponder(String id) async {
    try {
      await _deleteResponderUseCase(id);
      await loadResponders();
    } on Exception catch (e, st) {
      appLogger.error('RespondersController: deleteResponder failed', e, st);
      if (mounted) state = state.copyWith(error: 'Failed to delete responder.');
    }
  }

  /// Reorders responders based on new indices from [ReorderableListView].
  ///
  /// Flutter's [ReorderableListView.onReorder] provides (oldIndex, newIndex).
  Future<void> reorder(int oldIndex, int newIndex) async {
    // Flutter quirk: newIndex needs adjustment when moving down.
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;

    final list = [...state.responders];
    final moved = list.removeAt(oldIndex);
    list.insert(adjusted, moved);

    // Optimistic update for instant UI feedback.
    if (mounted) state = state.copyWith(responders: list);

    try {
      await _reorderRespondersUseCase(list.map((r) => r.id).toList());
    } on Exception catch (e, st) {
      appLogger.error('RespondersController: reorder failed', e, st);
      // Rollback on failure.
      await loadResponders();
    }
  }
}
