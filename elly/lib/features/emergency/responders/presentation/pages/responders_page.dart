/// responders_page.dart
///
/// Settings screen for managing emergency responders.
/// Features:
///   - ReorderableListView with drag-and-drop ordering
///   - Delete via popup menu with confirmation dialog
///   - FAB to add new responder
///   - Empty state with CTA

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/responder_providers.dart';
import '../widgets/responder_card.dart';

/// Displays all configured responders with drag-and-drop ordering.
class RespondersPage extends ConsumerWidget {
  const RespondersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(respondersControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Responders'),
        centerTitle: false,
        actions: [
          // Info button explaining the priority order.
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About priority order',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),

      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return _ErrorView(
              message: state.error!,
              onRetry: () =>
                  ref.read(respondersControllerProvider.notifier).loadResponders(),
            );
          }

          if (state.responders.isEmpty) {
            return _EmptyState(
              onAdd: () => context.push(AppRoutes.respondersAdd),
            );
          }

          return Column(
            children: [
              // ── Drag hint ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_indicator_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Drag to set notification priority order',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Reorderable list ──────────────────────────────────────
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  buildDefaultDragHandles: false,
                  itemCount: state.responders.length,
                  itemBuilder: (context, index) {
                    final responder = state.responders[index];
                    return ResponderCard(
                      key: ValueKey(responder.id),
                      responder: responder,
                      onEdit: () => context.push(
                        AppRoutes.respondersEdit(responder.id),
                        extra: responder,
                      ),
                      onDelete: () =>
                          _confirmDelete(context, ref, responder.id, responder.name),
                    );
                  },
                  onReorderItem: (oldIndex, newIndex) {

                    ref
                        .read(respondersControllerProvider.notifier)
                        .reorder(oldIndex, newIndex);
                  },
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.respondersAdd),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Responder'),
        backgroundColor: AppColors.sosPrimary,
        foregroundColor: AppColors.sosOnPrimary,
      ),
    );
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Responder'),
        content: Text(
          'Remove "$name" from your emergency contacts?\n\n'
          'They will no longer be notified during an emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosPrimary,
              foregroundColor: AppColors.sosOnPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(respondersControllerProvider.notifier).deleteResponder(id);
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Priority Order'),
        content: const Text(
          'Responders are contacted from top to bottom.\n\n'
          '• The first person is notified immediately.\n'
          '• If they don\'t respond within the timeout, ELLY escalates to the next person.\n'
          '• Drag the ≡ handle to reorder.\n\n'
          'Emergency Services should typically be last — they always respond.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Responders Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add emergency contacts who will be notified '
              'when you activate SOS.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Your First Responder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sosPrimary,
                foregroundColor: AppColors.sosOnPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.sosPrimary),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
