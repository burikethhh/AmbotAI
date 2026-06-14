import 'dart:convert';

enum PermissionLevel {
  none,
  read,
  write,
  execute,
  admin,
}

class ToolContext {
  final String workingDirectory;
  final Map<String, dynamic> environment;
  final String sessionId;

  const ToolContext({
    required this.workingDirectory,
    this.environment = const {},
    required this.sessionId,
  });
}

class ToolResult {
  final bool success;
  final String title;
  final String content;
  final Map<String, dynamic>? data;
  final List<String>? warnings;

  const ToolResult({
    required this.success,
    required this.title,
    required this.content,
    this.data,
    this.warnings,
  });

  factory ToolResult.success(String title, String content, {Map<String, dynamic>? data}) {
    return ToolResult(success: true, title: title, content: content, data: data);
  }

  factory ToolResult.failure(String title, String content, {List<String>? warnings}) {
    return ToolResult(success: false, title: title, content: content, warnings: warnings);
  }

  String toJson() => jsonEncode({
    'success': success,
    'title': title,
    'content': content,
    if (data != null) 'data': data,
    if (warnings != null) 'warnings': warnings,
  });
}

abstract class AgentTool {
  String get id;
  String get name;
  String get description;
  String get category;
  PermissionLevel get permissionLevel;
  Map<String, dynamic> get schema;

  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'permissionLevel': permissionLevel.name,
    'schema': schema,
  };
}

class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  void register(AgentTool tool) {
    _tools[tool.id] = tool;
  }

  void registerAll(List<AgentTool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  AgentTool? get(String id) => _tools[id];

  List<AgentTool> get all => _tools.values.toList();

  List<AgentTool> byCategory(String category) {
    return _tools.values.where((t) => t.category == category).toList();
  }

  List<AgentTool> byPermission(PermissionLevel level) {
    final maxIndex = level.index;
    return _tools.values.where((t) => t.permissionLevel.index <= maxIndex).toList();
  }

  Map<String, dynamic> schemaForAll() {
    return {
      'tools': _tools.values.map((t) => t.toJson()).toList(),
    };
  }
}
