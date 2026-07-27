/// main.dart
///
/// Application entry point for ELLY.
///
/// Responsibilities:
///   - Wrap the widget tree with [ProviderScope] (Riverpod DI root)
///   - Initialise the logger before runApp
///   - Ensure Flutter bindings are initialised

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';

void main() {
  // Ensure Flutter engine is ready before initialising plugins / logger.
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure standard Flutter error handling is active.
  FlutterError.onError = FlutterError.presentError;

  appLogger.info('ELLY starting up…');

  runApp(
    // ProviderScope is the DI container for the entire app.
    // All Riverpod providers are scoped within this.
    const ProviderScope(
      child: EllyApp(),
    ),
  );
}
