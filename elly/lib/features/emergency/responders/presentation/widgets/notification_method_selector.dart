/// notification_method_selector.dart
///
/// Multi-select widget for choosing which notification channels to use
/// for a responder. Renders as a grid of toggle chips.

library;

import 'package:flutter/material.dart';

import '../../domain/enums/notification_method.dart';

/// Multi-select [FilterChip] group for [NotificationMethod].
class NotificationMethodSelector extends StatelessWidget {
  const NotificationMethodSelector({
    required this.selectedMethods,
    required this.onChanged,
    super.key,
  });

  final List<NotificationMethod> selectedMethods;
  final ValueChanged<List<NotificationMethod>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Methods',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select how ELLY contacts this person during an emergency.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NotificationMethod.values.map((method) {
            final isSelected = selectedMethods.contains(method);
            final isApi = method == NotificationMethod.api;

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icon(method),
                    size: 14,
                    color: isSelected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(method.displayName),
                  if (isApi) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Soon',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: isApi
                  ? null // API is disabled in Phase 1
                  : (_) => _toggle(method),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _toggle(NotificationMethod method) {
    final updated = [...selectedMethods];
    if (updated.contains(method)) {
      updated.remove(method);
    } else {
      updated.add(method);
    }
    onChanged(updated);
  }

  IconData _icon(NotificationMethod method) {
    switch (method) {
      case NotificationMethod.pushNotification:
        return Icons.notifications_outlined;
      case NotificationMethod.sms:
        return Icons.sms_outlined;
      case NotificationMethod.phoneCall:
        return Icons.call_outlined;
      case NotificationMethod.email:
        return Icons.email_outlined;
      case NotificationMethod.api:
        return Icons.api_outlined;
    }
  }
}
