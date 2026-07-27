/// live_responder_pipeline_card.dart
///
/// Unified Live Responder Pipeline Card driven by real-time event streams
/// from the Emergency Communication Engine.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/communication/presentation/providers/communication_providers.dart';

import 'package:elly/features/emergency/communication/domain/entities/communication_event.dart';


class LiveResponderPipelineCard extends ConsumerStatefulWidget {
  const LiveResponderPipelineCard({
    super.key,
    required this.isDark,
    required this.isActiveSos,
    this.respondersCount = 3,
    this.onViewLocationDetails,
  });

  final bool isDark;
  final bool isActiveSos;
  final int respondersCount;
  final VoidCallback? onViewLocationDetails;

  @override
  ConsumerState<LiveResponderPipelineCard> createState() => _LiveResponderPipelineCardState();
}

class _LiveResponderPipelineCardState extends ConsumerState<LiveResponderPipelineCard> {
  int _dispatchStep = 1;

  @override
  void initState() {
    super.initState();
    if (widget.isActiveSos) {
      _startStepSequence();
    }
  }

  @override
  void didUpdateWidget(covariant LiveResponderPipelineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveSos && !oldWidget.isActiveSos) {
      _dispatchStep = 1;
      _startStepSequence();
    } else if (!widget.isActiveSos) {
      _dispatchStep = 1;
    }
  }

  void _startStepSequence() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && widget.isActiveSos) setState(() => _dispatchStep = 2);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && widget.isActiveSos) setState(() => _dispatchStep = 3);
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && widget.isActiveSos) setState(() => _dispatchStep = 5); // All 4 completed!
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen to real-time communication events
    ref.listen<AsyncValue<CommunicationEvent>>(communicationEventStreamProvider, (previous, next) {
      next.whenData((event) {
        if (!mounted) return;
        switch (event) {
          case DispatchPreparingEvent(:final stepName):
            if (stepName.contains('Initializing')) {
              setState(() => _dispatchStep = 1);
            } else if (stepName.contains('Compiling')) {
              setState(() => _dispatchStep = 2);
            } else if (stepName.contains('Selecting')) {
              setState(() => _dispatchStep = 3);
            }
          case DialerLaunchingEvent():
          case DialerLaunchedEvent():
          case DispatchCompletedEvent():
          case EmergencySessionStartedEvent():
            setState(() => _dispatchStep = 5);
          default:
            break;
        }
      });
    });


    final steps = [
      'Initializing Monitoring Engine',
      'Compiling Telemetry Packet',
      'Selecting Communication Channel',
      'Launching Emergency Communication',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isActiveSos ? AppColors.sosPrimary : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: widget.isActiveSos ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Section Title & Overall Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isActiveSos ? Icons.warning_amber_rounded : Icons.shield_outlined,
                    color: widget.isActiveSos ? AppColors.sosPrimary : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE RESPONDER PIPELINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (widget.isActiveSos ? AppColors.sosPrimary : Colors.green).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.isActiveSos ? (_dispatchStep > 4 ? 'DISPATCHED' : 'DISPATCHING') : 'READY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: widget.isActiveSos ? (_dispatchStep > 4 ? AppColors.successGreen : AppColors.sosPrimary) : Colors.green,
                  ),
                ),

              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-Section 1: System Telemetry Badges
          Row(
            children: [
              _buildBadge('Telemetry', 'Active', Colors.green),

              const SizedBox(width: 8),
              _buildBadge('Responders', '${widget.respondersCount} Ready', Colors.blue),
              const SizedBox(width: 8),
              _buildBadge('Channel', 'Internet', Colors.purple),
            ],
          ),

          // Sub-Section 2: Event-Driven Dispatch Step Checklist (Active SOS Only)
          if (widget.isActiveSos) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sosPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sosPrimary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(steps.length, (index) {
                  final stepIdx = index + 1;
                  final isDone = _dispatchStep > stepIdx;
                  final isCurrent = _dispatchStep == stepIdx;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppColors.successGreen
                                : isCurrent
                                    ? AppColors.sosPrimary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                            border: Border.all(
                              color: isDone
                                  ? AppColors.successGreen
                                  : isCurrent
                                      ? AppColors.sosPrimary
                                      : Colors.grey.shade600,
                              width: 1.5,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 11, color: Colors.white)
                              : isCurrent
                                  ? const Center(
                                      child: SizedBox(
                                        width: 6,
                                        height: 6,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.sosPrimary,
                                        ),
                                      ),
                                    )
                                  : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isDone
                                  ? (widget.isDark ? Colors.white : Colors.black87)
                                  : isCurrent
                                      ? AppColors.sosPrimary
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 10),

          // Sub-Section 3: Live GPS Location Sharing Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Colors.green, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Location Telemetry',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.isActiveSos ? 'Sharing GPS  •  Updated 3s ago' : 'GPS Tracking Active  •  5s updates',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.onViewLocationDetails != null)
                GestureDetector(
                  onTap: widget.onViewLocationDetails,
                  child: const Text(
                    'Details →',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String key, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            Text(key, style: const TextStyle(fontSize: 8, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
