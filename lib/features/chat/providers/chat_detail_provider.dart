import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'dart:convert';

import '../../../core/theme/app_theme.dart';
import '../../chat/models/message_model.dart';
import '../../agent/llm/claude_api_service.dart';
import '../../agent/llm/agent_service.dart';
import '../../agent/tools/tool_base.dart';
import '../../../database/database.dart';
import '../../../database/repositories/database_provider.dart';

/// Provider for creating AgentService
final agentServiceProvider = Provider.family<AgentService, String>((ref, conversationId) {
  final db = ref.watch(auraDatabaseProvider);
  // Tools will be provided when ChatDetailPage creates the service
  throw UnimplementedError('AgentService must be created with tools');
});

/// State for the chat detail page
class ChatDetailState {
  final List<ChatMessage> messages;
  final bool isProcessing;
  final bool isLoading;
  final String? error;

  const ChatDetailState({
    this.messages = const [],
    this.isProcessing = false,
    this.isLoading = true,
    this.error,
  });

  ChatDetailState copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
    bool? isLoading,
    String? error,
  }) {
    return ChatDetailState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  final AuraDatabase _db;
  final String _conversationId;
  AgentService? _agentService;

  ChatDetailNotifier(this._db, this._conversationId) : super(const ChatDetailState()) {
    _loadMessages();
  }

  void initAgent(AgentService agent) {
    _agentService = agent;
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _db.getMessages(_conversationId);
      final chatMessages = msgs
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => ChatMessage(
                id: m.id,
                role: m.role,
                content: m.content,
                contentType: m.contentType,
                createdAt: m.createdAt,
              ))
          .toList();
      state = state.copyWith(messages: chatMessages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isProcessing) return;

    final userMsg = ChatMessage(
      id: _generateId(),
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isProcessing: true,
      error: null,
    );

    // Save user message to DB
    await _db.insertMessage(MessagesCompanion.insert(
      id: userMsg.id,
      conversationId: _conversationId,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    ));

    if (_agentService == null) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Agent not initialized. Please check your API key in Settings.',
      );
      return;
    }

    try {
      final result = await _agentService!.processMessage(text);

      final assistantMsg = ChatMessage(
        id: _generateId(),
        role: 'assistant',
        content: result.assistantMessage,
        createdAt: DateTime.now(),
      );

      // Save assistant message
      await _db.insertMessage(MessagesCompanion.insert(
        id: assistantMsg.id,
        conversationId: _conversationId,
        role: 'assistant',
        content: result.assistantMessage,
        createdAt: DateTime.now(),
      ));

      // Save tool results as tool messages
      for (final toolResult in result.toolResults) {
        await _db.insertMessage(MessagesCompanion.insert(
          id: _generateId(),
          conversationId: _conversationId,
          role: 'tool',
          content: '${toolResult.toolName}: ${toolResult.output}',
          contentType: Value('tool_result'),
          createdAt: DateTime.now(),
        ));
      }

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: '抱歉，处理消息时出错: $e',
      );
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${state.messages.length}';
  }
}

final chatDetailProvider =
    StateNotifierProvider.family<ChatDetailNotifier, ChatDetailState, String>(
  (ref, conversationId) {
    final db = ref.watch(auraDatabaseProvider);
    return ChatDetailNotifier(db, conversationId);
  },
);