/// main.dart
///
/// Application entry point for ELLY.
///
/// Responsibilities:
///   - Wrap the widget tree with [ProviderScope] (Riverpod DI root)
///   - Initialise SharedPreferences before runApp
///   - Initialise the logger before runApp
///   - Ensure Flutter bindings are initialised

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';
import 'features/emergency/responders/presentation/providers/responder_providers.dart';

Future<void> main() async {
  // Ensure Flutter engine is ready before initialising plugins / logger.
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure standard Flutter error handling is active.
  FlutterError.onError = FlutterError.presentError;

  // Initialise SharedPreferences once before the widget tree is built.
  final prefs = await SharedPreferences.getInstance();

  appLogger.info('ELLY starting up…');

  runApp(
    ProviderScope(
      overrides: [
        // Make the single SharedPreferences instance available to all providers.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EllyApp(),
    ),
  );
}
