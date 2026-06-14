import 'dart:io';

enum MentionType { file, folder, shell, command }

class Mention {
  final MentionType type;
  final String value;
  final int startIndex;
  final int endIndex;

  const Mention({
    required this.type,
    required this.value,
    required this.startIndex,
    required this.endIndex,
  });

  String get prefix {
    switch (type) {
      case MentionType.file:
        return '@';
      case MentionType.folder:
        return '#';
      case MentionType.shell:
        return '!';
      case MentionType.command:
        return '/';
    }
  }

  String get displayName => '$prefix$value';
}

class ParsedInput {
  final String rawInput;
  final String cleanText;
  final List<Mention> mentions;
  final Mention? primaryCommand;

  const ParsedInput({
    required this.rawInput,
    required this.cleanText,
    required this.mentions,
    this.primaryCommand,
  });

  bool get hasMentions => mentions.isNotEmpty;
  bool get hasCommand => primaryCommand != null;

  List<Mention> get files => mentions.where((m) => m.type == MentionType.file).toList();
  List<Mention> get folders => mentions.where((m) => m.type == MentionType.folder).toList();
  List<Mention> get shellCommands => mentions.where((m) => m.type == MentionType.shell).toList();
}

class InputParser {
  static final _mentionRegex = RegExp(r'([@#!/])(\S+)');

  static ParsedInput parse(String input) {
    final mentions = <Mention>[];
    Mention? primaryCommand;

    final matches = _mentionRegex.allMatches(input);
    for (final match in matches) {
      final prefix = match.group(1)!;
      final value = match.group(2)!;

      MentionType type;
      switch (prefix) {
        case '@':
          type = MentionType.file;
          break;
        case '#':
          type = MentionType.folder;
          break;
        case '!':
          type = MentionType.shell;
          break;
        case '/':
          type = MentionType.command;
          break;
        default:
          continue;
      }

      final mention = Mention(
        type: type,
        value: value,
        startIndex: match.start,
        endIndex: match.end,
      );

      mentions.add(mention);

      if (type == MentionType.command || type == MentionType.shell) {
        primaryCommand ??= mention;
      }
    }

    String cleanText = input;
    for (final mention in mentions.reversed) {
      cleanText = cleanText.replaceRange(mention.startIndex, mention.endIndex, '');
    }
    cleanText = cleanText.trim();

    return ParsedInput(
      rawInput: input,
      cleanText: cleanText,
      mentions: mentions,
      primaryCommand: primaryCommand,
    );
  }

  static List<String> getCompletions(String partial, String workingDirectory) {
    final completions = <String>[];

    if (partial.startsWith('@')) {
      final path = partial.substring(1);
      completions.addAll(_getFileCompletions(path, workingDirectory));
    } else if (partial.startsWith('#')) {
      final path = partial.substring(1);
      completions.addAll(_getFolderCompletions(path, workingDirectory));
    } else if (partial.startsWith('/')) {
      completions.addAll(_getCommandCompletions(partial));
    }

    return completions;
  }

  static List<String> _getFileCompletions(String path, String workingDirectory) {
    final completions = <String>[];
    try {
      final dir = Directory(workingDirectory);
      if (!dir.existsSync()) return completions;

      final targetPath = path.isEmpty ? workingDirectory : '$workingDirectory/$path';
      final targetDir = Directory(targetPath);

      if (targetDir.existsSync()) {
        for (final entity in targetDir.listSync()) {
          if (entity is File) {
            final name = entity.path.split(Platform.pathSeparator).last;
            completions.add('@$name');
          }
        }
      } else if (path.contains(Platform.pathSeparator)) {
        final parentPath = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
        final parentDir = Directory('$workingDirectory/$parentPath');
        if (parentDir.existsSync()) {
          final prefix = path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
          for (final entity in parentDir.listSync()) {
            final name = entity.path.split(Platform.pathSeparator).last;
            if (name.toLowerCase().startsWith(prefix.toLowerCase())) {
              if (entity is File) {
                completions.add('@$parentPath/$name');
              }
            }
          }
        }
      } else {
        for (final entity in dir.listSync()) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.toLowerCase().startsWith(path.toLowerCase())) {
            if (entity is File) {
              completions.add('@$name');
            }
          }
        }
      }
    } catch (_) {}
    return completions;
  }

  static List<String> _getFolderCompletions(String path, String workingDirectory) {
    final completions = <String>[];
    try {
      final dir = Directory(workingDirectory);
      if (!dir.existsSync()) return completions;

      final targetPath = path.isEmpty ? workingDirectory : '$workingDirectory/$path';
      final targetDir = Directory(targetPath);

      if (targetDir.existsSync()) {
        for (final entity in targetDir.listSync()) {
          if (entity is Directory) {
            final name = entity.path.split(Platform.pathSeparator).last;
            completions.add('#$name');
          }
        }
      } else if (path.contains(Platform.pathSeparator)) {
        final parentPath = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
        final parentDir = Directory('$workingDirectory/$parentPath');
        if (parentDir.existsSync()) {
          final prefix = path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
          for (final entity in parentDir.listSync()) {
            final name = entity.path.split(Platform.pathSeparator).last;
            if (name.toLowerCase().startsWith(prefix.toLowerCase())) {
              if (entity is Directory) {
                completions.add('#$parentPath/$name');
              }
            }
          }
        }
      } else {
        for (final entity in dir.listSync()) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.toLowerCase().startsWith(path.toLowerCase())) {
            if (entity is Directory) {
              completions.add('#$name');
            }
          }
        }
      }
    } catch (_) {}
    return completions;
  }

  static List<String> _getCommandCompletions(String partial) {
    const commands = [
      '/help',
      '/clear',
      '/reset',
      '/model',
      '/agent',
      '/build',
      '/test',
      '/lint',
      '/format',
      '/run',
      '/debug',
      '/explain',
      '/refactor',
      '/commit',
      '/push',
      '/pull',
    ];

    return commands.where((cmd) => cmd.toLowerCase().startsWith(partial.toLowerCase())).toList();
  }
}
