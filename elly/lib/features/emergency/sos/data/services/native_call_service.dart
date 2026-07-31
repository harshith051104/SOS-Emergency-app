/// native_call_service.dart
///
/// Service executing direct native phone calls via ACTION_CALL MethodChannel
/// or url_launcher tel: fallback.

library;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elly/core/utils/app_logger.dart';

class NativeCallService {
  static const MethodChannel _channel = MethodChannel('com.elly.elly/test_call');

  /// Executes a direct native ACTION_CALL for the specified phone number.
  /// Defaults to "112" if empty.
  static Future<bool> makeDirectCall({String number = '112'}) async {
    final target = number.trim().isEmpty ? '112' : number.trim();
    appLogger.info('NativeCallService: Initiating direct ACTION_CALL to "$target"');

    try {
      final String? result = await _channel.invokeMethod('makeCall', {
        'phoneNumber': target,
      });
      appLogger.info('NativeCallService: Success -> $result');
      return true;
    } on PlatformException catch (e) {
      appLogger.warning('NativeCallService: Native channel error [${e.code}]: ${e.message}. Falling back to url_launcher.');
      return _fallbackUrlLauncher(target);
    } catch (e) {
      appLogger.error('NativeCallService: Direct call exception ($e). Falling back to url_launcher.');
      return _fallbackUrlLauncher(target);
    }
  }

  static Future<bool> _fallbackUrlLauncher(String number) async {
    final Uri uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      appLogger.error('NativeCallService: url_launcher fallback error: $e');
    }
    return false;
  }
}
