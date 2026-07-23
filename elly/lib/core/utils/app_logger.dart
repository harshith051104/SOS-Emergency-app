/// app_logger.dart
///
/// Centralised logging using the [talker_flutter] package.
/// All application components should use this logger instead of [print].
/// This ensures consistent log formatting, filtering, and future remote
/// log shipping (e.g., Crashlytics, Sentry).

library;

import 'package:talker_flutter/talker_flutter.dart';

/// Singleton [Talker] instance shared across the entire application.
///
/// Usage:
/// ```dart
/// appLogger.info('SOS activated');
/// appLogger.error('Failed to create emergency', error, stackTrace);
/// ```
final Talker appLogger = TalkerFlutter.init(
  settings: TalkerSettings(
    // Enable all log levels in debug; configure via build flavours later.
    enabled: true,
    useConsoleLogs: true,
  ),
);
