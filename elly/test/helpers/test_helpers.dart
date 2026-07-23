/// test_helpers.dart
///
/// Shared test utilities and widget builders.

library;

import 'package:elly/app.dart';
import 'package:elly/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wraps a widget in the minimal test scaffold:
///   - ProviderScope
///   - MaterialApp with Material 3 theme
///   - GoRouter (single route to the provided widget)
Widget buildTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => child,
          ),
          // Stub routes so navigation calls don't error in tests.
          GoRoute(
            path: '/emergency/countdown',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Countdown')),
            ),
          ),
          GoRoute(
            path: '/emergency/activated',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Activated')),
            ),
          ),
        ],
      ),
    ),
  );
}
