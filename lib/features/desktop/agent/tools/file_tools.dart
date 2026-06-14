import 'dart:io';
import '../agent_tool.dart';

class FilePathSecurity {
  static final List<String> _restrictedPaths = [
    '/etc/passwd',
    '/etc/shadow',
    '/etc/sudoers',
    '/root',
    '/boot',
    '/sys',
    '/proc',
    'C:\\Windows\\System32',
    'C:\\Windows\\SysWOW64',
    'C:\\boot.ini',
    'C:\\pagefile.sys',
    'C:\\hiberfil.sys',
  ];

  static final List<String> _sensitivePatterns = [
    '.env',
    '.ssh',
    '.gnupg',
    '.aws',
    '.azure',
    'credentials',
    'secrets',
    'private_key',
    'id_rsa',
    'id_ed25519',
    '.netrc',
    '.npmrc',
  ];

  static FilePermission checkPath(String path, String workingDirectory) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();

    for (final restricted in _restrictedPaths) {
      if (normalized.startsWith(restricted.toLowerCase())) {
        return FilePermission(
          allowed: false,
          reason: 'Access to system directory restricted: $restricted',
        );
      }
    }

    for (final pattern in _sensitivePatterns) {
      if (normalized.contains(pattern.toLowerCase())) {
        return FilePermission(
          allowed: false,
          reason: 'Access to sensitive file restricted: $pattern',
        );
      }
    }

    if (!normalized.startsWith('/') && !normalized.contains(':')) {
      final fullPath = '$workingDirectory/$normalized'.replaceAll('//', '/');
      return checkPath(fullPath, workingDirectory);
    }

    return FilePermission(allowed: true, reason: 'Path allowed');
  }

  static String sandboxPath(String path, String workingDirectory) {
    final result = checkPath(path, workingDirectory);
    if (!result.allowed) {
      throw SecurityException(result.reason);
    }
    return path;
  }
}

class FilePermission {
  final bool allowed;
  final String reason;

  const FilePermission({
    required this.allowed,
    required this.reason,
  });
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

class ReadFileTool extends AgentTool {
  @override
  String get id => 'read_file';

  @override
  String get name => 'Read File';

  @override
  String get description => 'Read the contents of a file';

  @override
  String get category => 'file';

  @override
  PermissionLevel get permissionLevel => PermissionLevel.read;

  @override
  Map<String, dynamic> get schema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the file to read',
      },
      'offset': {
        'type': 'integer',
        'description': 'Line number to start reading from (0-indexed)',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of lines to read',
      },
    },
    'required': ['path'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context) async {
    try {
      final path = params['path'] as String;
      final offset = params['offset'] as int? ?? 0;
      final limit = params['limit'] as int? ?? 500;

      FilePathSecurity.sandboxPath(path, context.workingDirectory);

      final fullPath = path.startsWith('/') || path.contains(':') ? path : '${context.workingDirectory}/$path';
      final file = File(fullPath);

      if (!await file.exists()) {
        return ToolResult.failure('File not found', 'File does not exist: $path');
      }

      final lines = await file.readAsLines();
      final selectedLines = lines.skip(offset).take(limit).toList();
      final content = selectedLines.join('\n');

      return ToolResult.success(
        'Read ${selectedLines.length} lines',
        content,
        data: {
          'path': path,
          'totalLines': lines.length,
          'offset': offset,
          'limit': limit,
        },
      );
    } on SecurityException catch (e) {
      return ToolResult.failure('Access denied', e.message);
    } catch (e) {
      return ToolResult.failure('Error reading file', e.toString());
    }
  }
}

class WriteFileTool extends AgentTool {
  @override
  String get id => 'write_file';

  @override
  String get name => 'Write File';

  @override
  String get description => 'Write content to a file';

  @override
  String get category => 'file';

  @override
  PermissionLevel get permissionLevel => PermissionLevel.write;

  @override
  Map<String, dynamic> get schema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the file to write',
      },
      'content': {
        'type': 'string',
        'description': 'Content to write to the file',
      },
    },
    'required': ['path', 'content'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context) async {
    try {
      final path = params['path'] as String;
      final content = params['content'] as String;

      FilePathSecurity.sandboxPath(path, context.workingDirectory);

      final fullPath = path.startsWith('/') || path.contains(':') ? path : '${context.workingDirectory}/$path';
      final file = File(fullPath);

      final dirPath = fullPath.substring(0, fullPath.lastIndexOf(Platform.pathSeparator));
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsString(content);

      final lines = content.split('\n').length;
      return ToolResult.success(
        'File written',
        'Successfully wrote $lines lines to $path',
        data: {'path': path, 'lines': lines},
      );
    } on SecurityException catch (e) {
      return ToolResult.failure('Access denied', e.message);
    } catch (e) {
      return ToolResult.failure('Error writing file', e.toString());
    }
  }
}

class EditFileTool extends AgentTool {
  @override
  String get id => 'edit_file';

  @override
  String get name => 'Edit File';

  @override
  String get description => 'Edit specific parts of a file';

  @override
  String get category => 'file';

  @override
  PermissionLevel get permissionLevel => PermissionLevel.write;

  @override
  Map<String, dynamic> get schema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the file to edit',
      },
      'oldString': {
        'type': 'string',
        'description': 'Text to find and replace',
      },
      'newString': {
        'type': 'string',
        'description': 'Replacement text',
      },
      'replaceAll': {
        'type': 'boolean',
        'description': 'Replace all occurrences',
      },
    },
    'required': ['path', 'oldString', 'newString'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context) async {
    try {
      final path = params['path'] as String;
      final oldString = params['oldString'] as String;
      final newString = params['newString'] as String;
      final replaceAll = params['replaceAll'] as bool? ?? false;

      FilePathSecurity.sandboxPath(path, context.workingDirectory);

      final fullPath = path.startsWith('/') || path.contains(':') ? path : '${context.workingDirectory}/$path';
      final file = File(fullPath);

      if (!await file.exists()) {
        return ToolResult.failure('File not found', 'File does not exist: $path');
      }

      var content = await file.readAsString();

      if (!content.contains(oldString)) {
        return ToolResult.failure('Text not found', 'Could not find the specified text in $path');
      }

      if (replaceAll) {
        content = content.replaceAll(oldString, newString);
      } else {
        content = content.replaceFirst(oldString, newString);
      }

      await file.writeAsString(content);

      return ToolResult.success(
        'File edited',
        'Successfully edited $path',
        data: {'path': path, 'replaceAll': replaceAll},
      );
    } on SecurityException catch (e) {
      return ToolResult.failure('Access denied', e.message);
    } catch (e) {
      return ToolResult.failure('Error editing file', e.toString());
    }
  }
}

class ListDirectoryTool extends AgentTool {
  @override
  String get id => 'list_directory';

  @override
  String get name => 'List Directory';

  @override
  String get description => 'List files and folders in a directory';

  @override
  String get category => 'file';

  @override
  PermissionLevel get permissionLevel => PermissionLevel.read;

  @override
  Map<String, dynamic> get schema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the directory to list',
      },
    },
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context) async {
    try {
      final path = params['path'] as String? ?? '.';

      FilePathSecurity.sandboxPath(path, context.workingDirectory);

      final fullPath = path.startsWith('/') || path.contains(':') ? path : '${context.workingDirectory}/$path';
      final dir = Directory(fullPath);

      if (!await dir.exists()) {
        return ToolResult.failure('Directory not found', 'Directory does not exist: $path');
      }

      final entries = await dir.list().toList();
      final items = entries.map((e) {
        final name = e.path.split(Platform.pathSeparator).last;
        final isDir = e is Directory;
        return {
          'name': name,
          'type': isDir ? 'directory' : 'file',
          'path': e.path,
        };
      }).toList();

      items.sort((a, b) {
        if (a['type'] == 'directory' && b['type'] != 'directory') return -1;
        if (a['type'] != 'directory' && b['type'] == 'directory') return 1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      final output = items.map((item) {
        final icon = item['type'] == 'directory' ? '📁' : '📄';
        return '$icon ${item['name']}';
      }).join('\n');

      return ToolResult.success(
        'Listed ${items.length} items',
        output,
        data: {'items': items},
      );
    } on SecurityException catch (e) {
      return ToolResult.failure('Access denied', e.message);
    } catch (e) {
      return ToolResult.failure('Error listing directory', e.toString());
    }
  }
}
