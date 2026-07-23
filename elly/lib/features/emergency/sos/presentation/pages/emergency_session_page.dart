/// emergency_session_page.dart
///
/// The central live Emergency Session Dashboard.
/// Displays the elapsed timer, session ID, ELLY Live Assistant,
/// responder status cards, location shared info, and emergency control panel.
/// Also features sliding sheets for detailed Packet details and Live Timelines.

library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/enums/emergency_status.dart';
import '../controllers/emergency_controller.dart';
import '../providers/emergency_providers.dart';
import '../../domain/entities/emergency_session.dart';
import '../../../assistant/presentation/widgets/assistant_wave_indicator.dart';
import '../../../assistant/presentation/providers/assistant_ui_providers.dart';
import '../../../assistant/domain/entities/assistant_state.dart';
import '../../../packet/presentation/providers/packet_providers.dart';
import '../../../packet/presentation/controllers/packet_controller.dart';

class EmergencySessionPage extends ConsumerStatefulWidget {
  const EmergencySessionPage({super.key});

  @override
  ConsumerState<EmergencySessionPage> createState() => _EmergencySessionPageState();
}

class _EmergencySessionPageState extends ConsumerState<EmergencySessionPage> {

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controllerState = ref.read(emergencyControllerProvider);
      final category = controllerState.selectedCategory ?? controllerState.activeEvent?.type.name;
      ref.read(assistantControllerProvider.notifier).startContinuousSession(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final controllerState = ref.watch(emergencyControllerProvider);
    final session = controllerState.activeSession;

    // Connect packet telemetry updates directly to ELLY Live Assistant Brain.
    // Use unconditional ref.listen so Riverpod correctly manages the subscription
    // lifecycle across builds. The guard was incorrectly removing the listener
    // on every non-registering build (Riverpod removes listeners not called in
    // the current build).
    if (session != null) {
      ref.listen<EmergencyPacketState>(
        packetControllerProvider(session.sessionId),
        (previous, next) {
          if (!mounted) return;
          if (next.packet != null) {
            final packet = next.packet!;
            // Defer all brain processing to post-frame to guarantee it never
            // fires during an in-progress layout or build pass.
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final assistantNotifier = ref.read(assistantControllerProvider.notifier);
              assistantNotifier.brain.processBatteryUpdate(packet.device.batteryPercent);
              assistantNotifier.brain.processLocationUpdate(
                address: packet.location.address,
                accuracy: packet.location.accuracy,
              );
              if (next.buildingProgress >= 6) {
                assistantNotifier.brain.processPacketCompleted();
              }
            });
          }
        },
      );
    }

    // Listen for state change to navigate to complete report screen
    ref.listen<EmergencyControllerState>(
      emergencyControllerProvider,
      (previous, next) {
        if (!context.mounted) return;
        if (next.status == EmergencyStatus.sessionCompleted) {
          context.go(AppRoutes.emergencyComplete);
        }
      },
    );

    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasAck = session.responderStatuses.any((s) => s.state == ResponderSessionState.accepted);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar (End Emergency Button) ──────────────────────────
              _SessionTopBar(
                onCancel: () => _confirmEndSession(context),
                isDark: isDark,
              ),

              // ── Main scrollable body ──────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Progress tracker (Started ➜ Notified ➜ Acknowledged)
                    _ProgressHeader(
                      hasAck: hasAck,
                      hasNotified: session.responderStatuses.any((s) => s.state == ResponderSessionState.notified),
                    ),
                    const SizedBox(height: 18),

                    // ELLY AI Live Assistant Speech bubble
                    // NOTE: ListView already wraps each child in RepaintBoundary
                    // via SliverChildDelegate (addRepaintBoundaries: true).
                    // Adding a second RepaintBoundary here caused child!==null
                    // during SliverList reconciliation → Null check operator storm.
                    _EllyAssistantPanel(
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    // Responders Status Card
                    _RespondersStatusCard(
                      statuses: session.responderStatuses,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),

              // ── Bottom Panel (Timer Display) ──────────────────────────
              _SessionBottomTimerPanel(
                formattedDuration: controllerState.formattedDuration,
                sessionId: session.sessionId,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirm Ending Emergency Session ──────────────────────────────────────

  Future<void> _confirmEndSession(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 56,
                color: AppColors.sosPrimary,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ending the emergency will notify all responders that you are safe.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Continue Emergency'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sosPrimary,
                        foregroundColor: AppColors.sosOnPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('End Emergency'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await ref.read(assistantControllerProvider.notifier).stopContinuousSession();
      await ref.read(emergencyControllerProvider.notifier).endEmergency();
    }
  }
}

// ── Private Sub-Widgets ──────────────────────────────────────────────────────

class _SessionTopBar extends StatelessWidget {
  const _SessionTopBar({
    required this.onCancel,
    required this.isDark,
  });

  final VoidCallback onCancel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Active emergency badge
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.sosPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVE SOS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.sosPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_rounded, size: 18),
            label: const Text('End Emergency'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosPrimary,
              foregroundColor: AppColors.sosOnPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(120, 44),
              elevation: 0,
            ),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.hasAck,
    required this.hasNotified,
  });

  final bool hasAck;
  final bool hasNotified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _buildStep(context, 'Started', true, true),
        _buildConnector(true),
        _buildStep(context, 'Notified', hasNotified || hasAck, hasNotified || hasAck),
        _buildConnector(hasAck),
        _buildStep(context, 'Acknowledged', hasAck, hasAck),
      ],
    );
  }

  Widget _buildStep(BuildContext context, String label, bool isActive, bool isVisited) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive
              ? AppColors.successGreen
              : isVisited
                  ? AppColors.successGreen.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant,
          child: isVisited
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? AppColors.successGreen : Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }
}

class _EllyAssistantPanel extends ConsumerStatefulWidget {
  const _EllyAssistantPanel({
    required this.isDark,
  });

  final bool isDark;

  @override
  ConsumerState<_EllyAssistantPanel> createState() => _EllyAssistantPanelState();
}

class _EllyAssistantPanelState extends ConsumerState<_EllyAssistantPanel> {
  final TextEditingController _textController = TextEditingController();
  bool _showTextSimulator = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendSimulatedText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    _textController.clear();
    ref.read(assistantControllerProvider.notifier).processInput(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assistantState = ref.watch(assistantControllerProvider);

    // Resolve current speech bubble text display
    String bubbleMessage = 'I am staying with you. How can I help you?';
    if (assistantState.state == AssistantState.speaking) {
      bubbleMessage = assistantState.activeTextSpeech;
    } else if (assistantState.messages.isNotEmpty) {
      // Find the last assistant message, or default
      final lastMsg = assistantState.messages.last;
      bubbleMessage = lastMsg.text;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark
              ? [AppColors.sosPrimary.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.2)]
              : [AppColors.sosPrimaryFaint, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.sosPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ELLY AI Dynamic Animated Pulse Indicator
              Column(
                children: [
                  AssistantWaveIndicator(state: assistantState.state),
                  const SizedBox(height: 4),
                  Text(
                    'ELLY AI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Conversation speechbubble area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASSISTANT LIVE — ${assistantState.state.name.toUpperCase()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.sosPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bubbleMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24, thickness: 0.5),

          // Voice and Text actions control panel
          Row(
            children: [
              // Toggle Text Input Simulator Button
              IconButton(
                icon: Icon(
                  _showTextSimulator ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _showTextSimulator = !_showTextSimulator;
                  });
                },
                tooltip: 'Toggle Text Input Simulator',
              ),

              // Dynamic Hands-Free Voice Status Container (No manual button press needed)
              // Microphone stays active automatically throughout the SOS session.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: assistantState.state == AssistantState.listening
                        ? AppColors.successGreen.withValues(alpha: 0.15)
                        : (assistantState.state == AssistantState.thinking || assistantState.state == AssistantState.transcribing)
                            ? Colors.blue.withValues(alpha: 0.15)
                            : AppColors.sosPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: assistantState.state == AssistantState.listening
                          ? AppColors.successGreen
                          : AppColors.sosPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        assistantState.state == AssistantState.listening
                            ? Icons.mic_rounded
                            : (assistantState.state == AssistantState.thinking || assistantState.state == AssistantState.transcribing)
                                ? Icons.psychology_rounded
                                : assistantState.state == AssistantState.speaking
                                    ? Icons.volume_up_rounded
                                    : Icons.graphic_eq_rounded,
                        size: 20,
                        color: assistantState.state == AssistantState.listening
                            ? AppColors.successGreen
                            : AppColors.sosPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          assistantState.state == AssistantState.listening
                              ? 'ELLY IS LISTENING...'
                              : (assistantState.state == AssistantState.thinking || assistantState.state == AssistantState.transcribing)
                                  ? 'ELLY IS THINKING...'
                                  : assistantState.state == AssistantState.speaking
                                      ? 'ELLY IS SPEAKING...'
                                      : 'ELLY HANDS-FREE ACTIVE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                            color: assistantState.state == AssistantState.listening
                                ? AppColors.successGreen
                                : (widget.isDark ? Colors.white : Colors.black87),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),

          // Collapsible Text Simulation Input Field (for developer testing)
          if (_showTextSimulator) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type prompt to ELLY...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendSimulatedText(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.sosPrimary),
                  onPressed: _sendSimulatedText,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RespondersStatusCard extends StatelessWidget {
  const _RespondersStatusCard({
    required this.statuses,
    required this.isDark,
  });

  final List<ResponderSessionStatus> statuses;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Responder Pipeline',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (statuses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for responders...',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...statuses.map((status) {
                final isNotified = status.state == ResponderSessionState.notified;
                final isAccepted = status.state == ResponderSessionState.accepted;
                final isTimedOut = status.state == ResponderSessionState.timedOut;

                Color stateColor = Colors.grey;
                String stateLabel = 'Pending';
                IconData stateIcon = Icons.radio_button_unchecked;

                if (isAccepted) {
                  stateColor = AppColors.successGreen;
                  stateLabel = '🟢 Connected & Alerted';
                  stateIcon = Icons.check_circle_rounded;
                } else if (isNotified) {
                  stateColor = const Color(0xFFF59E0B);
                  stateLabel = '🟡 Notified (Waiting ACK)';
                  stateIcon = Icons.hourglass_empty_rounded;
                } else if (isTimedOut) {
                  stateColor = AppColors.sosPrimary;
                  stateLabel = '🔴 Escalated (No ACK)';
                  stateIcon = Icons.error_rounded;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: stateColor.withValues(alpha: 0.12),
                              child: Icon(stateIcon, color: stateColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status.responder.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    status.responder.type.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        stateLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: stateColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.address,
    required this.accuracy,
    required this.isDark,
  });

  final String address;
  final String accuracy;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sosPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.sosPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Location Shared',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Accuracy: $accuracy',
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.successGreen, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  Updated Now',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoTile extends StatelessWidget {
  const _DetailInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionBottomTimerPanel extends StatelessWidget {
  const _SessionBottomTimerPanel({
    required this.formattedDuration,
    required this.sessionId,
    required this.isDark,
  });

  final String formattedDuration;
  final String sessionId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Duration label & Session ID
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SESSION DURATION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sessionId,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // Right: Large Live Timer Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.sosPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sosPrimary.withValues(alpha: 0.3)),
            ),
            child: Text(
              formattedDuration,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.sosPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
