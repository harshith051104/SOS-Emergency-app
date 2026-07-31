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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onViewLocationDetails,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Static 6-Column Pipeline Row (All 6 Steps Displayed At Once matching reference image)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _buildStaticStep(
                  step: steps[i],
                  isCompleted: (i + 1) <= _dispatchStep,
                  isDark: widget.isDark,
                ),
                if (i < steps.length - 1) _buildDashedConnector(widget.isDark),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticStep({
    required _SosFlowStepData step,
    required bool isCompleted,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? step.bgColor
                  : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
              border: Border.all(
                color: isCompleted
                    ? step.iconColor
                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                width: 1.2,
              ),
            ),
            child: Icon(
              step.icon,
              size: 15,
              color: isCompleted
                  ? step.iconColor
                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            step.stepNumber,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            step.title.split(' ').first, // Main concise title keyword
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDashedConnector(bool isDark) {
    return Container(
      width: 10,
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        children: List.generate(
          2,
          (i) => Expanded(
            child: Container(
              height: 1.2,
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
          ),
        ),
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
