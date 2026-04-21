import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasap/core/db/db.dart';
import 'package:hasap/core/providers/db_provider.dart';

class CategoryRepository {
  const CategoryRepository(this._db);
  final AppDatabase _db;

  Stream<List<Category>> watchAll() => _db.select(_db.categories).watch();

  Future<List<Category>> getAll() => _db.select(_db.categories).get();

  Future<void> insert(CategoriesCompanion entry) => _db.into(_db.categories).insert(entry);

  Future<void> update(int id, CategoriesCompanion entry) =>
      (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(entry);

  Future<void> delete(int id) =>
      (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(dbProvider)),
);
