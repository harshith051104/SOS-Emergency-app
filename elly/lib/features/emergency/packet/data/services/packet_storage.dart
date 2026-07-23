/// packet_storage.dart
///
/// Implements local storage cache for compiled packets using SharedPreferences.

library;

import 'package:shared_preferences/shared_preferences.dart';

class EmergencyPacketStorage {
  static const String _keyPrefix = 'elly_packet_';

  /// Caches the serialized packet by session ID.
  Future<void> save(String sessionId, String serializedPacket) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$sessionId', serializedPacket);
    } catch (_) {}
  }

  /// Loads the cached serialized packet for the given session ID.
  Future<String?> load(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_keyPrefix$sessionId');
    } catch (_) {
      return null;
    }
  }

  /// Deletes the cached packet.
  Future<void> delete(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$sessionId');
    } catch (_) {}
  }

  /// Clears the storage cache.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }
}
