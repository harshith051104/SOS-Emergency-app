/// app.dart
///
/// Root application widget.
/// Wires together:
///   - GoRouter (from Riverpod provider)
///   - Material 3 light + dark themes
///   - ProviderScope is handled in main.dart

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget of the ELLY application.
class EllyApp extends ConsumerWidget {
  const EllyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ELLY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
