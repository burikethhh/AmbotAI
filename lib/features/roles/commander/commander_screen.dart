import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../core/ai/nvidia_vision.dart';
import '../../../core/device_control/action.dart';
import '../../../core/device_control/action_log.dart';
import '../../../core/device_control/action_registry.dart';
import '../../../core/device_control/device_controller.dart';
import '../../../core/device_control/engines/android_accessibility_engine.dart';
import '../../../core/device_control/execution_mode.dart';
import '../../../core/device_control/safety_rules.dart';
import '../../../core/services/haptic_feedback_service.dart';
import '../../../core/voice/engines/android_voice_engine.dart';
import '../../../core/voice/voice_command_parser.dart';
import '../../../core/voice/voice_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../device_control/accessibility_setup_screen.dart';
import 'widgets/commander_app_bar.dart';
import 'widgets/commander_history.dart' show AgentHistory;
import 'widgets/command_input.dart';
import 'widgets/command_output.dart';
import 'widgets/quick_commands.dart';
import 'widgets/status_panel.dart';

class AgentDrivenEnvironmentScreen extends ConsumerStatefulWidget {
  const AgentDrivenEnvironmentScreen({super.key});

  @override
  ConsumerState<AgentDrivenEnvironmentScreen> createState() => _AgentDrivenEnvironmentScreenState();
}

class _AgentDrivenEnvironmentScreenState extends ConsumerState<AgentDrivenEnvironmentScreen>
    with TickerProviderStateMixin {
  late DeviceController _controller;
  late VoiceService _voiceService;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  ExecutionMode _mode = ExecutionMode.ask;
  ScreenContext? _screenContext;
  List<LogEntry> _log = [];
  bool _isProcessing = false;
  String _statusMessage = 'Initializing...';
  double _trustScore = 0.5;
  bool _hasPermission = false;
  bool _captureReady = false;
  String? _lastError;
  bool _showScreenContent = false;

  VoiceState _voiceState = VoiceState.idle;
  String _liveTranscript = '';
  bool _voiceEnabled = false;

  final NvidiaVisionService _visionService = NvidiaVisionService();
  late AnimationController _statusPulseController;

  // Runtime permission states (Android 13+)
  bool _hasNotificationPerm = true;
  bool _hasOverlayPerm = true;

  @override
  void initState() {
    super.initState();
    _controller = AndroidAccessibilityEngine();
    _voiceService = AndroidVoiceEngine();
    _statusPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _init();
    _checkRuntimePermissions();
  }

  Future<void> _checkRuntimePermissions() async {
    if (Platform.isAndroid) {
      final notif = await Permission.notification.status;
      final overlay = await Permission.systemAlertWindow.status;
      if (mounted) {
        setState(() {
          _hasNotificationPerm = notif.isGranted;
          _hasOverlayPerm = overlay.isGranted;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (mounted) setState(() => _hasNotificationPerm = status.isGranted);
    }
  }

  Future<void> _init() async {
    await _controller.initialize();
    await _voiceService.initialize();
    final hasPerm = await _controller.hasPermission;
    final voiceAvailable = await _voiceService.isSpeechAvailable;
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
        _statusMessage = hasPerm ? 'Ready' : 'Permission required';
        _log = ActionLog.instance.all();
        _voiceEnabled = voiceAvailable;
      });
    }

    _voiceResultSub = _voiceService.onResult.listen((result) {
      if (!mounted) return;
      setState(() {
        _liveTranscript = result.text;
        if (!result.isPartial) {
          _voiceState = VoiceState.done;
        } else {
          _voiceState = VoiceState.recognizing;
        }
      });
      if (!result.isPartial && result.text.isNotEmpty) {
        _processVoiceCommand(result.text);
      }
    });

    _voiceErrorSub = _voiceService.onError.listen((error) {
      if (!mounted) return;
      setState(() {
        _voiceState = VoiceState.idle;
        _statusMessage = 'Voice error: $error';
      });
    });
  }

  StreamSubscription? _voiceResultSub;
  StreamSubscription? _voiceErrorSub;

  @override
  void dispose() {
    _voiceResultSub?.cancel();
    _voiceErrorSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _voiceService.dispose();
    _statusPulseController.dispose();
    super.dispose();
  }

  Future<void> _sendTextCommand() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    HapticFeedbackService.tap();
    _textController.clear();

    final commands = VoiceCommandParser.parse(text);
    if (commands.isEmpty) {
      // NVIDIA LLM fallback for unfamiliar commands
      final nvidiaResult = await _tryNvidiaCommand(text);
      if (nvidiaResult != null) {
        await _executeAction(nvidiaResult);
      } else {
        setState(() {
          _lastError = "Didn't understand: '$text'";
          _statusMessage = 'Command not recognized';
        });
        HapticFeedbackService.error();
      }
      return;
    }

    final cmd = commands.first;
    await _executeAction(cmd.toAction());
  }

  Future<DeviceAction?> _tryNvidiaCommand(String text) async {
    try {
      final analysis = await _visionService.analyzeDocument(
        'Parse this device control command into one of these action IDs: '
        'launch_app, open_url, web_search, set_alarm, set_timer, toggle_wifi, '
        'toggle_bluetooth, set_volume, set_brightness, scroll_down, scroll_up, '
        'go_back, click_screen_text, take_screenshot, read_screen, copy_to_clipboard, '
        'send_sms, send_email, create_note, toggle_dnd.\n\n'
        'User said: "$text"\n\n'
        'Return ONLY a JSON object with fields: actionId, params (object of parameters). '
        'Use the action IDs listed above. For launch_app, set params.packageName to the app name. '
        'For web_search, set params.query. For click_screen_text, set params.text.',
      );

      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(analysis);
      if (jsonMatch == null) return null;

      final raw = jsonMatch.group(0);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final actionId = decoded['actionId'] as String?;
      final params = decoded['params'] as Map<String, dynamic>? ?? {};
      final base = ActionRegistry.byId(actionId ?? '');
      if (base == null) return null;

      return base.copyWith(params: params);
    } catch (_) {
      return null;
    }
  }

  Future<void> _readScreen() async {
    HapticFeedbackService.medium();
    setState(() {
      _isProcessing = true;
      _lastError = null;
      _statusMessage = 'Reading screen...';
    });

    try {
      final ctx = await _controller.captureScreen();
      if (mounted) {
        setState(() {
          _screenContext = ctx;
          _showScreenContent = true;
          _isProcessing = false;
          _statusMessage = ctx.text.isNotEmpty
              ? 'Screen read: ${ctx.text.length} chars'
              : 'Screen read failed';
        });

        if (ctx.text.isNotEmpty) {
          await _voiceService
              .speak(ctx.text.substring(0, ctx.text.length.clamp(0, 500)));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastError = 'Screen read failed: $e';
          _statusMessage = 'Read failed';
        });
        HapticFeedbackService.error();
      }
    }
  }

  Future<void> _aiAnalyzeScreen() async {
    HapticFeedbackService.medium();
    setState(() {
      _isProcessing = true;
      _lastError = null;
      _statusMessage = 'AI analyzing screen...';
    });

    try {
      final ctx = await _controller.captureScreen();
      if (!mounted) return;

      if (ctx.screenshotBytes != null && ctx.screenshotBytes!.isNotEmpty) {
        // Save screenshot to temp file and analyze with NVIDIA vision
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/ambot_screen_analysis.png');
        await tempFile.writeAsBytes(ctx.screenshotBytes!);
        final analysis = await _visionService.analyzeImage(tempFile.path);

        if (mounted) {
          setState(() {
            _screenContext = ctx;
            _showScreenContent = true;
            _isProcessing = false;
            _statusMessage = 'AI analysis complete';
          });
          await _voiceService.speak(analysis.substring(0, analysis.length.clamp(0, 500)));
        }
      } else {
        // Text-only analysis using NVIDIA LLM
        final analysis = await _visionService.analyzeDocument(
          'Analyze this device screen content and describe what the user is looking at, '
          'what actions are available, and suggest what they can do next:\n\n${ctx.text}',
        );
        if (mounted) {
          setState(() {
            _screenContext = ctx;
            _showScreenContent = true;
            _isProcessing = false;
            _statusMessage = 'AI analysis complete';
          });
          await _voiceService.speak(analysis.substring(0, analysis.length.clamp(0, 500)));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastError = 'AI analysis failed: $e';
          _statusMessage = 'Analysis failed';
        });
        HapticFeedbackService.error();
      }
    }
  }

  Future<void> _onPermissionEnabled() async {
    final hasPerm = await _controller.hasPermission;
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
        _statusMessage = hasPerm ? 'Ready' : 'Permission required';
        _lastError = null;
      });
    }
  }

  void _openAccessibilitySetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccessibilitySetupScreen(
          onEnabled: () {
            Navigator.pop(context);
            _onPermissionEnabled();
          },
          onSkip: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _toggleVoice() async {
    HapticFeedbackService.tap();
    if (_voiceState == VoiceState.listening ||
        _voiceState == VoiceState.recognizing) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() {
          _voiceState = VoiceState.idle;
          _liveTranscript = '';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _voiceState = VoiceState.listening;
          _liveTranscript = '';
          _statusMessage = 'Listening...';
        });
      }
      await _voiceService.startListening(continuous: false);
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    if (text.isEmpty || _isProcessingVoice) return;
    _isProcessingVoice = true;

    await _voiceService.stopListening();

    var commands = VoiceCommandParser.parse(text);
    if (commands.isEmpty) {
      // NVIDIA LLM fallback
      final nvidiaAction = await _tryNvidiaCommand(text);
      if (nvidiaAction != null) {
        await _executeAction(nvidiaAction);
        if (mounted) {
          setState(() {
            _voiceState = VoiceState.idle;
            _liveTranscript = '';
          });
        }
        _isProcessingVoice = false;
        return;
      }
      if (mounted) {
        setState(() => _statusMessage = "Didn't understand: '$text'");
      }
      await _voiceService.speak("I didn't understand that");
      if (mounted) {
        setState(() {
          _voiceState = VoiceState.idle;
          _liveTranscript = '';
        });
      }
      _isProcessingVoice = false;
      return;
    }

    final cmd = commands.first;
    final action = cmd.toAction();

    if (mounted) {
      setState(() => _statusMessage = 'Voice: ${cmd.spokenResponse}');
    }

    if (cmd.spokenResponse.isNotEmpty) {
      await _voiceService.speak(cmd.spokenResponse);
    }

    await _executeAction(action);

    if (mounted) {
      setState(() {
        _voiceState = VoiceState.idle;
        _liveTranscript = '';
      });
    }
    _isProcessingVoice = false;
  }

  bool _isProcessingVoice = false;

  String get _voiceLabel {
    switch (_voiceState) {
      case VoiceState.idle:
        return 'Tap to speak';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.recognizing:
        return 'Processing...';
      case VoiceState.done:
        return 'Got it';
      case VoiceState.error:
        return 'Voice error';
    }
  }

  Future<void> _executeAction(DeviceAction action) async {
    HapticFeedbackService.medium();
    final decision = SafetyRules.canExecute(
      action: action,
      mode: _mode,
      trustScore: _trustScore,
    );

    if (!decision.allowed) {
      HapticFeedbackService.error();
      if (mounted) {
        setState(() => _statusMessage = 'Blocked: ${decision.reason}');
      }
      return;
    }

    if (decision.requiresConfirmation) {
      final confirmed = await _showConfirmationDialog(action, decision);
      if (confirmed != true) return;
    }

    setState(() {
      _isProcessing = true;
      _lastError = null;
      _statusMessage = 'Executing: ${action.label}...';
    });

    try {
      final result = await _controller.execute(action);

      await ActionLog.instance.log(
        action: action,
        aiReasoning: 'User requested: ${action.label}',
        safetyDecision: decision.reason,
        userResponse:
            decision.requiresConfirmation ? 'Confirmed' : 'Auto-approved',
        result: result,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage =
              result.success ? 'Done: ${action.label}' : 'Failed: ${result.error}';
          _log = ActionLog.instance.all();
          if (result.success) {
            _trustScore = (_trustScore + 0.02).clamp(0.0, 1.0);
            HapticFeedbackService.success();
          } else {
            _lastError = result.error;
            HapticFeedbackService.error();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastError = e.toString();
          _statusMessage = 'Error: $e';
        });
        HapticFeedbackService.error();
      }
    }
  }

  Future<bool?> _showConfirmationDialog(
    DeviceAction action,
    SafetyDecision decision,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ThemeColors.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              Icon(action.risk.icon, color: action.risk.color),
              const SizedBox(width: 8),
              Text(action.label),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action.confirmationMessage),
              const SizedBox(height: 12),
              Text(
                decision.reason,
                style: AppTypography.bodySmall(c.textSecondary),
              ),
              if (decision.requiresCountdown) ...[
                const SizedBox(height: 8),
                Text(
                  SafetyRules.dangerWarning(action),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('DENY'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ALLOW'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;

    return Scaffold(
      appBar: AgentAppBar(
        mode: _mode,
        onModeChanged: (m) {
          HapticFeedbackService.selection();
          setState(() => _mode = m);
        },
        onBack: () => Navigator.pop(context),
        textPrimary: c.textPrimary,
        isDark: c.isDark,
      ),
      body: Column(
        children: [
          Divider(color: c.borderColor, thickness: 2, height: 2),

          // Status bar + banners
          StatusPanel(
            isDark: c.isDark,
            isProcessing: _isProcessing,
            lastError: _lastError,
            statusMessage: _statusMessage,
            trustScore: _trustScore,
            hasPermission: _hasPermission,
            hasNotificationPerm: _hasNotificationPerm,
            hasOverlayPerm: _hasOverlayPerm,
            onDismissError: () => setState(() => _lastError = null),
            onSetupPermission: _openAccessibilitySetup,
            onRequestNotification: _requestNotificationPermission,
            statusPulseController: _statusPulseController,
            textSecondary: c.textSecondary,
          ),

          // Voice input section
          if (_voiceEnabled) ...[
            VoiceInputSection(
              isDark: c.isDark,
              voiceState: _voiceState,
              voiceLabel: _voiceLabel,
              liveTranscript: _liveTranscript,
              onToggleVoice: _toggleVoice,
            ),
            Divider(color: c.borderColor, thickness: 1, height: 1),
          ],

          // Quick command chips
          QuickCommands(
            isDark: c.isDark,
            isNarrow: isNarrow,
            captureReady: _captureReady,
            onToggleCapture: () async {
              HapticFeedbackService.tap();
              if (_captureReady) {
                if (_controller is AndroidAccessibilityEngine) {
                  await (_controller as AndroidAccessibilityEngine)
                      .stopScreenCapture();
                }
                if (mounted) {
                  setState(() {
                    _captureReady = false;
                    _statusMessage = 'Screen capture stopped';
                  });
                }
              } else {
                if (_controller is AndroidAccessibilityEngine) {
                  final ok =
                      await (_controller as AndroidAccessibilityEngine)
                          .startScreenCapture();
                  if (mounted) {
                    setState(() {
                      _captureReady = ok;
                      _statusMessage =
                          ok ? 'Screen capture active' : 'Capture denied';
                    });
                  }
                }
              }
            },
            onReadScreen: _readScreen,
            onQuickLaunch: () async {
              HapticFeedbackService.tap();
              final apps = await _controller.getInstalledApps();
              if (mounted) {
                _showAppsDialog(apps, c.isDark);
              }
            },
            onAiAnalyze: _aiAnalyzeScreen,
            onGoBack: () async {
              HapticFeedbackService.tap();
              final goBack = ActionRegistry.byId('go_back');
              if (goBack == null) return;
              await _executeAction(goBack.copyWith(
                confirmationMessage: 'Go back?',
              ));
            },
            onEmergencyStop: () async {
              HapticFeedbackService.heavy();
              await _controller.emergencyStop();
              if (mounted) {
                setState(() => _statusMessage = 'Stopped');
              }
            },
          ),

          Divider(color: c.borderColor, thickness: 1, height: 1),

          // Text command input
          TextCommandInput(
            isDark: c.isDark,
            isProcessing: _isProcessing,
            textController: _textController,
            onSendText: _sendTextCommand,
          ),

          Divider(color: c.borderColor, thickness: 1, height: 1),

          // Screen context (expandable)
          if (_screenContext != null && _showScreenContent)
            CommandOutput(
              isDark: c.isDark,
              screenContext: _screenContext,
              showScreenContent: _showScreenContent,
              onHide: () {
                HapticFeedbackService.tap();
                setState(() => _showScreenContent = false);
              },
              onReadAloud: () async {
                HapticFeedbackService.tap();
                await _voiceService.speak(
                  _screenContext!.text.substring(
                    0,
                    _screenContext!.text.length.clamp(0, 1000),
                  ),
                );
              },
              onCopy: () {
                HapticFeedbackService.tap();
                setState(() => _statusMessage = 'Screen content copied');
              },
            ),

          if (_screenContext != null && _showScreenContent)
            Divider(color: c.borderColor, thickness: 1, height: 1),

          // Action log
          Expanded(
            child: AgentHistory(
              log: _log,
              isDark: c.isDark,
              cardColor: c.cardColor,
              borderColor: c.borderColor,
              textPrimary: c.textPrimary,
              textSecondary: c.textSecondary,
              onClear: () {
                HapticFeedbackService.tap();
                ActionLog.instance.clear().then((_) {
                  if (mounted) setState(() => _log = []);
                }).catchError((_) {});
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAppsDialog(List<InstalledApp> apps, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AppLauncherDialog(
        apps: apps,
        isDark: isDark,
        onLaunch: (app) {
          Navigator.pop(ctx);
          _launchAppByPackage(app.packageName, app.label);
        },
      ),
    );
  }

  Future<void> _launchAppByPackage(
    String packageName,
    String displayName, {
    List<String> altPackages = const [],
  }) async {
    HapticFeedbackService.medium();
    setState(() {
      _isProcessing = true;
      _lastError = null;
      _statusMessage = 'Opening $displayName...';
    });

    try {
      final baseAction = ActionRegistry.byId('launch_app');
      if (baseAction == null) return;
      final action = baseAction.copyWith(
        params: {
          'packageName': packageName,
          'altPackages': altPackages,
          'displayName': displayName,
        },
        confirmationMessage: 'Open $displayName?',
      );
      await _executeAction(action);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastError = 'Failed to open $displayName: $e';
          _statusMessage = 'Launch failed';
        });
        HapticFeedbackService.error();
      }
    }
  }
}
