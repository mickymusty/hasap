import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasap/core/db/db.dart';
import 'package:hasap/core/providers/db_provider.dart';

enum PeriodFilter { today, week, month, all }

class TransactionRepository {
  const TransactionRepository(this._db);
  final AppDatabase _db;

  Stream<List<TransactionWithCategory>> watchAll(PeriodFilter period) {
    final query = _db.select(_db.transactions).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
    ]);

    final now = DateTime.now();
    switch (period) {
      case PeriodFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        query.where(_db.transactions.date.isBiggerOrEqualValue(start));
      case PeriodFilter.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        query.where(_db.transactions.date.isBiggerOrEqualValue(DateTime(start.year, start.month, start.day)));
      case PeriodFilter.month:
        final start = DateTime(now.year, now.month, 1);
        query.where(_db.transactions.date.isBiggerOrEqualValue(start));
      case PeriodFilter.all:
        break;
    }

    query.orderBy([OrderingTerm.desc(_db.transactions.date)]);

    return query.watch().map(
      (rows) => rows.map((row) => TransactionWithCategory(
        transaction: row.readTable(_db.transactions),
        category: row.readTable(_db.categories),
      )).toList(),
    );
  }

  Future<void> insert(TransactionsCompanion entry) => _db.into(_db.transactions).insert(entry);

  Future<void> update(int id, TransactionsCompanion entry) =>
      (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(entry);

  Future<void> delete(int id) =>
      (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

  Future<Transaction?> getById(int id) =>
      (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
}

class TransactionWithCategory {
  const TransactionWithCategory({required this.transaction, required this.category});
  final Transaction transaction;
  final Category category;
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(dbProvider)),
);
