/// emergency_local_datasource.dart
///
/// Local data source stub for emergency data persistence.
///
/// Phase 1: Returns hardcoded / in-memory data.
/// Phase 2+: Will use SharedPreferences, Hive, or SQLite to persist
///   emergency events between app restarts.

library;

import '../../domain/entities/emergency_event.dart';

/// Contract for local emergency data operations.
abstract interface class EmergencyLocalDataSource {
  /// Saves an [EmergencyEvent] locally.
  Future<void> saveEvent(EmergencyEvent event);

  /// Retrieves the most recently saved [EmergencyEvent], or null.
  Future<EmergencyEvent?> getLatestEvent();

  /// Clears all locally stored emergency data.
  Future<void> clearAll();
}

/// In-memory implementation used in Phase 1.
///
/// Not persisted across app restarts — replace with Hive/SQLite in Phase 2.
class EmergencyLocalDataSourceImpl implements EmergencyLocalDataSource {
  EmergencyEvent? _latestEvent;

  @override
  Future<void> saveEvent(EmergencyEvent event) async {
    _latestEvent = event;
  }

  @override
  Future<EmergencyEvent?> getLatestEvent() async {
    return _latestEvent;
  }

  @override
  Future<void> clearAll() async {
    _latestEvent = null;
  }
}
