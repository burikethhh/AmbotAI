import 'dart:io';
import 'package:flutter/services.dart';

class DesktopWindowManager {
  DesktopWindowManager._();

  static const _channel = MethodChannel('ambot_ai/window');

  static Future<void> initialize() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('initialize');
    } catch (_) {}
  }

  static Future<void> setTitle(String title) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('setTitle', {'title': title});
    } catch (_) {}
  }

  static Future<void> setMinimumSize(int width, int height) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('setMinimumSize', {
        'width': width,
        'height': height,
      });
    } catch (_) {}
  }

  static Future<void> centerWindow() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('center');
    } catch (_) {}
  }

  static Future<void> maximize() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('maximize');
    } catch (_) {}
  }

  static Future<void> minimize() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('minimize');
    } catch (_) {}
  }

  static Future<void> restore() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('restore');
    } catch (_) {}
  }

  static Future<bool> isMaximized() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return false;
    try {
      return await _channel.invokeMethod('isMaximized') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> close() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('close');
    } catch (_) {}
  }
}
