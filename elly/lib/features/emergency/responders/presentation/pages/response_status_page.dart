/// response_status_page.dart
///
/// Live emergency response status timeline.
/// Auto-starts the engine when the page mounts.
/// Auto-scrolls as new events arrive.
///
/// Triggered from [EmergencyActivatedPage] → /emergency/response-status

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../sos/presentation/providers/emergency_providers.dart';
import '../../domain/enums/response_update_type.dart';
import '../providers/responder_providers.dart';
import '../widgets/response_timeline_item.dart';

/// Shows the live timeline of the emergency response engine execution.
class ResponseStatusPage extends ConsumerStatefulWidget {
  const ResponseStatusPage({super.key});

  @override
  ConsumerState<ResponseStatusPage> createState() => _ResponseStatusPageState();
}

class _ResponseStatusPageState extends ConsumerState<ResponseStatusPage> {
  final _scrollController = ScrollController();
  bool _engineStarted = false;

  @override
  void initState() {
    super.initState();
    // Start engine after first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startEngine());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startEngine() {
    if (_engineStarted) return;
    _engineStarted = true;

    final event = ref.read(activeEmergencyEventProvider);
    if (event == null) {
      // Fallback: no active event (e.g., navigated here directly in dev).
      return;
    }
    final category = ref.read(emergencyControllerProvider).selectedCategory;
    ref.read(responseEngineControllerProvider.notifier).start(event, category: category);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engineState = ref.watch(responseEngineControllerProvider);

    // Auto-scroll whenever new updates arrive.
    ref.listen(responseEngineControllerProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    final updates = engineState.updates;
    final isRunning = engineState.isRunning;
    final isCompleted = engineState.isCompleted;

    // Determine overall status for the header.
    final lastType = updates.isNotEmpty ? updates.last.type : null;
    final wasAcknowledged = updates.any(
      (u) => u.type == ResponseUpdateType.acknowledged,
    );

    return PopScope(
      canPop: isCompleted || !isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isRunning) {
          _showCancelConfirmation(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Response Status'),
          centerTitle: false,
          leading: BackButton(
            onPressed: isRunning
                ? () => _showCancelConfirmation(context)
                : () => Navigator.of(context).pop(),
          ),
          actions: [
            if (isRunning)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sosPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.sosPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        body: Column(
          children: [
            // ── Status header banner ────────────────────────────────────
            _StatusBanner(
              isRunning: isRunning,
              isCompleted: isCompleted,
              wasAcknowledged: wasAcknowledged,
              lastType: lastType,
              summary: engineState.emergencySummary,
            ),

            // ── Timeline ────────────────────────────────────────────────
            Expanded(
              child: updates.isEmpty
                  ? const _WaitingIndicator()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      itemCount: updates.length,
                      itemBuilder: (context, index) {
                        return ResponseTimelineItem(
                          key: ValueKey('${updates[index].timestamp.millisecondsSinceEpoch}_$index'),
                          update: updates[index],
                          isLast: index == updates.length - 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _showCancelConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Response?'),
        content: const Text(
          'The emergency response engine is still running.\n\n'
          'Leaving will stop notifications. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Running'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosPrimary,
              foregroundColor: AppColors.sosOnPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop & Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.isRunning,
    required this.isCompleted,
    required this.wasAcknowledged,
    required this.lastType,
    this.summary,
  });

  final bool isRunning;
  final bool isCompleted;
  final bool wasAcknowledged;
  final ResponseUpdateType? lastType;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bannerColor;
    String bannerLabel;
    IconData bannerIcon;

    if (isRunning) {
      bannerColor = const Color(0xFFF59E0B);
      bannerLabel = 'Notifying responders…';
      bannerIcon = Icons.notifications_active_rounded;
    } else if (wasAcknowledged) {
      bannerColor = AppColors.successGreen;
      bannerLabel = 'Help is on the way';
      bannerIcon = Icons.verified_rounded;
    } else if (lastType == ResponseUpdateType.failed) {
      bannerColor = AppColors.sosPrimary;
      bannerLabel = 'Response failed';
      bannerIcon = Icons.error_outline_rounded;
    } else if (isCompleted) {
      bannerColor = const Color(0xFF64748B);
      bannerLabel = 'All responders notified';
      bannerIcon = Icons.flag_outlined;
    } else {
      bannerColor = const Color(0xFF6366F1);
      bannerLabel = 'Starting engine…';
      bannerIcon = Icons.play_circle_outlined;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: bannerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: 18),
              const SizedBox(width: 8),
              Text(
                bannerLabel.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: bannerColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bannerColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bannerColor.withValues(alpha: 0.15)),
              ),
              child: Text(
                summary!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaitingIndicator extends StatelessWidget {
  const _WaitingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.sosPrimary),
          SizedBox(height: 16),
          Text('Initialising response engine…'),
        ],
      ),
    );
  }
}
