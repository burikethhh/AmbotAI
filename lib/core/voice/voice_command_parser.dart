import '../device_control/action.dart';
import '../device_control/action_registry.dart';
import '../device_control/app_registry.dart';

/// Parses natural language speech into structured [DeviceAction] intents.
///
/// This is a rule-based parser that handles common voice command patterns.
/// For complex or ambiguous commands, it falls back to a generic "search"
/// action that lets the AI figure it out.
class VoiceCommandParser {
  VoiceCommandParser._();

  /// Parse spoken text into a list of device actions.
  /// Returns empty list if no recognizable command pattern matched.
  static List<ParsedVoiceCommand> parse(String speech) {
    final lower = speech.toLowerCase().trim();
    final commands = <ParsedVoiceCommand>[];

    // Try each pattern in priority order
    commands.addAll(_parseAppLaunch(lower, speech));
    commands.addAll(_parseCommunication(lower, speech));
    commands.addAll(_parseSystemControl(lower, speech));
    commands.addAll(_parseNavigation(lower, speech));
    commands.addAll(_parseInformation(lower, speech));
    commands.addAll(_parseTimerAlarm(lower, speech));
    commands.addAll(_parseVolumeBrightness(lower, speech));

    // If nothing matched, return a generic search command
    if (commands.isEmpty && lower.isNotEmpty) {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('web_search')!,
        params: {'query': speech},
        confidence: 0.3,
        spokenResponse: "Searching for '$speech'",
      ));
    }

    return commands;
  }

  // --- App Launch ---

  static List<ParsedVoiceCommand> _parseAppLaunch(String lower, String original) {
    final commands = <ParsedVoiceCommand>[];

    // "open [app]" / "launch [app]" / "start [app]"
    final openMatch = RegExp(
      r'\b(?:open|launch|start|go to)\s+(.+?)(?:\s*\.?\s*)$',
    ).firstMatch(lower);
    if (openMatch != null) {
      final appName = openMatch.group(1)!.trim();
      final entry = AppRegistry.findMatch(appName);
      if (entry != null) {
        commands.add(ParsedVoiceCommand(
          action: ActionRegistry.byId('launch_app')!,
          params: {
            'packageName': entry.packageName,
            'altPackages': entry.altPackages,
            'displayName': entry.displayName,
          },
          confidence: 0.9,
          spokenResponse: 'Opening ${entry.displayName}',
        ));
      } else {
        // Try direct keyword match (user said just the app name)
        final directEntry = AppRegistry.findMatch(lower);
        if (directEntry != null) {
          commands.add(ParsedVoiceCommand(
            action: ActionRegistry.byId('launch_app')!,
            params: {
              'packageName': directEntry.packageName,
              'altPackages': directEntry.altPackages,
              'displayName': directEntry.displayName,
            },
            confidence: 0.85,
            spokenResponse: 'Opening ${directEntry.displayName}',
          ));
        } else {
          // Fallback to old heuristic
          commands.add(ParsedVoiceCommand(
            action: ActionRegistry.byId('launch_app')!,
            params: {'packageName': _appKeywordToPackage(appName)},
            confidence: 0.5,
            spokenResponse: 'Trying to open $appName',
          ));
        }
      }
    }

    // Direct app name without "open" prefix (e.g., just "Facebook")
    if (commands.isEmpty) {
      final entry = AppRegistry.findMatch(lower);
      if (entry != null) {
        commands.add(ParsedVoiceCommand(
          action: ActionRegistry.byId('launch_app')!,
          params: {
            'packageName': entry.packageName,
            'altPackages': entry.altPackages,
            'displayName': entry.displayName,
          },
          confidence: 0.8,
          spokenResponse: 'Opening ${entry.displayName}',
        ));
      }
    }

    return commands;
  }

  // --- Communication ---

  static List<ParsedVoiceCommand> _parseCommunication(String lower, String original) {
    final commands = <ParsedVoiceCommand>[];

    // "type [text]" / "write [text]" / "enter [text]"
    final typeMatch = RegExp(
      r'\b(?:type|write|enter|input)\s+(?:the\s+)?(?:text\s+)?["\x27]?(.+?)["\x27]?\s*\.?\s*$',
    ).firstMatch(lower);
    if (typeMatch != null) {
      final text = typeMatch.group(1)!.trim();
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('type_text')!,
        params: {'text': text},
        confidence: 0.85,
        spokenResponse: 'Typing "$text"',
      ));
    }

    // "send [message] to [contact]" / "text [contact] [message]"
    final sendMatch = RegExp(
      r'\b(?:send|text|message)\s+(?:a\s+)?(?:message\s+)?(.+?)\s+to\s+(.+)',
    ).firstMatch(lower);
    if (sendMatch != null) {
      final message = sendMatch.group(1)!.trim();
      final contact = sendMatch.group(2)!.trim();
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('send_sms')!,
        params: {'recipient': contact, 'message': message},
        confidence: 0.75,
        spokenResponse: 'Sending "$message" to $contact',
      ));
    }

    // "call [contact]"
    final callMatch = RegExp(r'\bcall\s+(.+?)\.?$').firstMatch(lower);
    if (callMatch != null) {
      final contact = callMatch.group(1)!.trim();
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('launch_app')!,
        params: {'packageName': 'com.android.dialer'},
        confidence: 0.6,
        spokenResponse: 'Calling $contact',
      ));
    }

    // "read my last message" / "read messages"
    if (lower.contains('read') && (lower.contains('message') || lower.contains('text'))) {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('launch_app')!,
        params: {'packageName': 'com.google.android.apps.messaging'},
        confidence: 0.5,
        spokenResponse: 'Opening messages',
      ));
    }

    // "open email" / "check email"
    if (lower.contains('email') || lower.contains('gmail')) {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('launch_app')!,
        params: {'packageName': 'com.google.android.gm'},
        confidence: 0.8,
        spokenResponse: 'Opening email',
      ));
    }

    return commands;
  }

  // --- System Control ---

  static List<ParsedVoiceCommand> _parseSystemControl(String lower, String original) {
    final commands = <ParsedVoiceCommand>[];

    // "turn on/off [setting]"
    final toggleMatch = RegExp(
      r'\b(?:turn|switch)\s+(on|off|enable|disable)\s+(\w+)',
    ).firstMatch(lower);
    if (toggleMatch != null) {
      final isOn = toggleMatch.group(1)!.toLowerCase() == 'on' || toggleMatch.group(1)!.toLowerCase() == 'enable';
      final setting = toggleMatch.group(2)!.toLowerCase();
      final settingKey = _settingKeyword(setting);
      if (settingKey != null) {
        final actionId = settingKey == 'flashlight' ? 'toggle_flashlight' : 'toggle_wifi';
        commands.add(ParsedVoiceCommand(
          action: ActionRegistry.byId(actionId)!,
          params: {'setting': settingKey, 'value': isOn},
          confidence: 0.85,
          spokenResponse: 'Turning $settingKey ${isOn ? "on" : "off"}',
        ));
      }
    }

    // Direct toggle commands: "flashlight on/off", "wifi on/off", "dnd on/off"
    if (commands.isEmpty) {
      final directToggle = RegExp(
        r'\b(flashlight|wifi|bluetooth|dnd|do not disturb|location)\s+(on|off|enable|disable)\b',
      ).firstMatch(lower);
      if (directToggle != null) {
        final setting = directToggle.group(1)!.toLowerCase();
        final isOn = directToggle.group(2)!.toLowerCase() == 'on' || directToggle.group(2)!.toLowerCase() == 'enable';
        final settingKey = _settingKeyword(setting);
        if (settingKey != null) {
          final actionId = settingKey == 'flashlight' ? 'toggle_flashlight'
              : settingKey == 'wifi' ? 'toggle_wifi'
              : settingKey == 'bluetooth' ? 'toggle_bluetooth'
              : settingKey == 'dnd' ? 'toggle_dnd'
              : 'toggle_wifi';
          commands.add(ParsedVoiceCommand(
            action: ActionRegistry.byId(actionId)!,
            params: {'setting': settingKey, 'value': isOn},
            confidence: 0.85,
            spokenResponse: 'Turning $settingKey ${isOn ? "on" : "off"}',
          ));
        }
      }
    }

    // "silence my phone" / "silent mode" -> DND on
    if (commands.isEmpty && (lower.contains('silence') || lower.contains('silent'))) {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('toggle_dnd')!,
        params: {'setting': 'dnd', 'value': true},
        confidence: 0.8,
        spokenResponse: 'Enabling silent mode',
      ));
    }

    // "max volume" / "full volume"
    if (lower.contains('max volume') || lower.contains('full volume') || lower.contains('maximum volume')) {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('set_volume')!,
        params: {'stream': 'media', 'level': 100},
        confidence: 0.9,
        spokenResponse: 'Setting volume to maximum',
      ));
    }

    // "mute" / "mute phone"
    if (lower == 'mute' || lower.contains('mute phone') || lower == 'mute.') {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('set_volume')!,
        params: {'stream': 'media', 'level': 0},
        confidence: 0.9,
        spokenResponse: 'Muting volume',
      ));
    }

    // "what's on my screen?" / "read this to me"
    if (lower.contains("what's on my screen") ||
        lower.contains('read this') ||
        lower.contains('read screen')) {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('read_screen')!,
        params: {},
        confidence: 0.9,
        spokenResponse: 'Reading the screen for you',
      ));
    }

    return commands;
  }

  // --- Navigation ---

  static List<ParsedVoiceCommand> _parseNavigation(String lower, String original) {
    final commands = <ParsedVoiceCommand>[];

    // "go back"
    if (lower == 'go back' || lower == 'back' || lower == 'go back.') {
      commands.add(ParsedVoiceCommand(
        action: DeviceAction(
          id: 'go_back',
          label: 'Go Back',
          description: 'Navigate back.',
          risk: ActionRisk.safe,
          category: ActionCategory.navigation,
          method: 'goBack',
          confirmationMessage: 'Go back?',
        ),
        params: {},
        confidence: 0.95,
        spokenResponse: 'Going back',
      ));
    }

    // "go home"
    if (lower == 'go home' || lower == 'home' || lower == 'go home.') {
      commands.add(ParsedVoiceCommand(
        action: DeviceAction(
          id: 'go_home',
          label: 'Go Home',
          description: 'Navigate to home screen.',
          risk: ActionRisk.safe,
          category: ActionCategory.navigation,
          method: 'goHome',
          confirmationMessage: 'Go to home screen?',
        ),
        params: {},
        confidence: 0.95,
        spokenResponse: 'Going home',
      ));
    }

    // "search for [query]" / "google [query]"
    final searchMatch = RegExp(
      r'\b(?:search|google|look up|find)\s+(?:for\s+)?(.+)',
    ).firstMatch(lower);
    if (searchMatch != null && !lower.startsWith('open') && !lower.startsWith('launch')) {
      final query = searchMatch.group(1)!.trim();
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('web_search')!,
        params: {'query': query},
        confidence: 0.8,
        spokenResponse: 'Searching for $query',
      ));
    }

    return commands;
  }

  // --- Information ---

  static List<ParsedVoiceCommand> _parseInformation(String lower, String original) {
    final commands = <ParsedVoiceCommand>[];

    // "what apps do I have?" / "list my apps"
    if (lower.contains('what apps') || lower.contains('list') && lower.contains('apps')) {
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('get_installed_apps')!,
        params: {},
        confidence: 0.85,
        spokenResponse: 'Here are your installed apps',
      ));
    }

    // "what time is it?"
    if (lower.contains('what time') || lower.contains('current time')) {
      final now = DateTime.now();
      final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      commands.add(ParsedVoiceCommand(
        action: DeviceAction(
          id: 'get_time',
          label: 'Get Time',
          description: 'Tell the current time.',
          risk: ActionRisk.safe,
          category: ActionCategory.custom,
          method: 'getTime',
          confirmationMessage: 'Tell the time?',
        ),
        params: {},
        confidence: 0.95,
        spokenResponse: 'It\'s $timeStr',
      ));
    }

    return commands;
  }

  // --- Timer & Alarm ---

  static List<ParsedVoiceCommand> _parseTimerAlarm(String lower, String original) {
    final commands = <ParsedVoiceCommand>[];

    // "wake me up at [time]" / "wake me at [time]"
    final wakeMatch = RegExp(
      r'\bwake\s+me\s+(?:up\s+)?(?:at|in)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    ).firstMatch(lower);
    if (wakeMatch != null) {
      var hour = int.parse(wakeMatch.group(1)!);
      final minute = wakeMatch.group(2) != null ? int.parse(wakeMatch.group(2)!) : 0;
      final period = wakeMatch.group(3)?.toLowerCase();
      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('set_alarm')!,
        params: {'hour': hour, 'minute': minute, 'label': 'Wake up'},
        confidence: 0.9,
        spokenResponse: 'Setting alarm for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      ));
    }

    // "set a timer for [X] minutes/seconds"
    if (commands.isEmpty) {
      final timerMatch = RegExp(
        r'\bset\s+(?:a\s+)?timer\s+(?:for\s+)?(\d+)\s*(minute|minutes|min|second|seconds|sec|s)?',
      ).firstMatch(lower);
      if (timerMatch != null) {
        final value = int.parse(timerMatch.group(1)!);
        final unit = timerMatch.group(2)?.toLowerCase() ?? 'minutes';
        final seconds = unit.startsWith('s') ? value : value * 60;
        commands.add(ParsedVoiceCommand(
          action: ActionRegistry.byId('set_timer')!,
          params: {'seconds': seconds},
          confidence: 0.9,
          spokenResponse: 'Setting timer for $value $unit',
        ));
      }
    }

    // "set an alarm for [X] [AM/PM]"
    if (commands.isEmpty) {
      final alarmMatch = RegExp(
        r'\bset\s+(?:an\s+)?alarm\s+(?:for\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      ).firstMatch(lower);
      if (alarmMatch != null) {
        var hour = int.parse(alarmMatch.group(1)!);
        final minute = alarmMatch.group(2) != null ? int.parse(alarmMatch.group(2)!) : 0;
        final period = alarmMatch.group(3)?.toLowerCase();
        if (period == 'pm' && hour < 12) hour += 12;
        if (period == 'am' && hour == 12) hour = 0;
        commands.add(ParsedVoiceCommand(
          action: ActionRegistry.byId('set_alarm')!,
          params: {'hour': hour, 'minute': minute},
          confidence: 0.9,
          spokenResponse: 'Setting alarm for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        ));
      }
    }

    // "remind me [to do something] [at time]" — falls back to create_note
    if (commands.isEmpty) {
      final remindMatch = RegExp(
        r'\bremind\s+me\s+(?:to\s+)?(.+?)(?:\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?$',
      ).firstMatch(lower);
      if (remindMatch != null) {
        final task = remindMatch.group(1)!.trim();
        commands.add(ParsedVoiceCommand(
          action: ActionRegistry.byId('create_note')!,
          params: {'title': 'Reminder', 'content': task},
          confidence: 0.7,
          spokenResponse: 'I will remind you to $task',
        ));
      }
    }

    return commands;
  }

  // --- Volume & Brightness ---

  static List<ParsedVoiceCommand> _parseVolumeBrightness(String lower, String original) {
    final commands = <ParsedVoiceCommand>[];

    // "set volume to [X]%" / "volume [X]"
    final volumeMatch = RegExp(
      r'\b(?:set\s+)?volume\s+(?:to\s+)?(\d{1,3})\s*%?',
    ).firstMatch(lower);
    if (volumeMatch != null) {
      final level = int.parse(volumeMatch.group(1)!).clamp(0, 100);
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('set_volume')!,
        params: {'stream': 'media', 'level': level},
        confidence: 0.85,
        spokenResponse: 'Setting volume to $level%',
      ));
    }

    // "set brightness to [X]%" / "brightness [X]"
    final brightnessMatch = RegExp(
      r'\b(?:set\s+)?brightness\s+(?:to\s+)?(\d{1,3})\s*%?',
    ).firstMatch(lower);
    if (brightnessMatch != null) {
      final level = int.parse(brightnessMatch.group(1)!).clamp(0, 100);
      commands.add(ParsedVoiceCommand(
        action: ActionRegistry.byId('set_brightness')!,
        params: {'level': level},
        confidence: 0.85,
        spokenResponse: 'Setting brightness to $level%',
      ));
    }

    return commands;
  }

  // --- Helpers ---

  static String _appKeywordToPackage(String keyword) {
    // First try the comprehensive AppRegistry
    final entry = AppRegistry.findMatch(keyword);
    if (entry != null) return entry.packageName;

    // Legacy fallback map for anything not in AppRegistry
    final map = {
      'whatsapp': 'com.whatsapp',
      'chrome': 'com.android.chrome',
      'browser': 'com.android.chrome',
      'gmail': 'com.google.android.gm',
      'email': 'com.google.android.gm',
      'mail': 'com.google.android.gm',
      'messages': 'com.google.android.apps.messaging',
      'messaging': 'com.google.android.apps.messaging',
      'phone': 'com.android.dialer',
      'dialer': 'com.android.dialer',
      'calls': 'com.android.dialer',
      'settings': 'com.android.settings',
      'calendar': 'com.google.android.calendar',
      'photos': 'com.google.android.apps.photos',
      'gallery': 'com.google.android.apps.photos',
      'camera': 'com.android.camera2',
      'maps': 'com.google.android.apps.maps',
      'google maps': 'com.google.android.apps.maps',
      'youtube': 'com.google.android.youtube',
      'spotify': 'com.spotify.music',
      'music': 'com.google.android.music',
      'files': 'com.google.android.documentsui',
      'file manager': 'com.google.android.documentsui',
      'calculator': 'com.android.calculator2',
      'clock': 'com.android.deskclock',
      'notes': 'com.google.android.keep',
      'keep': 'com.google.android.keep',
      'drive': 'com.google.android.apps.docs',
      'google drive': 'com.google.android.apps.docs',
      'play store': 'com.android.vending',
      'store': 'com.android.vending',
    };
    for (final entry in map.entries) {
      if (keyword.contains(entry.key)) return entry.value;
    }
    // Fallback: try to guess package name
    return 'com.${keyword.toLowerCase().replaceAll(' ', '_')}';
  }

  static String? _settingKeyword(String keyword) {
    switch (keyword) {
      case 'wifi':
      case 'wi-fi':
      case 'wireless':
        return 'wifi';
      case 'bluetooth':
      case 'bt':
        return 'bluetooth';
      case 'flashlight':
      case 'torch':
      case 'flash':
        return 'flashlight';
      case 'dnd':
      case 'do not disturb':
      case 'do not disturb mode':
        return 'dnd';
      case 'location':
      case 'gps':
        return 'location';
      case 'airplane':
      case 'airplane mode':
      case 'flight mode':
        return 'airplane';
      default:
        return null;
    }
  }
}

/// A parsed voice command ready for execution.
class ParsedVoiceCommand {
  final DeviceAction action;
  final Map<String, dynamic> params;
  final double confidence;
  final String spokenResponse;

  const ParsedVoiceCommand({
    required this.action,
    required this.params,
    required this.confidence,
    required this.spokenResponse,
  });

  DeviceAction toAction() => action.copyWith(params: params);
}
