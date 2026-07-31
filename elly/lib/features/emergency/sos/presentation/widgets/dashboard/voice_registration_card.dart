/// voice_registration_card.dart
///
/// Dashboard Card for Owner Voice Registration & Speaker Biometric Lock.
/// Positioned above "Trigger Methods" on the main ELLY emergency dashboard.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/speaker_verification/presentation/providers/speaker_verification_providers.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/details/voice_registration_sheet.dart';

class VoiceRegistrationCard extends ConsumerWidget {
  const VoiceRegistrationCard({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speakerState = ref.watch(speakerVerificationControllerProvider);
    final activeProfile = speakerState.activeProfile;
    final isEnrolled = activeProfile != null || speakerState.enrolledProfiles.isNotEmpty;
    final ownerName = activeProfile?.displayName ?? 'Alex Vance';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFF6366F1).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => VoiceRegistrationSheet.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Left Icon Container (Voice Fingerprint Icon)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Middle: Title & Owner Voice Profile Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Flexible(
                            child: Text(
                              'Voice Registration',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'OWNER',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4F46E5),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnrolled
                            ? 'Voice Owner: $ownerName (Verified ✓)'
                            : 'Tap to register owner voice profile',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isEnrolled ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Right Action Button / Badge
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isEnrolled ? const Color(0xFFDCFCE7) : const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEnrolled
                            ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnrolled ? Icons.verified_user_rounded : Icons.mic_rounded,
                          size: 12,
                          color: isEnrolled ? const Color(0xFF16A34A) : Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isEnrolled ? 'VERIFIED' : 'REGISTER',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: isEnrolled ? const Color(0xFF16A34A) : Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
