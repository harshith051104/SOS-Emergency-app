/// responder_repository_impl.dart
///
/// Concrete [ResponderRepository] backed by [ResponderLocalDataSource].

library;

import '../../domain/entities/responder.dart';
import '../../domain/repositories/responder_repository.dart';
import '../datasources/responder_local_datasource.dart';

class ResponderRepositoryImpl implements ResponderRepository {
  const ResponderRepositoryImpl({required ResponderLocalDataSource dataSource})
      : _dataSource = dataSource;

  final ResponderLocalDataSource _dataSource;

  @override
  Future<List<Responder>> getResponders() => _dataSource.getAll();

  @override
  Future<Responder> saveResponder(Responder responder) =>
      _dataSource.save(responder);

  @override
  Future<void> deleteResponder(String id) => _dataSource.delete(id);

  @override
  Future<void> reorderResponders(List<String> orderedIds) =>
      _dataSource.reorder(orderedIds);
}
