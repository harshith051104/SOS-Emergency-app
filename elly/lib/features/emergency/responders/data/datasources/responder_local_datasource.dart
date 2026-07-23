/// responder_local_datasource.dart
///
/// In-memory data source for [Responder] entities.
/// Pre-loaded with 3 seed responders so the app is useful from first launch.
///
/// Phase 2+: Replace with a SQLite / SharedPreferences / Hive implementation.

library;

import 'package:uuid/uuid.dart';

import '../../domain/entities/responder.dart';
import '../../domain/enums/notification_method.dart';
import '../../domain/enums/responder_type.dart';

/// Abstract contract for the local data source.
abstract class ResponderLocalDataSource {
  Future<List<Responder>> getAll();
  Future<Responder> save(Responder responder);
  Future<void> delete(String id);
  Future<void> reorder(List<String> orderedIds);
}

/// In-memory implementation seeded with example responders.
class ResponderLocalDataSourceImpl implements ResponderLocalDataSource {
  ResponderLocalDataSourceImpl() {
    _store = _seedData();
  }

  late List<Responder> _store;
  final _uuid = const Uuid();

  // ── Interface Implementation ───────────────────────────────────────────────

  @override
  Future<List<Responder>> getAll() async {
    return List.unmodifiable(
      [..._store]..sort((a, b) => a.priority.compareTo(b.priority)),
    );
  }

  @override
  Future<Responder> save(Responder responder) async {
    final idx = _store.indexWhere((r) => r.id == responder.id);
    if (idx == -1) {
      // New responder — assign next available priority.
      final nextPriority =
          _store.isEmpty ? 0 : _store.map((r) => r.priority).reduce((a, b) => a > b ? a : b) + 1;
      final saved = responder.copyWith(priority: nextPriority);
      _store.add(saved);
      return saved;
    } else {
      _store[idx] = responder;
      return responder;
    }
  }

  @override
  Future<void> delete(String id) async {
    _store.removeWhere((r) => r.id == id);
    // Re-normalise priorities after deletion.
    _store.sort((a, b) => a.priority.compareTo(b.priority));
    for (var i = 0; i < _store.length; i++) {
      _store[i] = _store[i].copyWith(priority: i);
    }
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    // Build a lookup map for O(1) access.
    final map = {for (final r in _store) r.id: r};
    final reordered = <Responder>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final r = map[orderedIds[i]];
      if (r != null) reordered.add(r.copyWith(priority: i));
    }
    _store = reordered;
  }

  // ── Seed Data ──────────────────────────────────────────────────────────────

  List<Responder> _seedData() => [
        Responder(
          id: _uuid.v4(),
          name: 'Mom',
          type: ResponderType.family,
          notificationMethods: const [
            NotificationMethod.pushNotification,
            NotificationMethod.sms,
          ],
          phoneNumber: '+91 98765 43210',
        ),
        Responder(
          id: _uuid.v4(),
          name: 'Dr. Sharma',
          type: ResponderType.doctor,
          notificationMethods: const [
            NotificationMethod.phoneCall,
            NotificationMethod.sms,
          ],
          phoneNumber: '+91 99887 76655',
          priority: 1,
        ),
        Responder(
          id: _uuid.v4(),
          name: 'Emergency Services',
          type: ResponderType.emergencyService,
          notificationMethods: const [NotificationMethod.phoneCall],
          phoneNumber: '112',
          priority: 2,
          acknowledgementTimeoutSeconds: 60,
        ),
      ];
}
