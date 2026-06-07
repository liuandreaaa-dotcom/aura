import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'claude_api_service.dart';
import '../memory/memory_service.dart';
import '../tools/tool_base.dart';
import '../../../core/config/app_config.dart';
import '../../../database/database.dart';
import '../../../database/repositories/database_provider.dart';

const _uuid = Uuid();

/// Result from a full agent execution turn
class AgentTurnResult {
  final String assistantMessage;
  final List<ToolResult> toolResults;
  final int inputTokens;
  final int outputTokens;
  final bool hasMoreTurns;

  AgentTurnResult({
    required this.assistantMessage,
    this.toolResults = const [],
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.hasMoreTurns = false,
  });
}

class ToolResult {
  final String toolName;
  final String output;

  ToolResult({required this.toolName, required this.output});
}

class AgentService {
  final ClaudeApiService _llm;
  final AuraDatabase _db;
  final MemoryService _memory;
  final List<BaseTool> _tools;
  final String _conversationId;

  AgentService({
    required ClaudeApiService llm,
    required AuraDatabase db,
    required String conversationId,
    List<BaseTool>? tools,
  })  : _llm = llm,
        _db = db,
        _conversationId = conversationId,
        _tools = tools ?? [],
        _memory = MemoryService(db);

  /// Process a user message and return the assistant's response
  /// Handles the full tool-use loop
  Future<AgentTurnResult> processMessage(String userMessage) async {
    // Build conversation history from DB
    final history = await _db.getMessages(_conversationId);
    final claudeMessages = <ClaudeMessage>[];

    for (final msg in history) {
      if (msg.role == 'user' || msg.role == 'assistant') {
        claudeMessages.add(ClaudeMessage(
          role: msg.role,
          content: msg.content,
        ));
      } else if (msg.role == 'tool') {
        // Skip tool messages in history for context - they'll be re-added during turns
      }
    }

    // Add current user message
    claudeMessages.add(ClaudeMessage(role: 'user', content: userMessage));

    // Get memory context
    final memorySummary = await _memory.getMemorySummary();
    final systemPrompt = AppConfig.defaultSystemPrompt +
        (memorySummary.isNotEmpty ? '\n\n$memorySummary' : '');

    var currentMessages = List<ClaudeMessage>.from(claudeMessages);
    final allToolResults = <ToolResult>[];
    int totalInputTokens = 0;
    int totalOutputTokens = 0;
    String? finalTextContent;

    // Max tool-use iterations to prevent infinite loops
    const maxIterations = 10;
    int iteration = 0;
    ClaudeResponse? response;

    while (iteration < maxIterations) {
      response = await _llm.sendMessage(
        messages: currentMessages,
        systemPrompt: systemPrompt,
        tools: _tools.map((t) => t.toClaudeTool()).toList(),
      );

      totalInputTokens += response.inputTokens;
      totalOutputTokens += response.outputTokens;

      // If no tool calls, we're done
      if (response.toolUses.isEmpty) {
        finalTextContent = response.content;
        break;
      }

      // Process tool calls
      // Add assistant response with tool_use to messages
      final assistantContent = <Map<String, dynamic>>[];
      if (response.content.isNotEmpty) {
        assistantContent.add({'type': 'text', 'text': response.content});
      }
      for (final toolUse in response.toolUses) {
        assistantContent.add(toolUse.toJson());
      }

      currentMessages.add(ClaudeMessage(
        role: 'assistant',
        content: jsonEncode(assistantContent),
      ));

      // Execute each tool and add result
      for (final toolUse in response.toolUses) {
        final tool = _tools.where((t) => t.name == toolUse.name).firstOrNull;
        if (tool == null) {
          currentMessages.add(ClaudeMessage(
            role: 'user',
            content: jsonEncode([
              {
                'type': 'tool_result',
                'tool_use_id': toolUse.id,
                'content': 'Error: Tool "${toolUse.name}" not found',
              }
            ]),
          ));
          allToolResults.add(ToolResult(
            toolName: toolUse.name,
            output: 'Error: Tool not found',
          ));
          continue;
        }

        final result = await tool.execute(toolUse.input);

        // Learn from the interaction
        await _memory.learnFromInteraction(toolUse.name, toolUse.input, result);

        currentMessages.add(ClaudeMessage(
          role: 'user',
          content: jsonEncode([
            {
              'type': 'tool_result',
              'tool_use_id': toolUse.id,
              'content': result,
            }
          ]),
        ));
        allToolResults.add(ToolResult(
          toolName: toolUse.name,
          output: result,
        ));
      }

      iteration++;
    }

    // Get final response if we exited due to iteration limit
    finalTextContent ??= response?.content ?? '处理完成';

    // Try to extract conversation title from first interaction
    if (history.length <= 1) {
      final title = _extractTitle(userMessage, finalTextContent!);
      await _db.updateConversationTitle(_conversationId, title);
    }

    return AgentTurnResult(
      assistantMessage: finalTextContent!,
      toolResults: allToolResults,
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
      hasMoreTurns: iteration >= maxIterations,
    );
  }

  String _extractTitle(String userMsg, String reply) {
    if (userMsg.length <= 20) return userMsg;
    return '${userMsg.substring(0, 20)}...';
  }
}