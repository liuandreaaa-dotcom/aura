import '../../../database/database.dart';
import '../../../core/config/app_config.dart';

class MemoryService {
  final AuraDatabase _db;

  MemoryService(this._db);

  /// Get memory summary string for system prompt
  Future<String> getMemorySummary() async {
    return _db.getMemorySummary();
  }

  /// Learn user preferences from tool interactions
  Future<void> learnFromInteraction(
    String toolName,
    Map<String, dynamic> input,
    String result,
  ) async {
    // Extract location preferences
    if (toolName == 'weather' && input.containsKey('location')) {
      await _db.setMemory(
        '常用位置',
        input['location'].toString(),
        category: 'preference',
      );
    }

    // Extract todo patterns
    if (toolName == 'todo_add') {
      final title = input['title']?.toString() ?? '';
      if (title.contains('开会') || title.contains('会议')) {
        await _db.setMemory(
          '工作角色',
          '需要参加各种会议',
          category: 'fact',
        );
      }
    }
  }

  /// Directly set a memory
  Future<void> setMemory(String key, String value, {String? category}) async {
    await _db.setMemory(key, value, category: category);
  }

  /// Get all memories
  Future<List<MemoryEntry>> getAllMemories() async {
    return _db.getAllMemories();
  }

  /// Delete a memory
  Future<void> deleteMemory(String key) async {
    await _db.deleteMemory(key);
  }
}