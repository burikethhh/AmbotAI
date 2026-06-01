import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/ai/ai_engine.dart';
import 'package:ambot_ai/core/document_gen/document_gen_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAIEngine extends Mock implements AIEngine {}

void main() {
  late MockAIEngine mockEngine;

  setUp(() {
    mockEngine = MockAIEngine();
  });

  group('GeneratedDocument', () {
    test('constructor sets fields and defaults', () {
      final doc = GeneratedDocument(
        type: DocumentType.studyGuide,
        title: 'Study Guide: Math',
        content: 'Math content here',
        metadata: {'topic': 'Math'},
      );
      expect(doc.type, DocumentType.studyGuide);
      expect(doc.title, 'Study Guide: Math');
      expect(doc.content, 'Math content here');
      expect(doc.metadata, {'topic': 'Math'});
      expect(doc.tags, isEmpty);
      expect(doc.isExported, isFalse);
      expect(doc.pdfPath, isNull);
      expect(doc.docxPath, isNull);
    });

    test('isExported returns true after markPdfExported', () {
      final doc = GeneratedDocument(
        type: DocumentType.summary,
        title: 'Summary',
        content: 'Content',
        metadata: {},
      );
      doc.markPdfExported('/path/to/doc.pdf');
      expect(doc.isExported, isTrue);
      expect(doc.pdfPath, '/path/to/doc.pdf');
    });

    test('isExported returns true after markDocxExported', () {
      final doc = GeneratedDocument(
        type: DocumentType.quiz,
        title: 'Quiz',
        content: 'Content',
        metadata: {},
      );
      doc.markDocxExported('/path/to/doc.rtf');
      expect(doc.isExported, isTrue);
      expect(doc.docxPath, '/path/to/doc.rtf');
    });
  });

  group('buildContextPrompt', () {
    test('appends memory context when memoryLines provided', () {
      final result = DocumentGenService.instance.buildContextPrompt(
        'Create a study guide about biology.',
        ['User is studying for MCAT', 'User prefers visual learning'],
      );
      expect(result, contains('Create a study guide about biology.'));
      expect(result, contains('Known context from past conversations'));
      expect(result, contains('User is studying for MCAT'));
      expect(result, contains('Incorporate this context naturally'));
    });

    test('returns base prompt unchanged when memoryLines empty', () {
      final result = DocumentGenService.instance.buildContextPrompt(
        'Create a summary.',
        [],
      );
      expect(result, 'Create a summary.');
    });
  });

  group('document generation methods', () {
    test('generateStudyGuide creates document with fallback tags', () async {
      final doc = await DocumentGenService.instance.generateStudyGuide(
        topic: 'Photosynthesis',
        content: 'Detailed content about photosynthesis.',
        level: StudyGuideLevel.beginner,
      );
      expect(doc.type, DocumentType.studyGuide);
      expect(doc.title, 'Study Guide: Photosynthesis');
      expect(doc.tags, isNotEmpty);
    });

    test('generateQuiz creates document with quiz metadata', () async {
      final doc = await DocumentGenService.instance.generateQuiz(
        topic: 'World History',
        content: 'History quiz content.',
        questionCount: 5,
        quizType: QuizType.trueFalse,
      );
      expect(doc.type, DocumentType.quiz);
      expect(doc.title, 'Quiz: World History');
      expect(doc.metadata['questionCount'], 5);
      expect(doc.metadata['quizType'], 'trueFalse');
    });

    test('generateFlashcards creates document', () async {
      final doc = await DocumentGenService.instance.generateFlashcards(
        topic: 'Spanish Vocabulary',
        content: 'Flashcard content.',
        cardCount: 10,
      );
      expect(doc.type, DocumentType.flashcards);
      expect(doc.title, 'Flashcards: Spanish Vocabulary');
      expect(doc.metadata['cardCount'], 10);
    });

    test('generateSummary creates document', () async {
      final doc = await DocumentGenService.instance.generateSummary(
        title: 'Chapter 1',
        content: 'Summary content.',
        format: SummaryFormat.bulletPoints,
      );
      expect(doc.type, DocumentType.summary);
      expect(doc.title, 'Chapter 1');
      expect(doc.metadata['format'], 'bulletPoints');
    });

    test('generateLessonPlan creates document', () async {
      final doc = await DocumentGenService.instance.generateLessonPlan(
        topic: 'Algebra',
        content: 'Lesson plan content.',
        durationMinutes: 45,
        targetAudience: 'Grade 9',
      );
      expect(doc.type, DocumentType.lessonPlan);
      expect(doc.title, 'Lesson Plan: Algebra');
      expect(doc.metadata['durationMinutes'], 45);
      expect(doc.metadata['targetAudience'], 'Grade 9');
    });

    test('generateFromResponse creates general document', () async {
      final doc = await DocumentGenService.instance.generateFromResponse(
        title: 'AI Response',
        aiResponse: 'This is the AI output.',
        type: DocumentType.general,
      );
      expect(doc.type, DocumentType.general);
      expect(doc.title, 'AI Response');
    });
  });

  group('_autoTag (tested through generate)', () {
    test('falls back to title-based tags when engine is null', () async {
      final doc = await DocumentGenService.instance.generateStudyGuide(
        topic: 'Machine Learning',
        content: 'Content about ML.',
        llmEngine: null,
      );
      expect(doc.tags, isNotEmpty);
      expect(doc.tags.every((t) => t.length > 3), isTrue);
    });

    test('uses engine tags when engine returns comma-separated response', () async {
      when(() => mockEngine.isReady).thenReturn(true);
      when(() => mockEngine.generate(any())).thenAnswer(
        (_) async => 'machine learning, neural networks, deep learning',
      );

      final doc = await DocumentGenService.instance.generateStudyGuide(
        topic: 'AI',
        content: 'Content about artificial intelligence.',
        llmEngine: mockEngine,
      );
      expect(doc.tags, isNotEmpty);
    });

    test('falls back when engine returns fewer than 2 tags', () async {
      when(() => mockEngine.isReady).thenReturn(true);
      when(() => mockEngine.generate(any())).thenAnswer(
        (_) async => 'single',
      );

      final doc = await DocumentGenService.instance.generateStudyGuide(
        topic: 'Physics',
        content: 'Physics content.',
        llmEngine: mockEngine,
      );
      expect(doc.tags, isNotEmpty);
    });
  });

}
