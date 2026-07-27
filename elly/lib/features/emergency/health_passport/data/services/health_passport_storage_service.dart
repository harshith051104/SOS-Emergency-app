/// health_passport_storage_service.dart
///
/// Storage abstraction persisting Health Passport JSON data via SharedPreferences.

library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/core/utils/app_logger.dart';

class HealthPassportStorageService {
  static const String _storageKey = 'elly_health_passport_v1';

  Future<Map<String, dynamic>?> readPassportJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e, st) {
      appLogger.error('HealthPassportStorageService: Error reading passport JSON from storage', e, st);
    }
    return null;
  }

  Future<bool> writePassportJson(Map<String, dynamic> passportJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(passportJson);
      final success = await prefs.setString(_storageKey, encoded);
      appLogger.info('HealthPassportStorageService: Saved profile JSON to storage (success: $success)');
      return success;
    } catch (e, st) {
      appLogger.error('HealthPassportStorageService: Error writing passport JSON to storage', e, st);
      return false;
    }
  }

  Future<bool> deletePassportJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_storageKey);
      appLogger.info('HealthPassportStorageService: Deleted profile JSON from storage');
      return success;
    } catch (e, st) {
      appLogger.error('HealthPassportStorageService: Error deleting passport JSON from storage', e, st);
      return false;
    }
  }
}
