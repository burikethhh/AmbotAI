import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ambot_ai/core/document_gen/document_gen_service.dart';

void main() {
  group('DocumentGenService', () {
    late DocumentGenService service;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      service = DocumentGenService.instance;
      await service.initialize();
    });

    group('generateStudyGuide', () {
      test('returns a GeneratedDocument with correct type and title', () async {
        final doc = await service.generateStudyGuide(
          topic: 'Photosynthesis',
          content:
              'Photosynthesis is the process by which plants convert sunlight into chemical energy.',
        );

        expect(doc.type, DocumentType.studyGuide);
        expect(doc.title, 'Study Guide: Photosynthesis');
      });

      test('output content contains the provided content', () async {
        final doc = await service.generateStudyGuide(
          topic: 'Biology',
          content:
              'Mitochondria are the powerhouse of the cell. They generate ATP through oxidative phosphorylation.',
        );

        expect(doc.content, contains('Mitochondria'));
        expect(doc.content, contains('ATP'));
      });
    });

    group('generateQuiz', () {
      test('returns a quiz document', () async {
        final doc = await service.generateQuiz(
          topic: 'World History',
          content:
              'Who was the first president of the United States?\nA: George Washington',
          questionCount: 10,
          quizType: QuizType.multipleChoice,
        );

        expect(doc.type, DocumentType.quiz);
        expect(doc.title, 'Quiz: World History');
        expect(doc.metadata['questionCount'], 10);
        expect(doc.metadata['quizType'], 'multipleChoice');
      });
    });

    group('generateFlashcards', () {
      test('returns a flashcards document', () async {
        final doc = await service.generateFlashcards(
          topic: 'Spanish Vocabulary',
          content: 'Hola - Hello\nAdiós - Goodbye',
          cardCount: 20,
        );

        expect(doc.type, DocumentType.flashcards);
        expect(doc.title, 'Flashcards: Spanish Vocabulary');
        expect(doc.metadata['cardCount'], 20);
      });
    });

    group('auto-tagging', () {
      test('generates fallback tags from title when no LLM engine', () async {
        final doc = await service.generateStudyGuide(
          topic: 'Python Programming',
          content:
              'Python is a versatile programming language used in web development and data science.',
        );

        expect(doc.tags, isNotEmpty);
        expect(doc.tags, contains('study'));
        expect(doc.tags, contains('guide'));
        expect(doc.tags, contains('python'));
        expect(doc.tags, contains('programming'));
      });

      test('generates fallback tags for quiz document', () async {
        final doc = await service.generateQuiz(
          topic: 'Mathematics',
          content: 'What is 2+2?\nA: 4',
        );

        expect(doc.tags, isNotEmpty);
        expect(doc.tags, contains('quiz'));
        expect(doc.tags, contains('mathematics'));
      });
    });

    group('buildContextPrompt', () {
      test('returns base prompt when memoryLines is empty', () {
        final result =
            service.buildContextPrompt('Write a study guide.', []);
        expect(result, 'Write a study guide.');
      });

      test('appends memory context when memoryLines are provided', () {
        final result = service.buildContextPrompt('Write a study guide.', [
          'User is studying biology',
          'User prefers concise explanations',
        ]);

        expect(result, contains('Write a study guide.'));
        expect(result, contains('Known context from past conversations'));
        expect(result, contains('User is studying biology'));
        expect(result, contains('User prefers concise explanations'));
      });
    });
  });
}
