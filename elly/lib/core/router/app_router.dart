/// app_router.dart
///
/// GoRouter configuration for the ELLY application.
///
/// Routes:
///   /                              → HomePage
///   /emergency/confirmation        → EmergencyConfirmationPage
///   /emergency/generating          → EmergencyGeneratingPage (checklist)
///   /emergency/session             → EmergencySessionPage (dashboard)
///   /emergency/complete            → EmergencyReportPage (final stats)
///   /emergency/countdown           → EmergencyCountdownPage (legacy)
///   /emergency/activated           → EmergencyActivatedPage
///   /emergency/response-status     → ResponseStatusPage (live engine)
///   /responders                    → RespondersPage
///   /responders/add                → AddEditResponderPage (add mode)
///   /responders/edit/:id           → AddEditResponderPage (edit mode)

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/emergency/responders/domain/entities/responder.dart';
import '../../features/emergency/responders/presentation/pages/add_edit_responder_page.dart';
import '../../features/emergency/responders/presentation/pages/response_status_page.dart';
import '../../features/emergency/responders/presentation/pages/responders_page.dart';
import '../../features/emergency/sos/domain/enums/emergency_status.dart';
import '../../features/emergency/sos/presentation/pages/emergency_activated_page.dart';
import '../../features/emergency/sos/presentation/pages/emergency_confirmation_page.dart';
import '../../features/emergency/sos/presentation/pages/emergency_countdown_page.dart';
import '../../features/emergency/sos/presentation/pages/emergency_generating_page.dart';
import '../../features/emergency/sos/presentation/pages/emergency_session_page.dart';
import '../../features/emergency/sos/presentation/pages/emergency_report_page.dart';
import '../../features/emergency/sos/presentation/pages/home_page.dart';
import '../../features/emergency/sos/presentation/providers/emergency_providers.dart';
import '../../features/emergency/packet/presentation/pages/emergency_packet_page.dart';
import '../../features/emergency/packet/presentation/pages/emergency_debug_page.dart';

/// Route path constants — no hardcoded strings in widget code.
abstract final class AppRoutes {
  static const String home = '/';

  // ── Emergency flow ────────────────────────────────────────────────────────
  static const String emergencyConfirmation = '/emergency/confirmation';
  static const String emergencyGenerating = '/emergency/generating';
  static const String emergencySession = '/emergency/session';
  static const String emergencyComplete = '/emergency/complete';
  static const String emergencyPacketPattern = '/emergency/session/:id/packet';
  static String emergencyPacket(String id) => '/emergency/session/${Uri.encodeComponent(id)}/packet';
  static const String emergencyDebug = '/emergency/debug';
  static const String emergencyCountdown = '/emergency/countdown';
  static const String emergencyActivated = '/emergency/activated';
  static const String emergencyResponseStatus = '/emergency/response-status';

  // ── Responders management ─────────────────────────────────────────────────
  static const String responders = '/responders';
  static const String respondersAdd = '/responders/add';
  static String respondersEdit(String id) => '/responders/edit/$id';
}

/// Provider that exposes the configured [GoRouter] instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // ── Home ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // ── Emergency: Confirmation (new flow) ────────────────────────────────
      GoRoute(
        path: AppRoutes.emergencyConfirmation,
        name: 'emergencyConfirmation',
        redirect: (context, state) {
          final status = ref.read(emergencyStatusProvider);
          final allowed = status == EmergencyStatus.awaitingConfirmation ||
              status == EmergencyStatus.activating;
          return allowed ? null : AppRoutes.home;
        },
        builder: (context, state) => const EmergencyConfirmationPage(),
      ),

      // ── Emergency: Generating Packet (Bypassed) ─────────────────────────
      GoRoute(
        path: AppRoutes.emergencyGenerating,
        name: 'emergencyGenerating',
        redirect: (context, state) => AppRoutes.emergencySession,
        builder: (context, state) => const EmergencyGeneratingPage(),
      ),

      // ── Emergency: Live Session Dashboard ──────────────────────────────────
      GoRoute(
        path: AppRoutes.emergencySession,
        name: 'emergencySession',
        redirect: (context, state) {
          final status = ref.read(emergencyStatusProvider);
          final allowed = status == EmergencyStatus.active;
          return allowed ? null : AppRoutes.home;
        },
        builder: (context, state) => const EmergencySessionPage(),
      ),

      // ── Emergency: Packet Details ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.emergencyPacketPattern,
        name: 'emergencyPacket',
        builder: (context, state) {
          final id = Uri.decodeComponent(state.pathParameters['id'] ?? '');
          return EmergencyPacketPage(sessionId: id);
        },
      ),

      GoRoute(
        path: AppRoutes.emergencyDebug,
        name: 'emergencyDebug',
        builder: (context, state) => const EmergencyDebugPage(),
      ),

      // ── Emergency: Final Summary Report ────────────────────────────────────
      GoRoute(
        path: AppRoutes.emergencyComplete,
        name: 'emergencyComplete',
        redirect: (context, state) {
          final status = ref.read(emergencyStatusProvider);
          final allowed = status == EmergencyStatus.sessionCompleted;
          return allowed ? null : AppRoutes.home;
        },
        builder: (context, state) => const EmergencyReportPage(),
      ),

      // ── Emergency: Countdown (legacy flow) ────────────────────────────────
      GoRoute(
        path: AppRoutes.emergencyCountdown,
        name: 'emergencyCountdown',
        redirect: (context, state) {
          final status = ref.read(emergencyStatusProvider);
          final allowed = status == EmergencyStatus.countdown ||
              status == EmergencyStatus.activating;
          return allowed ? null : AppRoutes.home;
        },
        builder: (context, state) => const EmergencyCountdownPage(),
      ),

      // ── Emergency: Activated ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.emergencyActivated,
        name: 'emergencyActivated',
        redirect: (context, state) {
          final status = ref.read(emergencyStatusProvider);
          return status == EmergencyStatus.active ? null : AppRoutes.home;
        },
        builder: (context, state) => const EmergencyActivatedPage(),
      ),

      // ── Emergency: Response Status (live engine timeline) ─────────────────
      GoRoute(
        path: AppRoutes.emergencyResponseStatus,
        name: 'emergencyResponseStatus',
        builder: (context, state) => const ResponseStatusPage(),
      ),

      // ── Responders: List ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.responders,
        name: 'responders',
        builder: (context, state) => const RespondersPage(),
      ),

      // ── Responders: Add ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.respondersAdd,
        name: 'respondersAdd',
        builder: (context, state) => const AddEditResponderPage(),
      ),

      // ── Responders: Edit ──────────────────────────────────────────────────
      GoRoute(
        path: '/responders/edit/:id',
        name: 'respondersEdit',
        builder: (context, state) {
          final responder = state.extra as Responder?;
          return AddEditResponderPage(responder: responder);
        },
      ),
    ],

    // Global error page.
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
