import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef KeyboardShortcutCallback = VoidCallback;

class DesktopKeyboardHandler extends StatefulWidget {
  final Widget child;
  final KeyboardShortcutCallback? onNewChat;
  final KeyboardShortcutCallback? onSearch;
  final KeyboardShortcutCallback? onSettings;
  final KeyboardShortcutCallback? onToggleTheme;
  final KeyboardShortcutCallback? onEscape;
  final KeyboardShortcutCallback? onSave;
  final KeyboardShortcutCallback? onExport;

  const DesktopKeyboardHandler({
    super.key,
    required this.child,
    this.onNewChat,
    this.onSearch,
    this.onSettings,
    this.onToggleTheme,
    this.onEscape,
    this.onSave,
    this.onExport,
  });

  @override
  State<DesktopKeyboardHandler> createState() => _DesktopKeyboardHandlerState();
}

class _DesktopKeyboardHandlerState extends State<DesktopKeyboardHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
      widget.onNewChat?.call();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
      widget.onSearch?.call();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.comma) {
      widget.onSettings?.call();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyD) {
      widget.onToggleTheme?.call();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      widget.onSave?.call();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyE) {
      widget.onExport?.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onEscape?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
