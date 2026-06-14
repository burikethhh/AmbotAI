import 'dart:async';
import 'dart:io';
import '../agent_tool.dart';

class ShellTool extends AgentTool {
  @override
  String get id => 'shell';

  @override
  String get name => 'Shell Command';

  @override
  String get description => 'Execute a shell command';

  @override
  String get category => 'system';

  @override
  PermissionLevel get permissionLevel => PermissionLevel.execute;

  @override
  Map<String, dynamic> get schema => {
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'description': 'Shell command to execute',
      },
      'timeout': {
        'type': 'integer',
        'description': 'Timeout in seconds (default: 30)',
      },
    },
    'required': ['command'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context) async {
    try {
      final command = params['command'] as String;
      final timeout = params['timeout'] as int? ?? 30;

      final isWindows = Platform.isWindows;
      final shell = isWindows ? 'powershell' : 'bash';
      final args = isWindows ? ['-Command', command] : ['-c', command];

      final result = await Process.run(
        shell,
        args,
        workingDirectory: context.workingDirectory,
      ).timeout(
        Duration(seconds: timeout),
        onTimeout: () {
          throw TimeoutException('Command timed out after ${timeout}s');
        },
      );

      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      final exitCode = result.exitCode;

      final output = StringBuffer();
      if (stdout.isNotEmpty) output.write(stdout);
      if (stderr.isNotEmpty) {
        if (output.isNotEmpty) output.write('\n');
        output.write('STDERR:\n$stderr');
      }

      if (exitCode != 0) {
        return ToolResult.failure(
          'Command failed (exit code: $exitCode)',
          output.toString(),
          warnings: [stderr],
        );
      }

      return ToolResult.success(
        'Command executed',
        output.isEmpty ? '(no output)' : output.toString(),
        data: {
          'command': command,
          'exitCode': exitCode,
          'stdout': stdout,
          'stderr': stderr,
        },
      );
    } on TimeoutException catch (e) {
      return ToolResult.failure('Command timed out', e.message ?? 'Unknown timeout');
    } catch (e) {
      return ToolResult.failure('Error executing command', e.toString());
    }
  }
}

class SearchFilesTool extends AgentTool {
  @override
  String get id => 'search_files';

  @override
  String get name => 'Search Files';

  @override
  String get description => 'Search for files by name pattern';

  @override
  String get category => 'file';

  @override
  PermissionLevel get permissionLevel => PermissionLevel.read;

  @override
  Map<String, dynamic> get schema => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Glob pattern to match files',
      },
      'path': {
        'type': 'string',
        'description': 'Directory to search in',
      },
    },
    'required': ['pattern'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context) async {
    try {
      final pattern = params['pattern'] as String;
      final searchPath = params['path'] as String? ?? '.';

      final fullPath = searchPath.startsWith('/') || searchPath.contains(':') ? searchPath : '$context.workingDirectory/$searchPath';
      final dir = Directory(fullPath);

      if (!await dir.exists()) {
        return ToolResult.failure('Directory not found', 'Directory does not exist: $searchPath');
      }

      final matches = <String>[];
      await for (final entity in dir.list(recursive: true)) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (_matchesPattern(name, pattern)) {
          matches.add(entity.path);
        }
      }

      if (matches.isEmpty) {
        return ToolResult.success('No matches', 'No files found matching: $pattern');
      }

      return ToolResult.success(
        'Found ${matches.length} matches',
        matches.join('\n'),
        data: {'matches': matches},
      );
    } catch (e) {
      return ToolResult.failure('Error searching files', e.toString());
    }
  }

  bool _matchesPattern(String name, String pattern) {
    var regexPattern = pattern;
    regexPattern = regexPattern.replaceAll('.', '\\.');
    regexPattern = regexPattern.replaceAll('*', '.*');
    regexPattern = regexPattern.replaceAll('?', '.');
    final regex = RegExp('^' + regexPattern + '\$', caseSensitive: false);
    return regex.hasMatch(name);
  }
}

class GrepTool extends AgentTool {
  @override
  String get id => 'grep';

  @override
  String get name => 'Search in Files';

  @override
  String get description => 'Search for text patterns in file contents';

  @override
  String get category => 'file';

  @override
  PermissionLevel get permissionLevel => PermissionLevel.read;

  @override
  Map<String, dynamic> get schema => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Regex pattern to search for',
      },
      'path': {
        'type': 'string',
        'description': 'Directory to search in',
      },
      'include': {
        'type': 'string',
        'description': 'File pattern to include (e.g., "*.dart")',
      },
    },
    'required': ['pattern'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context) async {
    try {
      final pattern = params['pattern'] as String;
      final searchPath = params['path'] as String? ?? '.';
      final include = params['include'] as String?;

      final fullPath = searchPath.startsWith('/') || searchPath.contains(':') ? searchPath : '$context.workingDirectory/$searchPath';
      final dir = Directory(fullPath);

      if (!await dir.exists()) {
        return ToolResult.failure('Directory not found', 'Directory does not exist: $searchPath');
      }

      final regex = RegExp(pattern, caseSensitive: false);
      final results = <Map<String, dynamic>>[];

      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        if (include != null && !_matchesInclude(entity.path.split(Platform.pathSeparator).last, include)) continue;

        try {
          final content = await entity.readAsString();
          final lines = content.split('\n');
          for (var i = 0; i < lines.length; i++) {
            if (regex.hasMatch(lines[i])) {
              results.add({
                'file': entity.path,
                'line': i + 1,
                'content': lines[i].trim(),
              });
            }
          }
        } catch (_) {
          // Skip binary or unreadable files
        }
      }

      if (results.isEmpty) {
        return ToolResult.success('No matches', 'No matches found for: $pattern');
      }

      final output = results.map((r) {
        return '${r['file']}:${r['line']}: ${r['content']}';
      }).join('\n');

      return ToolResult.success(
        'Found ${results.length} matches',
        output,
        data: {'results': results},
      );
    } catch (e) {
      return ToolResult.failure('Error searching', e.toString());
    }
  }

  bool _matchesInclude(String name, String pattern) {
    var regexPattern = pattern;
    regexPattern = regexPattern.replaceAll('.', '\\.');
    regexPattern = regexPattern.replaceAll('*', '.*');
    regexPattern = regexPattern.replaceAll('?', '.');
    final regex = RegExp('^' + regexPattern + '\$', caseSensitive: false);
    return regex.hasMatch(name);
  }
}
