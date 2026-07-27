/// home_page.dart
///
/// Single State-Driven Emergency Control Center Dashboard for ELLY.
/// Morphing in-place across 5 UI states while preserving 100% of backend engines.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/presentation/providers/emergency_providers.dart';
import 'package:elly/features/emergency/sos/presentation/controllers/emergency_session_controller.dart';

import 'package:elly/features/emergency/monitoring/presentation/providers/developer_mode_provider.dart';
import 'package:elly/features/emergency/monitoring/presentation/widgets/mode_toggle_switch.dart';

import 'package:elly/features/emergency/monitoring/presentation/widgets/developer_telemetry_console.dart';
import 'package:elly/features/emergency/responders/presentation/providers/responder_providers.dart';


// Dashboard Cards
import 'package:elly/features/emergency/sos/presentation/widgets/dashboard/protection_header_card.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/dashboard/hero_sos_button_card.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/dashboard/live_responder_pipeline_card.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/dashboard/sos_circle_card.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/dashboard/health_passport_card.dart';

import 'package:elly/features/emergency/sos/presentation/widgets/dashboard/trigger_methods_card.dart';

import 'package:elly/features/emergency/sos/presentation/widgets/dashboard/session_summary_card.dart';

// Detail Modal Sheets
import 'package:elly/features/emergency/sos/presentation/widgets/details/trigger_methods_detail_sheet.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/details/sos_circle_detail_sheet.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/details/health_passport_detail_sheet.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/emergency_activation_bottom_sheet.dart';



import 'package:elly/features/emergency/communication/presentation/controllers/emergency_communication_controller.dart';

import 'package:elly/features/emergency/telemetry/presentation/providers/telemetry_providers.dart';
import 'package:elly/features/emergency/readiness/presentation/providers/readiness_providers.dart';









enum DashboardUiState {
  normalProtection,
  preparing,
  activeSos,
  resolved,
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  DashboardUiState _uiState = DashboardUiState.normalProtection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen for Emergency Communication Engine errors
    ref.listen<EmergencyCommunicationState>(emergencyCommunicationControllerProvider, (previous, next) {
      if (next.hasError && next.errorMessage != null && context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Emergency Dispatch Failed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(next.errorMessage!, style: const TextStyle(fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(emergencyCommunicationControllerProvider.notifier).reset();
                  _endEmergency(context);
                },
                child: const Text('Cancel Emergency', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(emergencyCommunicationControllerProvider.notifier).executeDispatch(
                        triggerSource: 'MANUAL SOS (RETRY)',
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    });

    ref.listen(emergencyStatusProvider, (prev, next) {
      if (next == EmergencyStatus.active) {
        ref.read(telemetryControllerProvider.notifier).startSession(
              ref.read(emergencyControllerProvider).activeSession?.sessionId ?? 'session_live',
            );
      } else if (next == EmergencyStatus.idle) {
        ref.read(telemetryControllerProvider.notifier).stopSession();
      }
    });


    final isDevMode = ref.watch(isDeveloperModeProvider);
    final status = ref.watch(emergencyStatusProvider);

    final controllerNotifier = ref.watch(emergencyControllerProvider.notifier);
    final controllerState = ref.watch(emergencyControllerProvider);
    final session = controllerState.activeSession;
    final respondersState = ref.watch(respondersControllerProvider);
    final responders = respondersState.responders;


    final isActiveSos = status == EmergencyStatus.active ||
        status == EmergencyStatus.generatingPacket ||
        status == EmergencyStatus.awaitingConfirmation ||
        status == EmergencyStatus.activating ||
        _uiState == DashboardUiState.activeSos;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Content (Dev Console vs User Control Center Dashboard) ──
            if (isDevMode)
              Positioned.fill(
                top: 60,
                child: DeveloperTelemetryConsole(sessionId: session?.sessionId),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 56), // Space for top bars

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        // Card 1: Protection Header Banner (Shows END EMERGENCY SESSION button at top when active)
                         ProtectionHeaderCard(
                          isDark: isDark,
                          readinessScore: ref.watch(readinessControllerProvider).readinessScore,

                          isActiveSos: isActiveSos,
                          elapsedFormatted: controllerState.formattedDuration,
                          onTestSos: isActiveSos ? () => _endEmergency(context) : () => _triggerSosFlow(context, isTest: true),
                        ),
                        const SizedBox(height: 14),

                        // State View: Normal vs Active vs Resolved
                        if (_uiState == DashboardUiState.resolved)

                          SessionSummaryCard(
                            isDark: isDark,
                            durationFormatted: controllerState.formattedDuration.isNotEmpty ? controllerState.formattedDuration : '04:12',
                            packetsSent: 18,
                            respondersReached: responders.isNotEmpty ? responders.length : 3,
                            onDone: () {
                              setState(() {
                                _uiState = DashboardUiState.normalProtection;
                              });
                            },
                          )

                        else ...[
                          // Section 2: How SOS Should Trigger
                          TriggerMethodsCard(
                            isDark: isDark,
                            onViewAll: () => _openSheet(context, const TriggerMethodsDetailSheet()),
                          ),
                          const SizedBox(height: 14),

                          // Section 3: Large SOS Button
                          HeroSosButtonCard(
                            isLocked: controllerNotifier.isLocked,
                            isActive: isActiveSos,
                            onTap: () => _triggerSosFlow(context),
                          ),
                          const SizedBox(height: 18),

                          // Section 4: SOS Circle
                          SosCircleCard(
                            isDark: isDark,
                            isActiveSos: isActiveSos,
                            onViewAll: () => _openSheet(context, const SosCircleDetailSheet()),
                          ),

                          const SizedBox(height: 14),

                          // Section 5: Live Responder Pipeline
                          LiveResponderPipelineCard(
                            isDark: isDark,
                            isActiveSos: isActiveSos,
                            respondersCount: responders.length,
                          ),
                          const SizedBox(height: 14),


                          // Section 6: Emergency Health Passport
                          HealthPassportCard(
                            isDark: isDark,
                            isActiveSos: isActiveSos,
                            onViewAll: () => _openSheet(context, const HealthPassportDetailSheet()),
                          ),
                          const SizedBox(height: 100),









                        ],

                      ],
                    ),
                  ),
                ],
              ),

            // ── Top Mode Toggle Bar ─────────────────────────────────────
            const Positioned(
              top: 12,
              left: 16,
              child: ModeToggleSwitch(compact: true),
            ),

            // ── Sticky Floating ACTIVE SOS EMERGENCY Timer Banner (Bottom Position) ──
            if (isActiveSos)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sosPrimary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosPrimary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'ACTIVE SOS EMERGENCY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: AppColors.sosPrimary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'Elapsed: ${controllerState.formattedDuration}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sosPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          ],
        ),
      ),
    );


  }



  void _triggerSosFlow(BuildContext context, {bool isTest = false}) {
    ref.read(emergencySessionControllerProvider.notifier).startSos();
    _openSheet(context, const EmergencyActivationBottomSheet());
  }




  Future<void> _endEmergency(BuildContext context) async {
    ref.read(emergencyControllerProvider.notifier).resetToIdle();
    setState(() {
      _uiState = DashboardUiState.normalProtection;
    });
  }




  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => sheet,
    );
  }
}
