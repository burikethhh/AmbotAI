import 'dart:async';

enum CommandType {
  help,
  clear,
  reset,
  model,
  agent,
  build,
  test,
  lint,
  format,
  run,
  debug,
  explain,
  refactor,
  commit,
  push,
  pull,
  unknown,
}

class CommandResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const CommandResult({
    required this.success,
    required this.message,
    this.data,
  });

  factory CommandResult.ok(String message, {Map<String, dynamic>? data}) {
    return CommandResult(success: true, message: message, data: data);
  }

  factory CommandResult.error(String message) {
    return CommandResult(success: false, message: message);
  }
}

class AgentCommand {
  final CommandType type;
  final String name;
  final String description;
  final List<String> aliases;

  const AgentCommand({
    required this.type,
    required this.name,
    required this.description,
    this.aliases = const [],
  });
}

class CommandHandler {
  final Map<CommandType, AgentCommand> _commands = {};
  final Map<String, CommandType> _aliases = {};

  CommandHandler() {
    _registerDefaults();
  }

  void _registerDefaults() {
    register(const AgentCommand(
      type: CommandType.help,
      name: 'help',
      description: 'Show available commands',
      aliases: ['h', '?'],
    ));
    register(const AgentCommand(
      type: CommandType.clear,
      name: 'clear',
      description: 'Clear conversation history',
      aliases: ['cls'],
    ));
    register(const AgentCommand(
      type: CommandType.reset,
      name: 'reset',
      description: 'Reset agent state',
    ));
    register(const AgentCommand(
      type: CommandType.model,
      name: 'model',
      description: 'Switch or show current model',
      aliases: ['m'],
    ));
    register(const AgentCommand(
      type: CommandType.agent,
      name: 'agent',
      description: 'Switch agent type',
      aliases: ['a'],
    ));
    register(const AgentCommand(
      type: CommandType.build,
      name: 'build',
      description: 'Build the project',
      aliases: ['b'],
    ));
    register(const AgentCommand(
      type: CommandType.test,
      name: 'test',
      description: 'Run tests',
      aliases: ['t'],
    ));
    register(const AgentCommand(
      type: CommandType.lint,
      name: 'lint',
      description: 'Run linter',
    ));
    register(const AgentCommand(
      type: CommandType.format,
      name: 'format',
      description: 'Format code',
      aliases: ['fmt'],
    ));
    register(const AgentCommand(
      type: CommandType.run,
      name: 'run',
      description: 'Run a command',
      aliases: ['r'],
    ));
    register(const AgentCommand(
      type: CommandType.debug,
      name: 'debug',
      description: 'Debug an issue',
      aliases: ['d'],
    ));
    register(const AgentCommand(
      type: CommandType.explain,
      name: 'explain',
      description: 'Explain code or concept',
      aliases: ['e'],
    ));
    register(const AgentCommand(
      type: CommandType.refactor,
      name: 'refactor',
      description: 'Refactor code',
      aliases: ['rf'],
    ));
    register(const AgentCommand(
      type: CommandType.commit,
      name: 'commit',
      description: 'Create a git commit',
    ));
    register(const AgentCommand(
      type: CommandType.push,
      name: 'push',
      description: 'Push to remote',
    ));
    register(const AgentCommand(
      type: CommandType.pull,
      name: 'pull',
      description: 'Pull from remote',
    ));
  }

  void register(AgentCommand command) {
    _commands[command.type] = command;
    _aliases[command.name] = command.type;
    for (final alias in command.aliases) {
      _aliases[alias] = command.type;
    }
  }

  CommandType? resolveCommand(String name) {
    return _aliases[name.toLowerCase()];
  }

  AgentCommand? getCommand(CommandType type) {
    return _commands[type];
  }

  List<AgentCommand> get allCommands => _commands.values.toList();

  Future<CommandResult> execute(String input) async {
    final parts = input.trim().split(' ');
    if (parts.isEmpty || !parts[0].startsWith('/')) {
      return CommandResult.error('Not a command');
    }

    final commandName = parts[0].substring(1);
    final args = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final type = resolveCommand(commandName);
    if (type == null) {
      return CommandResult.error('Unknown command: /$commandName');
    }

    return _executeCommand(type, args);
  }

  Future<CommandResult> _executeCommand(CommandType type, String args) async {
    switch (type) {
      case CommandType.help:
        return _handleHelp();
      case CommandType.clear:
        return CommandResult.ok('Conversation cleared');
      case CommandType.reset:
        return CommandResult.ok('Agent state reset');
      case CommandType.model:
        return _handleModel(args);
      case CommandType.agent:
        return _handleAgent(args);
      case CommandType.build:
        return CommandResult.ok('Build started...');
      case CommandType.test:
        return CommandResult.ok('Tests running...');
      case CommandType.lint:
        return CommandResult.ok('Linting...');
      case CommandType.format:
        return CommandResult.ok('Formatting...');
      case CommandType.run:
        return CommandResult.ok('Running: $args');
      case CommandType.debug:
        return CommandResult.ok('Debugging: $args');
      case CommandType.explain:
        return CommandResult.ok('Explaining: $args');
      case CommandType.refactor:
        return CommandResult.ok('Refactoring: $args');
      case CommandType.commit:
        return CommandResult.ok('Committing changes...');
      case CommandType.push:
        return CommandResult.ok('Pushing to remote...');
      case CommandType.pull:
        return CommandResult.ok('Pulling from remote...');
      default:
        return CommandResult.error('Unknown command');
    }
  }

  CommandResult _handleHelp() {
    final buffer = StringBuffer();
    buffer.writeln('Available commands:');
    buffer.writeln('');
    for (final cmd in allCommands) {
      buffer.writeln('/${cmd.name.padRight(12)} ${cmd.description}');
      if (cmd.aliases.isNotEmpty) {
        buffer.writeln('${''.padRight(12)} Aliases: ${cmd.aliases.join(', ')}');
      }
    }
    return CommandResult.ok(buffer.toString());
  }

  CommandResult _handleModel(String args) {
    if (args.isEmpty) {
      return CommandResult.ok('Current model: Llama 3 8B');
    }
    return CommandResult.ok('Switching to model: $args');
  }

  CommandResult _handleAgent(String args) {
    if (args.isEmpty) {
      return CommandResult.ok('Current agent: Build');
    }
    final validTypes = ['build', 'plan', 'refactor', 'debug', 'document'];
    if (!validTypes.contains(args.toLowerCase())) {
      return CommandResult.error('Invalid agent type. Valid: ${validTypes.join(', ')}');
    }
    return CommandResult.ok('Switching to agent: $args');
  }
}
