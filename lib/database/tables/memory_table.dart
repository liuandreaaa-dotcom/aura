import 'package:drift/drift.dart';

class MemoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get category => text().nullable()(); // 'preference' | 'fact' | 'habit' | 'contact'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}