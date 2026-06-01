import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/rag/app_knowledge.dart';

void main() {
  group('AppKnowledge', () {
    test('has at least 10 knowledge sections', () {
      expect(AppKnowledge.sections.length, greaterThanOrEqualTo(10));
    });

    test('all sections are non-empty strings', () {
      for (final section in AppKnowledge.sections) {
        expect(section.trim(), isNotEmpty);
      }
    });

    test('retrieve returns relevant sections for "who created you"', () {
      final results = AppKnowledge.retrieve('who created you');
      expect(results, isNotEmpty);
      final all = results.join(' ').toLowerCase();
      expect(all, contains('devinci'));
    });

    test('retrieve returns relevant sections for "privacy"', () {
      final results = AppKnowledge.retrieve('privacy');
      expect(results, isNotEmpty);
      final all = results.join(' ').toLowerCase();
      expect(all, contains('privacy'));
    });

    test('retrieve returns relevant sections for "what models"', () {
      final results = AppKnowledge.retrieve('what AI models do you support');
      expect(results, isNotEmpty);
      final all = results.join(' ').toLowerCase();
      expect(all, anyOf(contains('llama'), contains('models'), contains('huggingface')));
    });

    test('retrieve with no match returns empty list', () {
      final results = AppKnowledge.retrieve('xyznonexistent12345');
      expect(results, isEmpty);
    });

    test('buildContext returns empty string for non-matching query', () {
      final ctx = AppKnowledge.buildContext('xyznonexistent12345');
      expect(ctx, isEmpty);
    });

    test('buildContext returns non-empty for matching query', () {
      final ctx = AppKnowledge.buildContext('what is ambot');
      expect(ctx, isNotEmpty);
      expect(ctx, contains('[APP KNOWLEDGE]'));
      expect(ctx, contains('[/APP KNOWLEDGE]'));
    });

    test('sections cover all core features', () {
      final all = AppKnowledge.sections.join(' ').toLowerCase();
      expect(all, contains('chat'));
      expect(all, contains('commander'));
      expect(all, contains('image generation'));
      expect(all, contains('voice generation'));
      expect(all, contains('document generation'));
    });

    test('sections mention platform and tech stack', () {
      final all = AppKnowledge.sections.join(' ').toLowerCase();
      expect(all, contains('flutter'));
      expect(all, contains('android'));
    });
  });
}
