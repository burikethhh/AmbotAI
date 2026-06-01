import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/document_gen/smart_formatter.dart';

void main() {
  group('SmartFormatter', () {
    group('_fixPunctuation (via format)', () {
      test('adds space after period followed by letter', () {
        final result = SmartFormatter.format('Hello.World');
        expect(result, contains('Hello. World'));
      });

      test('adds space after comma followed by letter', () {
        final result = SmartFormatter.format('apples,oranges');
        expect(result, contains('apples, oranges'));
      });

      test('adds sentence-ending period at line break', () {
        final result = SmartFormatter.format('Introduction\nThis is a very long sentence that goes well beyond sixty characters so it cannot be detected as a heading by the heading detection logic');
        expect(result, contains('Introduction.\n'));
      });

      test('removes double periods', () {
        final result = SmartFormatter.format('Hello.. World..');
        expect(result, contains('Hello. World.'));
      });

      test('removes double exclamation marks', () {
        final result = SmartFormatter.format('Wow!! Great!!');
        expect(result, contains('Wow! Great!'));
      });

      test('removes double question marks', () {
        final result = SmartFormatter.format('Really??');
        expect(result, contains('Really?'));
      });
    });

    group('heading detection (via format)', () {
      test('detects and formats a short line as heading', () {
        final input = 'Introduction\n\nThis is the introduction text.';
        final result = SmartFormatter.format(input);
        expect(result, contains('## Introduction'));
      });

      test('leaves already-formatted headings unchanged', () {
        final input = '## Introduction\n\nSome content.';
        final result = SmartFormatter.format(input);
        expect(result, startsWith('## Introduction'));
      });
    });

    group('list detection (via format)', () {
      test('converts dash-prefixed lines to markdown list', () {
        final input = '- Item one\n- Item two\n- Item three';
        final result = SmartFormatter.format(input);
        expect(result, contains('- Item one'));
        expect(result, contains('- Item two'));
      });

      test('preserves already-formatted numbered list items', () {
        final input = '1. First item\n2. Second item\n3. Third item';
        final result = SmartFormatter.format(input);
        expect(result, contains('1. First item'));
        expect(result, contains('2. Second item'));
        expect(result, contains('3. Third item'));
      });

      test('converts paren-style numbered items to dot format', () {
        // Use no space after paren to avoid "already formatted" path
        // Add period on last item to avoid heading detection
        final input = '1)First item with enough text\n2)Second item is also quite long\n3)Third item has plenty of text as well.';
        final result = SmartFormatter.format(input);
        expect(result, contains('1. First item'));
        expect(result, contains('2. Second item'));
        expect(result, contains('3. Third item'));
      });

      test('handles bullet character', () {
        final input = '• Bullet one\n• Bullet two\n  continuation text here to avoid short-line heading detection';
        final result = SmartFormatter.format(input);
        expect(result, contains('- Bullet one'));
        expect(result, contains('- Bullet two'));
      });
    });

    group('spacing (via format)', () {
      test('collapses multiple spaces into one', () {
        final result = SmartFormatter.format('Hello    World');
        expect(result, contains('Hello World'));
      });

      test('trims leading and trailing whitespace', () {
        final result = SmartFormatter.format('  Hello World  ');
        // Single short line gets detected as heading
        expect(result, '## Hello World');
      });

      test('normalizes Windows line endings', () {
        final result = SmartFormatter.format('Line1\r\nLine2\r\nLine3');
        expect(result, contains('Line1\n'));
      });
    });

    group('full format pipeline', () {
      test('formats a complete document', () {
        final input = 'introduction\n\nthis is the body of the document.it has multiple Sentences.'
            ' here is a list:\n- item a\n- item b\n\nconclusion\nThe end.';
        final result = SmartFormatter.format(input);
        expect(result, isNotEmpty);
        expect(result, isNot(equals(input)));
      });

      test('returns empty string for empty input', () {
        expect(SmartFormatter.format(''), '');
      });

      test('returns original whitespace-only input unchanged', () {
        // format() returns original text when trimmed text is empty
        expect(SmartFormatter.format('   '), '   ');
      });
    });
  });
}
