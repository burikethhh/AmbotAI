import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

import 'action.dart';
import 'device_controller.dart';

/// Persistent log of every device action attempted, including the AI's
/// reasoning, the safety decision, the user's response, and the result.
///
/// Stored in Hive for fast append-only writes. Users can view, filter,
/// and export the log from the settings screen.
class ActionLog {
  ActionLog._();
  static final ActionLog instance = ActionLog._();

  static const String _boxName = 'ambot_action_log_v1';

  Box<String>? _box;

  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> log({
    required DeviceAction action,
    required String aiReasoning,
    required String safetyDecision,
    required String userResponse,
    DeviceActionResult? result,
  }) async {
    final entry = LogEntry(
      id: '${action.id}_${DateTime.now().millisecondsSinceEpoch}',
      actionId: action.id,
      actionLabel: action.label,
      risk: action.risk.name,
      category: action.category.name,
      aiReasoning: aiReasoning,
      safetyDecision: safetyDecision,
      userResponse: userResponse,
      success: result?.success ?? false,
      output: result?.output,
      error: result?.error,
      timestamp: DateTime.now(),
    );
    await _box?.put(entry.id, jsonEncode(entry.toJson()));
  }

  List<LogEntry> all() {
    final box = _box;
    if (box == null) return const [];
    final out = <LogEntry>[];
    for (final raw in box.values) {
      try {
        out.add(LogEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ));
      } catch (_) {}
    }
    out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return out;
  }

  List<LogEntry> byCategory(ActionCategory category) =>
      all().where((e) => e.category == category.name).toList();

  List<LogEntry> byRisk(ActionRisk risk) =>
      all().where((e) => e.risk == risk.name).toList();

  Future<void> clear() async {
    await _box?.clear();
  }

  String exportJson() {
    return jsonEncode({
      'version': 1,
      'entries': all().map((e) => e.toJson()).toList(),
    });
  }
}

class LogEntry {
  final String id;
  final String actionId;
  final String actionLabel;
  final String risk;
  final String category;
  final String aiReasoning;
  final String safetyDecision;
  final String userResponse;
  final bool success;
  final String? output;
  final String? error;
  final DateTime timestamp;

  LogEntry({
    required this.id,
    required this.actionId,
    required this.actionLabel,
    required this.risk,
    required this.category,
    required this.aiReasoning,
    required this.safetyDecision,
    required this.userResponse,
    required this.success,
    this.output,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionId': actionId,
        'actionLabel': actionLabel,
        'risk': risk,
        'category': category,
        'aiReasoning': aiReasoning,
        'safetyDecision': safetyDecision,
        'userResponse': userResponse,
        'success': success,
        'output': output,
        'error': error,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] as String,
        actionId: json['actionId'] as String,
        actionLabel: json['actionLabel'] as String,
        risk: json['risk'] as String,
        category: json['category'] as String,
        aiReasoning: json['aiReasoning'] as String,
        safetyDecision: json['safetyDecision'] as String,
        userResponse: json['userResponse'] as String,
        success: json['success'] as bool,
        output: json['output'] as String?,
        error: json['error'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
