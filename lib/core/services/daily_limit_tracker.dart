import 'package:shared_preferences/shared_preferences.dart';

/// Tracks per-day usage limits using SharedPreferences.
/// Resets automatically when the date changes.
class DailyLimitTracker {
  final String _prefPrefix;

  DailyLimitTracker(this._prefPrefix);

  Future<int> get countToday async {
    final prefs = await SharedPreferences.getInstance();
    if (_isNewDay(prefs)) return 0;
    return prefs.getInt('${_prefPrefix}_count') ?? 0;
  }

  Future<bool> canIncrement(int limit) async {
    final current = await countToday;
    return current < limit;
  }

  Future<int> increment() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isNewDay(prefs)) {
      await prefs.setString('${_prefPrefix}_date', _today);
      await prefs.setInt('${_prefPrefix}_count', 1);
      return 1;
    }
    final count = (prefs.getInt('${_prefPrefix}_count') ?? 0) + 1;
    await prefs.setInt('${_prefPrefix}_count', count);
    return count;
  }

  Future<int> remaining(int limit) async {
    final current = await countToday;
    return (limit - current).clamp(0, limit);
  }

  bool _isNewDay(SharedPreferences prefs) {
    final savedDate = prefs.getString('${_prefPrefix}_date');
    return savedDate == null || savedDate != _today;
  }

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
