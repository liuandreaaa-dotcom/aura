import 'package:drift/drift.dart';

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get role => text()(); // 'user' | 'assistant' | 'system' | 'tool'
  TextColumn get content => text()();
  TextColumn get contentType => text().withDefault(const Constant('text'))(); // text | image | tool_call | tool_result
  TextColumn get metadata => text().nullable()(); // JSON string for additional data
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}