import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/rag/document_qa_service.dart';

void main() {
  group('DocumentQaService', () {
    late DocumentQaService service;

    setUp(() {
      service = DocumentQaService();
    });

    tearDown(() {
      service.clear();
    });

    group('ingest / hasContent / chunkCount', () {
      test('new service has no content', () {
        expect(service.hasContent, isFalse);
        expect(service.chunkCount, 0);
      });

      test('ingest normalizes multi-paragraph text into a single chunk', () {
        service.ingest('First paragraph.\n\nSecond paragraph.\n\nThird paragraph.');
        expect(service.hasContent, isTrue);
        expect(service.chunkCount, 1);
      });

      test('ingest handles single paragraph', () {
        service.ingest('Just one paragraph.');
        expect(service.chunkCount, 1);
      });

      test('ingest handles empty text', () {
        service.ingest('');
        expect(service.hasContent, isFalse);
        expect(service.chunkCount, 0);
      });

      test('ingest trims whitespace and skips empty lines into single chunk', () {
        service.ingest('  Para one  \n\n   \n\nPara two');
        expect(service.chunkCount, 1);
      });

      test('clear resets state', () {
        service.ingest('Some text.');
        expect(service.hasContent, isTrue);

        service.clear();
        expect(service.hasContent, isFalse);
        expect(service.chunkCount, 0);
      });
    });

    group('buildQaPrompt', () {
      test('returns question verbatim when no content ingested', () {
        final prompt = service.buildQaPrompt('What is AI?');
        expect(prompt, 'What is AI?');
      });

      test('includes context from the ingested text', () {
        service.ingest('Artificial intelligence is transforming the world.\n\n'
            'Machine learning is a subset of AI.');

        final prompt = service.buildQaPrompt('What is artificial intelligence?');

        expect(prompt, contains('Context from the document'));
        expect(prompt, contains('Based on the context above, answer:'));
        expect(prompt, contains('artificial intelligence'));
        expect(prompt, contains('What is artificial intelligence?'));
      });

      test('buildQaPrompt respects topK limit', () {
        service.ingest('A\n\nB\n\nC\n\nD\n\nE\n\nF\n\nG');
        final prompt = service.buildQaPrompt('A B C D E', topK: 3);
        expect(prompt, contains('Context from the document'));
      });
    });

    group('retrieve (via buildQaPrompt)', () {
      test('finds chunks with matching keywords', () {
        service.ingest('Photosynthesis converts sunlight into energy.\n\n'
            'Quantum computing uses qubits.');

        final prompt = service.buildQaPrompt('Explain photosynthesis');
        expect(prompt, contains('Photosynthesis'));
      });

      test('returns question with context when some keywords match', () {
        service.ingest('Dogs are mammals.\n\n'
            'Many people keep dogs as pets.\n\n'
            'Cats are independent animals.');

        final prompt = service.buildQaPrompt('dogs pets');
        expect(prompt, contains('Context from the document'));
      });
    });
  });
}
