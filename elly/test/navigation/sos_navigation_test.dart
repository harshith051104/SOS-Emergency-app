/// sos_navigation_test.dart
///
/// Navigation tests using GoRouter.
/// Verifies route guards redirect correctly when accessed out of order.

library;

import 'package:elly/core/router/app_router.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/presentation/providers/emergency_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Route Guards —', () {
    testWidgets(
        'navigating to /emergency/countdown when idle redirects to home',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Status is idle — no active countdown.
            emergencyStatusProvider
                .overrideWithValue(EmergencyStatus.idle),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Attempt to navigate directly to countdown route.
      final element = tester.element(find.byType(MaterialApp));
      GoRouter.of(element).go(AppRoutes.emergencyCountdown);

      await tester.pumpAndSettle();

      // Should have been redirected to home.
      final router = GoRouter.of(element);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });

    testWidgets(
        'navigating to /emergency/activated when idle redirects to home',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyStatusProvider
                .overrideWithValue(EmergencyStatus.idle),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      final element = tester.element(find.byType(MaterialApp));
      GoRouter.of(element).go(AppRoutes.emergencyActivated);

      await tester.pumpAndSettle();

      final router = GoRouter.of(element);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });
  });
}
