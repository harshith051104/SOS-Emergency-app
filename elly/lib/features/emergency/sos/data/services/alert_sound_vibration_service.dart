/// alert_sound_vibration_service.dart
///
/// Helper service that manages silent tactile vibration feedback
/// when emergency confirmation pages trigger (Sound removed per user preference).

library;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:elly/core/utils/app_logger.dart';

class AlertSoundVibrationService {
  static Timer? _vibrationTimer;
  static bool _isActive = false;

  /// Starts repeating tactile vibration feedback (Silent - Audio Sound removed).
  static Future<void> startAlertSequence({String spokenText = ''}) async {
    if (_isActive) return;
    _isActive = true;
    appLogger.info('AlertSoundVibrationService: Starting silent emergency vibration sequence...');

    // 1. Immediate Heavy Vibration
    _triggerVibrationPattern();

    // 2. Start periodic 700ms repeating vibration pulse
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (_isActive) {
        _triggerVibrationPattern();
      }
    });
  }

  static void _triggerVibrationPattern() {
    try {
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Stops vibration feedback.
  static Future<void> stopAlertSequence() async {
    _isActive = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    appLogger.info('AlertSoundVibrationService: Vibration sequence stopped.');
  }
}
