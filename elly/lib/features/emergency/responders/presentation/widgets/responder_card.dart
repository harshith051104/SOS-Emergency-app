/// responder_card.dart
///
/// A draggable list tile for a single [Responder] in the [RespondersPage].
/// Shows type icon, name, notification method chips, and edit/delete actions.

library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/responder.dart';
import '../../domain/enums/notification_method.dart';
import '../../domain/enums/responder_type.dart';

/// Card widget displaying a responder in the reorderable list.
class ResponderCard extends StatelessWidget {
  const ResponderCard({
    required this.responder,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Responder responder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            // ── Drag handle ────────────────────────────────────────────
            ReorderableDragStartListener(
              index: responder.priority,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),

            // ── Type icon ──────────────────────────────────────────────
            _TypeAvatar(type: responder.type),
            const SizedBox(width: 12),

            // ── Name + chips ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          responder.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!responder.isEnabled) ...[
                        const SizedBox(width: 6),
                        _DisabledBadge(),
                      ],
                    ],
                  ),
                  if (responder.phoneNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      responder.phoneNumber!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: responder.notificationMethods
                        .map((m) => _MethodChip(method: m))
                        .toList(),
                  ),
                ],
              ),
            ),

            // ── Edit / Delete ──────────────────────────────────────────
            PopupMenuButton<_CardAction>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (action) {
                switch (action) {
                  case _CardAction.edit:
                    onEdit();
                  case _CardAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _CardAction.edit,
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: _CardAction.delete,
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.sosPrimary,
                    ),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.sosPrimary),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

enum _CardAction { edit, delete }

class _TypeAvatar extends StatelessWidget {
  const _TypeAvatar({required this.type});
  final ResponderType type;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: _bgColor(type).withValues(alpha: 0.12),
      child: Icon(_icon(type), color: _bgColor(type), size: 22),
    );
  }

  Color _bgColor(ResponderType type) {
    switch (type) {
      case ResponderType.family:
        return const Color(0xFF7B61FF);
      case ResponderType.caregiver:
        return const Color(0xFF00A884);
      case ResponderType.doctor:
        return const Color(0xFF1976D2);
      case ResponderType.hospital:
        return const Color(0xFF0288D1);
      case ResponderType.emergencyService:
        return AppColors.sosPrimary;
    }
  }

  IconData _icon(ResponderType type) {
    switch (type) {
      case ResponderType.family:
        return Icons.family_restroom_rounded;
      case ResponderType.caregiver:
        return Icons.support_agent_rounded;
      case ResponderType.doctor:
        return Icons.medical_services_outlined;
      case ResponderType.hospital:
        return Icons.local_hospital_outlined;
      case ResponderType.emergencyService:
        return Icons.emergency_rounded;
    }
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method});
  final NotificationMethod method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        method.shortName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DisabledBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Disabled',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey,
            ),
      ),
    );
  }
}
