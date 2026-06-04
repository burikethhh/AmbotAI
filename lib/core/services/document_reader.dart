import 'dart:convert';
import 'dart:io';

class DocumentReader {
  static const List<String> _textExtensions = ['txt', 'md', 'csv', 'json', 'xml', 'html', 'log'];

  static bool canRead(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _textExtensions.contains(ext);
  }

  static Future<String> readText(String path) async {
    final file = File(path);
    if (!await file.exists()) return '';
    final ext = path.split('.').last.toLowerCase();

    if (_textExtensions.contains(ext)) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.length > 50000) {
          return '${utf8.decode(bytes.sublist(0, 50000))}\n\n[...file truncated at 50KB]';
        }
        return utf8.decode(bytes);
      } catch (_) {
        return '';
      }
    }

    if (ext == 'pdf') {
      return 'PDF reading is not supported yet. Please convert to text format.';
    }

    return 'Cannot read file type: .$ext';
  }
}
