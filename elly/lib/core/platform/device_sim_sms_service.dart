/// device_sim_sms_service.dart
///
/// Thin Flutter platform bridge to the Android SmsManager MethodChannel.
/// Sends SMS directly through the device's SIM card — no internet required.
///
/// Platform support:
///   Android  ✅  Uses SmsManager via MethodChannel "com.elly.elly/sms"
///   iOS      ❌  Returns false (not supported — no background SMS API on iOS)
///   Web      ❌  Returns false
///   Desktop  ❌  Returns false

library;

import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:elly/core/utils/app_logger.dart';

/// Service that dispatches SMS using the device's own SIM card via Android
/// native [SmsManager]. All calls are fire-and-forget at the Android layer;
/// the Kotlin side returns `true` when [SmsManager.sendTextMessage] has been
/// called without throwing (delivery receipt is async and handled natively).
class DeviceSimSmsService {
  const DeviceSimSmsService();

  static const MethodChannel _channel = MethodChannel('com.elly.elly/sms');

  /// Whether this transport is supported on the current platform.
  bool get isSupported => Platform.isAndroid;

  /// Sends [body] as an SMS to [to] using the device SIM card.
  ///
  /// Returns `true` if the SMS was handed off to the Android SmsManager
  /// without error. A `true` result means the message was queued for
  /// transmission — delivery may still fail at the network layer.
  ///
  /// Returns `false` on non-Android platforms or when a platform exception
  /// is thrown (permission denied, no SIM, invalid number, etc.).
  Future<bool> sendSms({
    required String to,
    required String body,
  }) async {
    if (!isSupported) {
      appLogger.warning(
        'DeviceSimSmsService: SMS transport not supported on ${Platform.operatingSystem}.',
      );
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('sendSms', {
        'to': to,
        'body': body,
      });
      appLogger.info('DeviceSimSmsService: SMS queued → $to [result: $result]');
      return result ?? false;
    } on PlatformException catch (e) {
      appLogger.error(
        'DeviceSimSmsService: PlatformException sending SMS to $to — ${e.code}: ${e.message}',
      );
      return false;
    } catch (e, st) {
      appLogger.error('DeviceSimSmsService: Unexpected error sending SMS to $to', e, st);
      return false;
    }
  }
}
