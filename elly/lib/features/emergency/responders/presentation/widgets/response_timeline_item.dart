/// response_timeline_item.dart
///
/// A single step in the live response status timeline.
/// Rendered in [ResponseStatusPage]'s scrollable list.

library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/response_engine_update.dart';
import '../../domain/enums/response_update_type.dart';

/// Animated timeline row for a [ResponseEngineUpdate].
class ResponseTimelineItem extends StatefulWidget {
  const ResponseTimelineItem({
    required this.update,
    required this.isLast,
    super.key,
  });

  final ResponseEngineUpdate update;
  final bool isLast;

  @override
  State<ResponseTimelineItem> createState() => _ResponseTimelineItemState();
}

class _ResponseTimelineItemState extends State<ResponseTimelineItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final update = widget.update;
    final color = _color(update.type);
    final icon = _icon(update.type);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timeline line + dot ───────────────────────────────────
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (!widget.isLast)
                    Container(
                      width: 2,
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Responder name (if applicable).
                      if (update.responder != null) ...[
                        Text(
                          update.responder!.name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],

                      // Event message.
                      if (update.message != null)
                        Text(
                          update.message!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),

                      // Timestamp.
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(update.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _color(ResponseUpdateType type) {
    switch (type) {
      case ResponseUpdateType.started:
      case ResponseUpdateType.generatingSummary:
        return const Color(0xFF6366F1); // indigo
      case ResponseUpdateType.notifying:
        return const Color(0xFFF59E0B); // amber
      case ResponseUpdateType.notified:
        return widget.update.success == true
            ? AppColors.successGreen
            : AppColors.sosPrimary;
      case ResponseUpdateType.acknowledged:
        return AppColors.successGreen;
      case ResponseUpdateType.timedOut:
        return const Color(0xFFF59E0B); // amber
      case ResponseUpdateType.escalating:
        return const Color(0xFFEC4899); // pink
      case ResponseUpdateType.completed:
        return widget.update.success == true
            ? AppColors.successGreen
            : const Color(0xFF64748B);
      case ResponseUpdateType.failed:
        return AppColors.sosPrimary;
      case ResponseUpdateType.cancelled:
        return const Color(0xFF64748B); // slate
    }
  }

  IconData _icon(ResponseUpdateType type) {
    switch (type) {
      case ResponseUpdateType.started:
        return Icons.play_circle_outlined;
      case ResponseUpdateType.generatingSummary:
        return Icons.description_outlined;
      case ResponseUpdateType.notifying:
        return Icons.send_outlined;
      case ResponseUpdateType.notified:
        return widget.update.success == true
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded;
      case ResponseUpdateType.acknowledged:
        return Icons.verified_rounded;
      case ResponseUpdateType.timedOut:
        return Icons.timer_off_outlined;
      case ResponseUpdateType.escalating:
        return Icons.arrow_circle_up_outlined;
      case ResponseUpdateType.completed:
        return Icons.flag_outlined;
      case ResponseUpdateType.failed:
        return Icons.cancel_outlined;
      case ResponseUpdateType.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}
