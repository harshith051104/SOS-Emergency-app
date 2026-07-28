/// sos_flow_detail_sheet.dart
///
/// Dedicated Modal Sheet explaining the complete 6-step emergency pipeline
/// for "What Happens During SOS".

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class SosFlowDetailSheet extends StatelessWidget {
  const SosFlowDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      _SosStepDetail(
        stepNumber: '1',
        title: 'Detect — Emergency Detected',
        description: 'Instant activation via manual trigger, voice wake-word ("Help me"), or AI sensor detection (falls, crash, abnormal vitals).',
        icon: Icons.notifications_active_rounded,
        bgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
      ),
      _SosStepDetail(
        stepNumber: '2',
        title: 'Alert — Notify SOS Circle',
        description: 'Immediate SMS, push notification, and automated voice call sent to your prioritized emergency contact circle.',
        icon: Icons.send_rounded,
        bgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
      ),
      _SosStepDetail(
        stepNumber: '3',
        title: 'Dispatch — Ambulance & Emergency Services',
        description: 'Direct routing to regional emergency services (112 / 911 / 999 / 000 based on live GPS location).',
        icon: Icons.local_hospital_rounded,
        bgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
      ),
      _SosStepDetail(
        stepNumber: '4',
        title: 'Inform — Hospital & Local Authorities',
        description: 'Real-time encrypted telemetry transmission to nearest regional hospital ERs and first responder hubs.',
        icon: Icons.domain_rounded,
        bgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0D9488),
      ),
      _SosStepDetail(
        stepNumber: '5',
        title: 'Share — Live Location & Health Data',
        description: 'Encrypted 5-second interval GPS location tracking link and Emergency Health Passport shared with active responders.',
        icon: Icons.location_on_rounded,
        bgColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      ),
      _SosStepDetail(
        stepNumber: '6',
        title: 'Assist — Live ELLY Voice Guidance',
        description: '24/7 AI Guardian providing calm voice guidance, CPR / first-aid steps, and live session monitoring until safe.',
        icon: Icons.headset_mic_rounded,
        bgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle Bar
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What Happens During SOS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '6-Step Automated Emergency Response & Dispatch Pipeline',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Step List
          Expanded(
            child: ListView.separated(
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = steps[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Circle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: item.iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Text Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sosPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Got It ✓',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosStepDetail {
  _SosStepDetail({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
}
