/// live_responder_pipeline_card.dart
///
/// Section "What happens during SOS" redesigned to match the design reference image:
/// Features a 6-step horizontal visual pipeline with circular icons, connecting dashed lines,
/// step titles, and action descriptions while maintaining real-time event updates.

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
      if (mounted && widget.isActiveSos) setState(() => _dispatchStep = 6);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            setState(() => _dispatchStep = 6);
          default:
            break;
        }
      });
    });

    final steps = [
      _SosFlowStepData(
        stepNumber: '1. Detect',
        title: 'Emergency Detected',
        icon: Icons.notifications_none_rounded,
        bgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
      ),
      _SosFlowStepData(
        stepNumber: '2. Alert',
        title: 'Notify SOS Circle',
        icon: Icons.send_rounded,
        bgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
      ),
      _SosFlowStepData(
        stepNumber: '3. Dispatch',
        title: 'Ambulance & Emergency',
        icon: Icons.local_hospital_outlined,
        bgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
      ),
      _SosFlowStepData(
        stepNumber: '4. Inform',
        title: 'Hospital & Authorities',
        icon: Icons.domain_rounded,
        bgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0D9488),
      ),
      _SosFlowStepData(
        stepNumber: '5. Share',
        title: 'Live Location & Health Data',
        icon: Icons.location_on_outlined,
        bgColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      ),
      _SosFlowStepData(
        stepNumber: '6. Assist',
        title: 'Live Elly Guidance',
        icon: Icons.headset_mic_outlined,
        bgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
      ),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'What happens during SOS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onViewLocationDetails,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Horizontal SOS Flow Steps List
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.antiAlias,
              itemCount: steps.length,


              separatorBuilder: (context, index) => Container(
                width: 32,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 18),
                child: Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        color: widget.isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
              ),
              itemBuilder: (context, index) {
                final step = steps[index];
                final isCompleted = (index + 1) <= _dispatchStep;

                return SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      // Icon Circle Container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? step.bgColor
                              : (widget.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          border: Border.all(
                            color: isCompleted
                                ? step.iconColor.withValues(alpha: 0.4)
                                : (widget.isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          step.icon,
                          size: 20,
                          color: isCompleted
                              ? step.iconColor
                              : (widget.isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Step Number
                      Text(
                        step.stepNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Step Title / Description
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SosFlowStepData {
  _SosFlowStepData({
    required this.stepNumber,
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  final String stepNumber;
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
}
