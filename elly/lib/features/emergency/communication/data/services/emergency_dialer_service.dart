/// emergency_dialer_service.dart
///
/// Low-level platform service executing phone call invocations via url_launcher
/// with number validation, fallback launch modes, and structured error handling.

library;

import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/utils/app_logger.dart';

class EmergencyDialerService {
  const EmergencyDialerService();

  /// Validates phone number format.
  bool validateNumber(String phoneNumber) {
    final sanitized = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return sanitized.isNotEmpty && sanitized.length >= 3;
  }

  /// Launches native phone dialer for the target emergency number.
  Future<bool> launchDialer(String phoneNumber) async {
    if (!validateNumber(phoneNumber)) {
      appLogger.error('EmergencyDialerService: Invalid emergency number "$phoneNumber"');
      return false;
    }

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      appLogger.info('EmergencyDialerService: Launching dialer for $cleanNumber');

      if (await canLaunchUrl(phoneUri)) {
        final launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }

      appLogger.warning('EmergencyDialerService: Default launch failed, trying externalNonBrowserApplication fallback');
      final fallbackLaunched = await launchUrl(phoneUri, mode: LaunchMode.externalNonBrowserApplication);
      return fallbackLaunched;
    } catch (e, st) {
      appLogger.error('EmergencyDialerService: Failed to launch phone dialer for $cleanNumber', e, st);
      return false;
    }
  }
}
