import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'tables/conversations_table.dart';
import 'tables/messages_table.dart';
import 'tables/todos_table.dart';
import 'tables/memory_table.dart';

part 'database.g.dart';

const _uuid = Uuid();

@DriftDatabase(
  tables: [
    Conversations,
    Messages,
    Todos,
    MemoryEntries,
  ],
)
class AuraDatabase extends _$AuraDatabase {
  AuraDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
    );
  }

  // ========== Conversations ==========
  Future<List<Conversation>> getAllConversations() {
    return (select(conversations)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<Conversation> getOrCreateConversation(String? id) async {
    if (id != null) {
      final existing = await (select(conversations)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (existing != null) return existing;
    }
    final newConvId = _uuid.v4();
    final now = DateTime.now();
    final newConv = ConversationsCompanion.insert(
      id: newConvId,
      title: '新对话',
      createdAt: now,
      updatedAt: now,
    );
    await into(conversations).insert(newConv);
    return (await (select(conversations)..where((t) => t.id.equals(newConvId))).getSingle());
  }

  Future<void> updateConversationTitle(String id, String title) async {
    await (update(conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteConversation(String id) async {
    await (delete(messages)..where((t) => t.conversationId.equals(id))).go();
    await (delete(conversations)..where((t) => t.id.equals(id))).go();
  }

  // ========== Messages ==========
  Future<List<Message>> getMessages(String conversationId) {
    return (select(messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<void> insertMessage(MessagesCompanion message) async {
    await into(messages).insert(message);
    final convId = message.conversationId.value;
    await (update(conversations)..where((t) => t.id.equals(convId))).write(
      ConversationsCompanion(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteMessages(String conversationId) async {
    await (delete(messages)..where((t) => t.conversationId.equals(conversationId))).go();
  }

  // ========== Todos ==========
  Future<List<Todo>> getAllTodos() {
    return (select(todos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<Todo>> getActiveTodos() {
    return (select(todos)
          ..where((t) => t.isCompleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> addTodo(String title, {String? description, DateTime? dueDate}) async {
    final now = DateTime.now();
    await into(todos).insert(TodosCompanion.insert(
      id: _uuid.v4(),
      title: title,
      description: Value(description),
      dueDate: Value(dueDate),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> toggleTodo(String id) async {
    final todo = await (select(todos)..where((t) => t.id.equals(id))).getSingle();
    await (update(todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        isCompleted: Value(!todo.isCompleted),
      ),
    );
  }

  Future<void> deleteTodo(String id) async {
    await (delete(todos)..where((t) => t.id.equals(id))).go();
  }

  // ========== Memory ==========
  Future<MemoryEntry?> getMemoryByKey(String key) async {
    return (select(memoryEntries)..where((t) => t.key.equals(key))).getSingleOrNull();
  }

  Future<void> setMemory(String key, String value, {String? category}) async {
    final existing = await getMemoryByKey(key);
    if (existing != null) {
      await (update(memoryEntries)..where((t) => t.key.equals(key))).write(
        MemoryEntriesCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(memoryEntries).insert(MemoryEntriesCompanion.insert(
        id: _uuid.v4(),
        key: key,
        value: value,
        category: Value(category),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<List<MemoryEntry>> getMemoriesByCategory(String category) async {
    return (select(memoryEntries)
          ..where((t) => t.category.equals(category))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<MemoryEntry>> getAllMemories() async {
    return (select(memoryEntries)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> deleteMemory(String key) async {
    await (delete(memoryEntries)..where((t) => t.key.equals(key))).go();
  }

  /// Build a memory summary string for the system prompt
  Future<String> getMemorySummary() async {
    final memories = await getAllMemories();
    if (memories.isEmpty) return '';
    final buf = StringBuffer('\n=== 关于用户的信息 ===\n');
    for (final mem in memories) {
      buf.writeln('- ${mem.key}: ${mem.value}');
    }
    return buf.toString();
  }
}