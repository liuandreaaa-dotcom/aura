import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database.dart';

final auraDatabaseProvider = Provider<AuraDatabase>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

// Chat providers
final allConversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final db = ref.watch(auraDatabaseProvider);
  return db.getAllConversations();
});

class MessageNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final AuraDatabase _db;
  final String _conversationId;

  MessageNotifier(this._db, this._conversationId) : super(const AsyncValue.loading()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.getMessages(_conversationId));
  }

  Future<void> addMessage(MessagesCompanion message) async {
    await _db.insertMessage(message);
    await loadMessages();
  }
}

final messagesProvider = StateNotifierProvider.family<MessageNotifier, AsyncValue<List<Message>>, String>(
  (ref, conversationId) {
    final db = ref.watch(auraDatabaseProvider);
    return MessageNotifier(db, conversationId);
  },
);

// Todo providers
final allTodosProvider = FutureProvider<List<Todo>>((ref) async {
  final db = ref.watch(auraDatabaseProvider);
  return db.getAllTodos();
});

final activeTodosProvider = FutureProvider<List<Todo>>((ref) async {
  final db = ref.watch(auraDatabaseProvider);
  return db.getActiveTodos();
});

// Memory providers
final allMemoriesProvider = FutureProvider<List<MemoryEntry>>((ref) async {
  final db = ref.watch(auraDatabaseProvider);
  return db.getAllMemories();
});

final memorySummaryProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(auraDatabaseProvider);
  return db.getMemorySummary();
});