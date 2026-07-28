/// emergency_activation_bottom_sheet.dart
///
/// Merged Emergency Activation Bottom Sheet.
/// Automatically targets Universal Emergency Service with support for international standards
/// (112, 911, 999, 000) and automatic regional CountryResolver detection.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/sos_countdown_state.dart';
import '../../domain/entities/emergency_service_model.dart';

import '../providers/sos_countdown_provider.dart';
import '../providers/emergency_service_provider.dart';
import '../controllers/emergency_session_controller.dart';
import '../../../communication/presentation/controllers/emergency_communication_controller.dart';

import '../../../global/domain/services/country_resolver.dart';
import '../../../global/domain/entities/emergency_service_directory.dart';
import '../../../telemetry/presentation/providers/telemetry_providers.dart';


class EmergencyActivationBottomSheet extends ConsumerWidget {
  const EmergencyActivationBottomSheet({super.key});

  void _dispatchEmergency(BuildContext context, WidgetRef ref) {
    final selectionState = ref.read(emergencyServiceProvider);
    final selectedService = selectionState.selectedService ??
        const EmergencyService(
          id: 'srv_universal',
          name: 'Universal Emergency',
          description: 'National Unified Emergency Response Standard',
          emergencyNumber: '112',
          icon: Icons.emergency_rounded,
          category: 'universal',
          priority: 6,
        );

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    ref.read(emergencyCommunicationControllerProvider.notifier).executeDispatch(
          triggerSource: 'MANUAL SOS (UNIVERSAL CALL)',
          selectedService: selectedService,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final countdownState = ref.watch(sosCountdownStateProvider);
    final serviceState = ref.watch(emergencyServiceProvider);
    final sessionController = ref.read(emergencySessionControllerProvider.notifier);

    final seconds = countdownState.secondsRemaining;
    final selectedService = serviceState.selectedService;
    final telemetryState = ref.watch(telemetryControllerProvider);
    final countryResult = CountryResolver.resolve(location: telemetryState.latestPoint);
    final countryProfile = EmergencyServiceDirectory.getProfile(countryResult.countryCode);
    final localEmergencyNumber = countryProfile.universalNumber;






    // Ensure countdown timer is actively running whenever the sheet is open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (countdownState.status == SosCountdownStatus.idle) {
        sessionController.startSos();
      }
    });

    // Listen for countdown completed or cancelled events
    ref.listen<SosCountdownStateModel>(sosCountdownStateProvider, (previous, next) {
      if (!context.mounted) return;
      if (next.status == SosCountdownStatus.completed) {
        _dispatchEmergency(context, ref);
      } else if (next.status == SosCountdownStatus.cancelled) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });


    /*
    final internationalStandards = [
      {'number': '112', 'region': 'EU / India / GSM'},
      {'number': '911', 'region': 'US / Canada'},
      {'number': '999', 'region': 'UK / Cmwlth'},
      {'number': '000', 'region': 'Australia'},
    ];
    */


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
        children: [
          // Drag Handle Bar
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Trigger Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sosPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sosPrimary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.sosPrimary),
                const SizedBox(width: 6),
                Text(
                  countdownState.triggerSource.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.sosPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Anti-False Trigger Question Prompt
          const Text(
            'Are you safe right now?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Large Countdown Number
          Text(
            '$seconds',
            style: const TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              color: AppColors.sosPrimary,
              height: 1.0,
            ),
          ),
          const Text(
            'SECONDS UNTIL AUTOMATIC DISPATCH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 16),

          // Direct Universal Emergency Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : const Color(0xFFFFE5EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sosPrimary, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.sosPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Universal Emergency (${selectedService?.emergencyNumber ?? localEmergencyNumber})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Detected Region: ${countryProfile.countryName} • Direct Emergency Line',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          /*
          // ── COMMENTED OUT PER USER DIRECTIVE: Zero Manual Feature Selection During SOS ──
          // International Standards Quick Selector Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: internationalStandards.map((item) {
              final number = item['number']!;
              final region = item['region']!;
              final isCurrentSelected = (selectedService?.emergencyNumber ?? localEmergencyNumber) == number;

              return InkWell(
                onTap: () {
                  sessionController.selectService(
                    EmergencyService(
                      id: 'srv_$number',
                      name: 'Emergency $number',
                      description: region,
                      emergencyNumber: number,
                      icon: Icons.phone_in_talk_rounded,
                      category: 'universal',
                      priority: 6,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrentSelected
                        ? AppColors.sosPrimary
                        : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentSelected
                          ? AppColors.sosPrimary
                          : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        number,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isCurrentSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($region)',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isCurrentSelected ? Colors.white70 : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          */

          const SizedBox(height: 8),


          /*
          // ── COMMENTED OUT PER USER DIRECTIVE: Multi-Service Department Selector ──
          // Emergency Service Selector Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select Emergency Department:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 6 Service Selector List (Grid / Wrap)
          if (serviceState.isLoading)
            const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: serviceState.services.map((service) {
                final isSelected = selectedService?.id == service.id;

                return InkWell(
                  onTap: () {
                    sessionController.selectService(service);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.sosPrimary
                          : (isDark ? AppColors.cardDark : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.sosPrimary : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : service.icon,
                          size: 16,
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            service.emergencyNumber,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          */

          const SizedBox(height: 14),

          // Auto-Selection Message
          Text(
            'Direct Universal Emergency (${selectedService?.emergencyNumber ?? localEmergencyNumber}) Dispatch Active.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons: I'M SAFE 💚 & NEED HELP NOW 🛑
          Row(
            children: [
              // POSITIVE RESPONSE: "I'M SAFE 💚"
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.vibrate();
                    sessionController.confirmSafe();
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Colors.green, width: 2.0),
                    foregroundColor: Colors.green.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "I'M SAFE 💚",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // NEGATIVE RESPONSE: "NEED HELP NOW 🛑"
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    sessionController.confirmEmergency();
                    _dispatchEmergency(context, ref);
                  },
                  icon: const Icon(Icons.warning_rounded, size: 18),
                  label: const Text(
                    'NEED HELP 🛑',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.sosPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
