import 'dart:convert';
import 'package:http/http.dart' as http;

class FetchResult {
  final String url;
  final String content;
  final String? error;

  const FetchResult({
    required this.url,
    required this.content,
    this.error,
  });

  bool get isSuccess => error == null && content.isNotEmpty;

  String get display {
    if (error != null) return 'FETCH ERROR ($url): $error';
    return 'SOURCE ($url):\n$content';
  }
}

class WebFetchService {
  WebFetchService._();
  static final WebFetchService instance = WebFetchService._();

  static const int _maxFetchesPerMinute = 5;
  final List<DateTime> _fetchTimestamps = [];
  int _totalFetchesThisTurn = 0;
  String? _turnId;

  void startTurn(String turnId) {
    if (_turnId != turnId) {
      _turnId = turnId;
      _totalFetchesThisTurn = 0;
    }
  }

  bool get canFetch {
    _pruneOldTimestamps();
    return _fetchTimestamps.length < _maxFetchesPerMinute;
  }

  int get remainingThisMinute {
    _pruneOldTimestamps();
    return _maxFetchesPerMinute - _fetchTimestamps.length;
  }

  int get remainingThisTurn {
    return _maxFetchesPerMinute - _totalFetchesThisTurn;
  }

  void _pruneOldTimestamps() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    _fetchTimestamps.removeWhere((t) => t.isBefore(cutoff));
  }

  Future<FetchResult> fetch(String url, {http.Client? client}) async {
    if (!canFetch) {
      return FetchResult(
        url: url,
        content: '',
        error: 'Rate limit reached ($_maxFetchesPerMinute/min). Try again later.',
      );
    }

    String normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    _fetchTimestamps.add(DateTime.now());
    _totalFetchesThisTurn++;

    try {
      final c = client ?? http.Client();
      final response = await c
          .get(
            Uri.parse(normalizedUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.5',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (client == null) c.close();

      if (response.statusCode != 200) {
        return FetchResult(
          url: url,
          content: '',
          error: 'HTTP ${response.statusCode}',
        );
      }

      final contentType = response.headers['content-type'] ?? '';
      String text;

      if (contentType.contains('application/json')) {
        final parsed = jsonDecode(response.body);
        text = _formatJson(parsed);
      } else {
        text = _stripHtml(response.body);
      }

      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        return FetchResult(
          url: url,
          content: '',
          error: 'No readable content found at URL',
        );
      }

      final maxChars = 8000;
      final content = trimmed.length > maxChars
          ? '${trimmed.substring(0, maxChars)}\n\n[truncated at $maxChars chars]'
          : trimmed;

      return FetchResult(url: url, content: content);
    } catch (e) {
      return FetchResult(
        url: url,
        content: '',
        error: 'Failed to fetch: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  String _stripHtml(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<nav[^>]*>[\s\S]*?</nav>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<footer[^>]*>[\s\S]*?</footer>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<header[^>]*>[\s\S]*?</header>', caseSensitive: false), '');

    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n- ');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'&amp;', caseSensitive: false), '&');
    text = text.replaceAll(RegExp(r'&lt;', caseSensitive: false), '<');
    text = text.replaceAll(RegExp(r'&gt;', caseSensitive: false), '>');
    text = text.replaceAll(RegExp(r'&quot;', caseSensitive: false), '"');
    text = text.replaceAll(RegExp(r'&#[0-9]+;', caseSensitive: false), ' ');

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '');
    text = text.trim();

    return text;
  }

  String _formatJson(dynamic json) {
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  void reset() {
    _fetchTimestamps.clear();
    _totalFetchesThisTurn = 0;
    _turnId = null;
  }

  static List<String> extractFetchUrls(String text) {
    final regex = RegExp(r'\[FETCH:\s*((?:https?://)?[^\]]+)\]', caseSensitive: false);
    return regex.allMatches(text).map((m) => m.group(1)!.trim()).toList();
  }

  static String removeFetchTags(String text) {
    return text.replaceAll(RegExp(r'\[FETCH:\s*[^\]]+\]\s*', caseSensitive: false), '').trim();
  }
}
