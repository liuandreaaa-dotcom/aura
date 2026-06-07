import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'Aura';
  static const String appVersion = '1.0.0';

  // Claude API
  static const String claudeApiBaseUrl = 'https://api.anthropic.com/v1';
  static const String claudeModel = 'claude-sonnet-4-6-20251001';
  static const int claudeMaxTokens = 4096;

  // Database
  static String dbPath = '';
  static const String dbName = 'aura_database.db';

  // Secure storage keys
  static const String apiKeyStorageKey = 'claude_api_key';
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    dbPath = dir.path;
  }

  static Future<String?> getApiKey() async {
    return await secureStorage.read(key: apiKeyStorageKey);
  }

  static Future<void> saveApiKey(String key) async {
    await secureStorage.write(key: apiKeyStorageKey, value: key);
  }

  static Future<void> deleteApiKey() async {
    await secureStorage.delete(key: apiKeyStorageKey);
  }

  static String get defaultSystemPrompt => '''
你是 Aura，用户的 AI 个人助手。
你的目标是帮助用户高效处理工作、学习和生活中的各种事务。

核心原则：
1. 友好、温暖、专业 - 像可靠的伙伴一样交流
2. 结合上下文给出个性化回复
3. 主动利用可用工具帮助用户完成任务
4. 如果缺少信息，主动询问用户

你有以下能力：
- 日常对话与咨询
- 管理待办事项和提醒
- 查询天气信息
- 管理日历事件
- 提供建议和规划

回复风格：
- 使用用户使用的语言回复
- 简洁有条理，重要内容突出
- 需要用户确认时才询问，否则直接给出结果
''';
}