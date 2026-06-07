import 'dart:convert';
import '../llm/claude_api_service.dart';
import '../../../database/database.dart';

/// Abstract base class for all tools
abstract class BaseTool {
  String get name;
  String get description;
  Map<String, dynamic>? get inputSchema;

  ClaudeTool toClaudeTool() {
    return ClaudeTool(
      name: name,
      description: description,
      inputSchema: inputSchema,
    );
  }

  /// Execute the tool with given input, return result string
  Future<String> execute(Map<String, dynamic> input);
}

/// Weather tool - provides weather information
class WeatherTool extends BaseTool {
  @override
  String get name => 'weather';

  @override
  String get description => '查询指定城市的实时天气和未来预报信息。需要提供城市名称，可选提供日期。';

  @override
  Map<String, dynamic>? get inputSchema => {
    'type': 'object',
    'properties': {
      'location': {
        'type': 'string',
        'description': '城市名称，例如：北京、上海、深圳',
      },
      'date': {
        'type': 'string',
        'description': '日期，格式：YYYY-MM-DD，不提供则查询当天',
      },
    },
    'required': ['location'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    final location = input['location'] ?? '深圳';
    // In production, call a real weather API (e.g., OpenWeatherMap)
    // For now, return a formatted placeholder
    return jsonEncode({
      'location': location,
      'temperature': '28°C',
      'condition': '晴',
      'humidity': '65%',
      'wind': '东南风 3级',
      'forecast': [
        {'date': '今天', 'temp': '26-32°C', 'condition': '晴转多云'},
        {'date': '明天', 'temp': '25-30°C', 'condition': '阵雨'},
        {'date': '后天', 'temp': '24-29°C', 'condition': '多云'},
      ],
    });
  }
}

/// Todo tool - manage to-do items
class TodoAddTool extends BaseTool {
  final Function(String title, {String? description, DateTime? dueDate}) addTodo;

  TodoAddTool({required this.addTodo});

  @override
  String get name => 'todo_add';

  @override
  String get description => '添加一个新的待办事项。需要提供标题，可选提供描述和截止日期。';

  @override
  Map<String, dynamic>? get inputSchema => {
    'type': 'object',
    'properties': {
      'title': {
        'type': 'string',
        'description': '待办事项的标题',
      },
      'description': {
        'type': 'string',
        'description': '待办事项的详细描述',
      },
      'dueDate': {
        'type': 'string',
        'description': '截止日期，格式：YYYY-MM-DD HH:mm',
      },
    },
    'required': ['title'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    final title = input['title'] ?? '';
    DateTime? dueDate;
    if (input['dueDate'] != null) {
      dueDate = DateTime.tryParse(input['dueDate']);
    }
    await addTodo(title, description: input['description'], dueDate: dueDate);
    return jsonEncode({'status': 'success', 'message': '已添加待办事项: $title'});
  }
}

class TodoListTool extends BaseTool {
  final Future<List<Todo>> Function() getTodos;

  TodoListTool({required this.getTodos});

  @override
  String get name => 'todo_list';

  @override
  String get description => '获取所有待办事项列表，包括已完成和未完成的。';

  @override
  Map<String, dynamic>? get inputSchema => {
    'type': 'object',
    'properties': {
      'filter': {
        'type': 'string',
        'description': '过滤条件: all(全部), active(未完成), completed(已完成)',
        'enum': ['all', 'active', 'completed'],
      },
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    final todos = await getTodos();
    final filter = input['filter'] ?? 'active';
    final filtered = todos.where((t) {
      if (filter == 'all') return true;
      if (filter == 'active') return !t.isCompleted;
      if (filter == 'completed') return t.isCompleted;
      return true;
    }).toList();

    return jsonEncode({
      'todos': filtered
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'isCompleted': t.isCompleted,
                'dueDate': t.dueDate?.toIso8601String(),
              })
          .toList(),
      'total': filtered.length,
    });
  }
}

class TodoToggleTool extends BaseTool {
  final Future<void> Function(String id) toggleTodo;

  TodoToggleTool({required this.toggleTodo});

  @override
  String get name => 'todo_toggle';

  @override
  String get description => '标记待办事项为已完成或未完成。需要提供待办事项的ID。';

  @override
  Map<String, dynamic>? get inputSchema => {
    'type': 'object',
    'properties': {
      'id': {
        'type': 'string',
        'description': '待办事项的ID',
      },
    },
    'required': ['id'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    await toggleTodo(input['id']);
    return jsonEncode({'status': 'success', 'message': '已更新待办事项状态'});
  }
}

/// Calendar/Reminder tools
class CalendarAddTool extends BaseTool {
  @override
  String get name => 'calendar_add';

  @override
  String get description => '在日历中创建新的日程事件。需要提供标题和时间。';

  @override
  Map<String, dynamic>? get inputSchema => {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': '日程标题'},
      'startTime': {'type': 'string', 'description': '开始时间，格式：YYYY-MM-DD HH:mm'},
      'endTime': {'type': 'string', 'description': '结束时间，格式：YYYY-MM-DD HH:mm'},
      'location': {'type': 'string', 'description': '地点'},
      'notes': {'type': 'string', 'description': '备注'},
    },
    'required': ['title', 'startTime'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    // In production, use device calendar API or store in local DB
    return jsonEncode({
      'status': 'success',
      'message': '已创建日程: ${input['title']}',
      'event': {
        'title': input['title'],
        'startTime': input['startTime'],
        'endTime': input['endTime'],
        'location': input['location'],
      },
    });
  }
}

/// Reminder tool
class ReminderSetTool extends BaseTool {
  @override
  String get name => 'reminder_set';

  @override
  String get description => '设置一个提醒。需要提供提醒内容和时间。';

  @override
  Map<String, dynamic>? get inputSchema => {
    'type': 'object',
    'properties': {
      'content': {'type': 'string', 'description': '提醒内容'},
      'time': {'type': 'string', 'description': '提醒时间，格式：YYYY-MM-DD HH:mm'},
      'repeat': {
        'type': 'string',
        'description': '重复方式',
        'enum': ['none', 'daily', 'weekly', 'weekday'],
      },
    },
    'required': ['content', 'time'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    // In production, use flutter_local_notifications
    return jsonEncode({
      'status': 'success',
      'message': '已设置提醒: ${input['content']}',
      'reminder': {
        'content': input['content'],
        'time': input['time'],
        'repeat': input['repeat'] ?? 'none',
      },
    });
  }
}