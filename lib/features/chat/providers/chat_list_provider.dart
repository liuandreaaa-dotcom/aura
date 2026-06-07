import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../database/database.dart';
import '../../../database/repositories/database_provider.dart';

const _uuid = Uuid();

/// Provider for creating new conversations and managing the list
final createConversationProvider = FutureProvider.family<String, void>((ref, _) async {
  final db = ref.watch(auraDatabaseProvider);
  final conv = await db.getOrCreateConversation(null);
  return conv.id;
});

/// Provider to delete a conversation
final deleteConversationProvider = FutureProvider.family<void, String>((ref, id) async {
  final db = ref.watch(auraDatabaseProvider);
  await db.deleteConversation(id);
});

/// Refresh provider for conversation list
final refreshConversationsProvider = Provider<void>((ref) {
  ref.invalidate(allConversationsProvider);
});