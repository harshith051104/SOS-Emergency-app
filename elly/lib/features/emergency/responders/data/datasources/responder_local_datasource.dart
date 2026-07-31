/// responder_local_datasource.dart
///
/// In-memory data source for [Responder] entities.
/// Pre-loaded with 3 seed responders so the app is useful from first launch.
///
/// Phase 2+: Replace with a SQLite / SharedPreferences / Hive implementation.

library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

/// SharedPreferences implementation seeded with example responders.
class ResponderLocalDataSourceImpl implements ResponderLocalDataSource {
  ResponderLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs {
    _init();
  }

  final SharedPreferences _prefs;
  static const _key = 'responders';
  final _uuid = const Uuid();

  Future<void> _init() async {
    if (!_prefs.containsKey(_key)) {
      await _saveToDisk(_seedData());
    }
  }

  Future<List<Responder>> _loadFromDisk() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Responder.fromJson(e)).toList();
  }

  Future<void> _saveToDisk(List<Responder> responders) async {
    final jsonString = jsonEncode(responders.map((r) => r.toJson()).toList());
    await _prefs.setString(_key, jsonString);
  }

  // ── Interface Implementation ───────────────────────────────────────────────

  @override
  Future<List<Responder>> getAll() async {
    final store = await _loadFromDisk();
    return List.unmodifiable(
      [...store]..sort((a, b) => a.priority.compareTo(b.priority)),
    );
  }

  @override
  Future<Responder> save(Responder responder) async {
    final store = await _loadFromDisk();
    final idx = store.indexWhere((r) => r.id == responder.id);
    if (idx == -1) {
      final nextPriority =
          store.isEmpty ? 0 : store.map((r) => r.priority).reduce((a, b) => a > b ? a : b) + 1;
      final saved = responder.copyWith(priority: nextPriority);
      store.add(saved);
      await _saveToDisk(store);
      return saved;
    } else {
      store[idx] = responder;
      await _saveToDisk(store);
      return responder;
    }
  }

  @override
  Future<void> delete(String id) async {
    final store = await _loadFromDisk();
    store.removeWhere((r) => r.id == id);
    store.sort((a, b) => a.priority.compareTo(b.priority));
    for (var i = 0; i < store.length; i++) {
      store[i] = store[i].copyWith(priority: i);
    }
    await _saveToDisk(store);
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    final store = await _loadFromDisk();
    final map = {for (final r in store) r.id: r};
    final reordered = <Responder>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final r = map[orderedIds[i]];
      if (r != null) reordered.add(r.copyWith(priority: i));
    }
    await _saveToDisk(reordered);
  }

  // ── Seed Data ──────────────────────────────────────────────────────────────

  List<Responder> _seedData() => [
        Responder(
          id: _uuid.v4(),
          name: 'Example Family Member',
          type: ResponderType.family,
          notificationMethods: const [
            NotificationMethod.pushNotification,
            NotificationMethod.sms,
          ],
          phoneNumber: '+15550100123',
        ),
        Responder(
          id: _uuid.v4(),
          name: 'Example Doctor',
          type: ResponderType.doctor,
          notificationMethods: const [
            NotificationMethod.phoneCall,
            NotificationMethod.sms,
          ],
          phoneNumber: '+15550100456',
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
