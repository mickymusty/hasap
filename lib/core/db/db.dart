import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

enum TransactionType { income, expense }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get type => intEnum<TransactionType>()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _insertDefaultCategories();
    },
  );

  Future<void> _insertDefaultCategories() async {
    final defaults = [
      (name: 'food', icon: '🍔', color: 0xFFFF6B6B),
      (name: 'transport', icon: '🚌', color: 0xFF4ECDC4),
      (name: 'housing', icon: '🏠', color: 0xFF45B7D1),
      (name: 'health', icon: '💊', color: 0xFF96CEB4),
      (name: 'entertainment', icon: '🎮', color: 0xFFFF9F43),
      (name: 'shopping', icon: '🛍️', color: 0xFFA29BFE),
      (name: 'education', icon: '📚', color: 0xFF6C5CE7),
      (name: 'salary', icon: '💰', color: 0xFF00B894),
      (name: 'freelance', icon: '💻', color: 0xFF00CEC9),
      (name: 'other', icon: '📦', color: 0xFFB2BEC3),
    ];
    for (final c in defaults) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: c.name,
          icon: c.icon,
          color: c.color,
          isDefault: const Value(true),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hasap.db'));
    return NativeDatabase.createInBackground(file);
  });
}
