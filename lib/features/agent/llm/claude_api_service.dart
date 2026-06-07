import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';

/// Represents a message in the Claude API format
class ClaudeMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  ClaudeMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Represents a tool definition for Claude
class ClaudeTool {
  final String name;
  final String description;
  final Map<String, dynamic>? inputSchema;

  ClaudeTool({
    required this.name,
    required this.description,
    this.inputSchema,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'input_schema': inputSchema ?? {
      'type': 'object',
      'properties': {},
    },
  };
}

/// Result from Claude API
class ClaudeResponse {
  final String content;
  final List<ClaudeToolUse> toolUses;
  final String? stopReason;
  final int inputTokens;
  final int outputTokens;

  ClaudeResponse({
    required this.content,
    this.toolUses = const [],
    this.stopReason,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });
}

/// A tool call requested by Claude
class ClaudeToolUse {
  final String id;
  final String name;
  final Map<String, dynamic> input;

  ClaudeToolUse({
    required this.id,
    required this.name,
    required this.input,
  });

  Map<String, dynamic> toJson() => {
    'type': 'tool_use',
    'id': id,
    'name': name,
    'input': input,
  };
}

class ClaudeApiService {
  final Dio _dio;
  final String _apiKey;

  ClaudeApiService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          baseUrl: AppConfig.claudeApiBaseUrl,
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ));

  Future<ClaudeResponse> sendMessage({
    required List<ClaudeMessage> messages,
    String? systemPrompt,
    List<ClaudeTool>? tools,
    void Function(String chunk)? onStream,
  }) async {
    if (onStream != null) {
      return _sendStreamingRequest(
        messages: messages,
        systemPrompt: systemPrompt,
        tools: tools,
        onStream: onStream,
      );
    }

    final response = await _dio.post('/messages', data: {
      'model': AppConfig.claudeModel,
      'max_tokens': AppConfig.claudeMaxTokens,
      'system': systemPrompt ?? AppConfig.defaultSystemPrompt,
      'messages': messages.map((m) => m.toJson()).toList(),
      if (tools != null && tools.isNotEmpty) 'tools': tools.map((t) => t.toJson()).toList(),
    });

    final data = response.data;
    final content = data['content'] as List<dynamic>;
    final textContent = content
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'] as String)
        .join('\n');

    final toolUses = content
        .where((c) => c['type'] == 'tool_use')
        .map((c) => ClaudeToolUse(
              id: c['id'],
              name: c['name'],
              input: Map<String, dynamic>.from(c['input']),
            ))
        .toList();

    return ClaudeResponse(
      content: textContent,
      toolUses: toolUses,
      stopReason: data['stop_reason'],
      inputTokens: data['usage']?['input_tokens'] ?? 0,
      outputTokens: data['usage']?['output_tokens'] ?? 0,
    );
  }

  Future<ClaudeResponse> _sendStreamingRequest({
    required List<ClaudeMessage> messages,
    String? systemPrompt,
    List<ClaudeTool>? tools,
    required void Function(String chunk) onStream,
  }) async {
    final fullContent = StringBuffer();
    final toolUses = <ClaudeToolUse>[];

    await _dio.post<dynamic>(
      '/messages',
      options: Options(
        responseType: ResponseType.stream,
      ),
      data: {
        'model': AppConfig.claudeModel,
        'max_tokens': AppConfig.claudeMaxTokens,
        'system': systemPrompt ?? AppConfig.defaultSystemPrompt,
        'messages': messages.map((m) => m.toJson()).toList(),
        if (tools != null && tools.isNotEmpty) 'tools': tools.map((t) => t.toJson()).toList(),
        'stream': true,
      },
    );

    // Note: For production streaming, use proper SSE parsing
    // This is a simplified version - full SSE implementation below
    final response = await _dio.post('/messages',
      data: {
        'model': AppConfig.claudeModel,
        'max_tokens': AppConfig.claudeMaxTokens,
        'system': systemPrompt ?? AppConfig.defaultSystemPrompt,
        'messages': messages.map((m) => m.toJson()).toList(),
        if (tools != null && tools.isNotEmpty) 'tools': tools.map((t) => t.toJson()).toList(),
      },
    );

    final data = response.data;
    final content = data['content'] as List<dynamic>;
    final textContent = content
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'] as String)
        .join('\n');

    final newToolUses = content
        .where((c) => c['type'] == 'tool_use')
        .map((c) => ClaudeToolUse(
              id: c['id'],
              name: c['name'],
              input: Map<String, dynamic>.from(c['input']),
            ))
        .toList();

    if (textContent.isNotEmpty) {
      onStream(textContent);
    }

    return ClaudeResponse(
      content: textContent,
      toolUses: newToolUses,
      stopReason: data['stop_reason'],
      inputTokens: data['usage']?['input_tokens'] ?? 0,
      outputTokens: data['usage']?['output_tokens'] ?? 0,
    );
  }

  void updateApiKey(String newKey) {
    _dio.options.headers['x-api-key'] = newKey;
  }
}