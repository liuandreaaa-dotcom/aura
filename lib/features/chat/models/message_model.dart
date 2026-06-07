import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String role, // 'user' | 'assistant' | 'system' | 'tool'
    required String content,
    @Default('text') String contentType, // text | image | tool_call | tool_result
    String? metadata, // JSON string
    @Default(false) bool isStreaming,
    DateTime? createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

@freezed
class ConversationSummary with _$ConversationSummary {
  const factory ConversationSummary({
    required String id,
    required String title,
    String? lastMessage,
    required DateTime updatedAt,
    @Default(0) int messageCount,
  }) = _ConversationSummary;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      _$ConversationSummaryFromJson(json);
}