/// responder_repository.dart
///
/// Abstract contract for persisting and retrieving [Responder] configurations.
/// The domain layer depends on this interface; the data layer provides the impl.

library;

import '../entities/responder.dart';

/// Repository contract for [Responder] CRUD + ordering.
abstract class ResponderRepository {
  /// Returns all responders sorted by [Responder.priority] ascending.
  Future<List<Responder>> getResponders();

  /// Inserts or updates a responder.
  /// If a responder with [responder.id] already exists, it is replaced.
  Future<Responder> saveResponder(Responder responder);

  /// Permanently removes the responder identified by [id].
  /// No-op if [id] is not found.
  Future<void> deleteResponder(String id);

  /// Updates the priority of all responders to match the given [orderedIds].
  ///
  /// [orderedIds] must contain the exact IDs of all existing responders
  /// (no extras, no missing). The first ID gets priority 0.
  Future<void> reorderResponders(List<String> orderedIds);
}
