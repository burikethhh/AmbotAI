/// Smart document formatter that works entirely in Dart (no LLM needed).
/// Fast, deterministic, and always succeeds.
class SmartFormatter {
  /// Apply smart formatting to raw text.
  /// Returns structured markdown with proper spacing, headings, and lists.
  static String format(String text, {String tone = 'professional'}) {
    if (text.trim().isEmpty) return text;

    var result = text;

    result = _normalizeLineEndings(result);
    result = _fixSpacing(result);
    result = _fixPunctuation(result);
    result = _detectAndFormatHeadings(result);
    result = _detectAndFormatLists(result);
    result = _normalizeParagraphSpacing(result);
    result = _addFinalNewline(result);

    return result.trim();
  }

  static String _normalizeLineEndings(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  static String _fixSpacing(String text) {
    return text
        .replaceAll(RegExp(r'[ \t]+'), ' ')   // multiple spaces → single
        .replaceAll(RegExp(r'\n[ \t]+'), '\n') // spaces at line start
        .replaceAll(RegExp(r'[ \t]+\n'), '\n') // trailing whitespace
        .trim();
  }

  static String _fixPunctuation(String text) {
    var result = text;

    // Space after punctuation if missing (but not inside numbers)
    result = result.replaceAllMapped(
      RegExp(r'([.!?])([A-Za-z])'),
      (m) => '${m[1]} ${m[2]}',
    );

    // Space after comma if missing
    result = result.replaceAllMapped(
      RegExp(r'([,])([A-Za-z])'),
      (m) => '${m[1]} ${m[2]}',
    );

    // Ensure sentences end with period if no other ending punctuation
    result = result.replaceAllMapped(
      RegExp(r'([a-zA-Z])\n([A-Z])'),
      (m) {
        final prevChar = m[1]!;
        // Don't add period after common abbreviations
        if (['Dr', 'Mr', 'Mrs', 'Ms', 'St', 'Ave', 'Rd', 'etc', 'vs', 'i.e', 'e.g'].contains(prevChar)) {
          return '${m[1]}\n${m[2]}';
        }
        return '${m[1]}.\n${m[2]}';
      },
    );

    // Remove double punctuation
    result = result.replaceAll(RegExp(r'[.]{2,}'), '.');
    result = result.replaceAll(RegExp(r'[!]{2,}'), '!');
    result = result.replaceAll(RegExp(r'[?]{2,}'), '?');

    return result;
  }

  static String _detectAndFormatHeadings(String text) {
    final lines = text.split('\n');
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        result.add('');
        continue;
      }

      // Skip if already formatted as heading
      if (line.startsWith('#') || line.startsWith('#')) {
        result.add(line);
        continue;
      }

      // Detect potential heading:
      // 1. Short line (under 60 chars), not part of a list
      // 2. Doesn't end with period/comma/semicolon
      // 3. Next line is empty OR next line doesn't start with lowercase
      // 4. Not a single word that's an article/preposition
      final isShort = line.length < 60;
      final noEndPunct = !line.endsWith('.') && !line.endsWith(',') && !line.endsWith(';') && !line.endsWith(':');
      final nextIsEmpty = i + 1 >= lines.length || lines[i + 1].trim().isEmpty;
      final nextIsCapital = i + 1 < lines.length && lines[i + 1].trim().isNotEmpty && 
                             RegExp("^[A-Z\"'#]").hasMatch(lines[i + 1].trim());
      final isLikelyHeading = isShort && noEndPunct && (nextIsEmpty || nextIsCapital);

      if (isLikelyHeading) {
        // Determine heading level based on context
        final prevIsEmpty = i == 0 || lines[i - 1].trim().isEmpty;
        if (prevIsEmpty) {
          result.add('## $line');
        } else {
          result.add('### $line');
        }
      } else {
        result.add(line);
      }
    }

    return result.join('\n');
  }

  static String _detectAndFormatLists(String text) {
    final lines = text.split('\n');
    final result = <String>[];
    var inList = false;
    var listNum = 1;

    for (final rawLine in lines) {
      var line = rawLine.trim();

      // Skip already-formatted lists
      if (line.startsWith('- ') || line.startsWith('* ') || RegExp(r'^\d+[\.\)] ').hasMatch(line)) {
        inList = true;
        if (RegExp(r'^\d+[\.\)] ').hasMatch(line)) {
          final num = int.tryParse(RegExp(r'^(\d+)').firstMatch(line)!.group(1)!);
          listNum = (num ?? listNum);
        }
        result.add(rawLine);
        continue;
      }

      // Detect potential list items:
      // Starts with dash, asterisk, number, or bullet-like prefix
      if (line.startsWith('-') || line.startsWith('•') || line.startsWith('*')) {
        inList = true;
        final clean = line.replaceAll(RegExp(r'^[-•*\s]+'), '').trim();
        if (clean.isNotEmpty) {
          result.add('- $clean');
        }
        continue;
      }

      // Detect numbered list: "1. " "1) " "1/ " etc
      if (RegExp(r'^\d+[\.\)\/]').hasMatch(line)) {
        inList = true;
        final clean = line.replaceAll(RegExp(r'^\d+[\.\)\/]\s*'), '').trim();
        if (clean.isNotEmpty) {
          result.add('${listNum++}. $clean');
        }
        continue;
      }

      // Detect lines starting with lowercase after bullet (continuation)
      if (inList && RegExp(r'^[a-z]').hasMatch(line)) {
        result.add('  ${rawLine.trimLeft()}');
        continue;
      }

      inList = false;
      listNum = 1;
      result.add(rawLine);
    }

    return result.join('\n');
  }

  static String _normalizeParagraphSpacing(String text) {
    final lines = text.split('\n');
    final result = <String>[];
    var prevBlank = true;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (!prevBlank) {
          result.add('');
          prevBlank = true;
        }
        continue;
      }

      // Check if this line is part of a list or heading (keep adjacent)
      final isList = trimmed.startsWith('- ') || trimmed.startsWith('* ') || RegExp(r'^\d+[\.\)] ').hasMatch(trimmed);
      final isHeading = trimmed.startsWith('#');
      final isContinuation = line.startsWith('  ');

      if (prevBlank || isList || isHeading || isContinuation) {
        result.add(trimmed);
      } else {
        // Add blank line between paragraphs
        if (!prevBlank) result.add('');
        result.add(trimmed);
      }
      prevBlank = false;
    }

    return result.join('\n');
  }

  static String _addFinalNewline(String text) {
    return text.endsWith('\n') ? text : '$text\n';
  }
}
