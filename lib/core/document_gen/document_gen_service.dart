import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'pdf_generator.dart';
import '../storage/output_storage_service.dart';
import '../ai/ai_engine.dart';

/// Types of documents that can be generated.
enum DocumentType {
  studyGuide('Study Guide'),
  quiz('Quiz'),
  flashcards('Flashcards'),
  summary('Summary'),
  lessonPlan('Lesson Plan'),
  essay('Essay'),
  report('Report'),
  general('Document');

  const DocumentType(this.label);
  final String label;
}

/// Difficulty levels for study materials.
enum StudyGuideLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced'),
  expert('Expert');

  const StudyGuideLevel(this.label);
  final String label;
}

/// Types of quiz questions.
enum QuizType {
  multipleChoice('Multiple Choice'),
  trueFalse('True/False'),
  fillInTheBlank('Fill in the Blank'),
  shortAnswer('Short Answer'),
  matching('Matching');

  const QuizType(this.label);
  final String label;
}

/// Summary output formats.
enum SummaryFormat {
  bulletPoints('Bullet Points'),
  paragraph('Paragraph'),
  outline('Outline'),
  mindMap('Mind Map');

  const SummaryFormat(this.label);
  final String label;
}

/// Represents a generated document ready for export.
class GeneratedDocument {
  final DocumentType type;
  final String title;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final List<String> tags;
  String? _pdfPath;
  String? _docxPath;

  GeneratedDocument({
    required this.type,
    required this.title,
    required this.content,
    required this.metadata,
    DateTime? createdAt,
    this.tags = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  String? get pdfPath => _pdfPath;
  String? get docxPath => _docxPath;

  bool get isExported => _pdfPath != null || _docxPath != null;

  void markPdfExported(String path) {
    _pdfPath = path;
  }

  void markDocxExported(String path) {
    _docxPath = path;
  }
}

/// Document generation service that creates real PDF and DOCX files.
class DocumentGenService {
  DocumentGenService._();
  static final DocumentGenService instance = DocumentGenService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Generate a study guide document.
  Future<GeneratedDocument> generateStudyGuide({
    required String topic,
    required String content,
    StudyGuideLevel level = StudyGuideLevel.intermediate,
    bool includeSummary = true,
    bool includeKeyTerms = true,
    bool includePracticeQuestions = true,
    AIEngine? llmEngine,
    List<String> memoryLines = const [],
  }) async {
    final doc = GeneratedDocument(
      type: DocumentType.studyGuide,
      title: 'Study Guide: $topic',
      content: content,
      metadata: {
        'topic': topic,
        'level': level.name,
        'includeSummary': includeSummary,
        'includeKeyTerms': includeKeyTerms,
        'includePracticeQuestions': includePracticeQuestions,
      },
      tags: await _autoTag('Study Guide: $topic', content, llmEngine),
    );
    return doc;
  }

  /// Generate a quiz document.
  Future<GeneratedDocument> generateQuiz({
    required String topic,
    required String content,
    int questionCount = 10,
    QuizType quizType = QuizType.multipleChoice,
    bool includeAnswers = false,
    AIEngine? llmEngine,
    List<String> memoryLines = const [],
  }) async {
    final doc = GeneratedDocument(
      type: DocumentType.quiz,
      title: 'Quiz: $topic',
      content: content,
      metadata: {
        'topic': topic,
        'questionCount': questionCount,
        'quizType': quizType.name,
        'includeAnswers': includeAnswers,
      },
      tags: await _autoTag('Quiz: $topic', content, llmEngine),
    );
    return doc;
  }

  /// Generate flashcards.
  Future<GeneratedDocument> generateFlashcards({
    required String topic,
    required String content,
    int cardCount = 20,
    AIEngine? llmEngine,
    List<String> memoryLines = const [],
  }) async {
    final doc = GeneratedDocument(
      type: DocumentType.flashcards,
      title: 'Flashcards: $topic',
      content: content,
      metadata: {
        'topic': topic,
        'cardCount': cardCount,
      },
      tags: await _autoTag('Flashcards: $topic', content, llmEngine),
    );
    return doc;
  }

  /// Generate a summary document.
  Future<GeneratedDocument> generateSummary({
    required String title,
    required String content,
    SummaryFormat format = SummaryFormat.bulletPoints,
    AIEngine? llmEngine,
    List<String> memoryLines = const [],
  }) async {
    final doc = GeneratedDocument(
      type: DocumentType.summary,
      title: title,
      content: content,
      metadata: {'format': format.name},
      tags: await _autoTag(title, content, llmEngine),
    );
    return doc;
  }

  /// Generate a lesson plan.
  Future<GeneratedDocument> generateLessonPlan({
    required String topic,
    required String content,
    int durationMinutes = 60,
    String? targetAudience,
    AIEngine? llmEngine,
    List<String> memoryLines = const [],
  }) async {
    final doc = GeneratedDocument(
      type: DocumentType.lessonPlan,
      title: 'Lesson Plan: $topic',
      content: content,
      metadata: {
        'topic': topic,
        'durationMinutes': durationMinutes,
        'targetAudience': targetAudience,
      },
      tags: await _autoTag('Lesson Plan: $topic', content, llmEngine),
    );
    return doc;
  }

  /// Generate a general document from AI response.
  Future<GeneratedDocument> generateFromResponse({
    required String title,
    required String aiResponse,
    DocumentType type = DocumentType.general,
    AIEngine? llmEngine,
  }) async {
    final doc = GeneratedDocument(
      type: type,
      title: title,
      content: aiResponse,
      metadata: {},
      tags: await _autoTag(title, aiResponse, llmEngine),
    );
    return doc;
  }

  /// Use the LLM to extract 3–5 topic tags from the document content.
  /// Falls back to extracting from title if LLM is unavailable.
  Future<List<String>> _autoTag(String title, String content, AIEngine? engine) async {
    if (engine == null || !engine.isReady) {
      return _fallbackTags(title);
    }
    try {
      final preview = content.length > 800 ? content.substring(0, 800) : content;
      final prompt = 'Extract 3-5 topic keywords/tags from this document. '
          'Return only the keywords separated by commas, no explanation.\n'
          'Title: $title\nContent: $preview';
      final response = await engine.generate(prompt);
      final tags = response.split(',').map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty).toList();
      return tags.length > 1 ? tags : _fallbackTags(title);
    } catch (_) {
      return _fallbackTags(title);
    }
  }

  List<String> _fallbackTags(String title) {
    final words = title.toLowerCase().split(RegExp(r'[\s,:;.?!]+')).where((w) => w.length > 3).toList();
    return words.take(5).toList();
  }

  /// Assembles system prompt enriched with relevant memories for document generation.
  String buildContextPrompt(String basePrompt, List<String> memoryLines) {
    if (memoryLines.isEmpty) return basePrompt;
    return '$basePrompt\n\nKnown context from past conversations:\n${memoryLines.join('\n')}\n'
        'Incorporate this context naturally when relevant.';
  }

  /// Export a document to PDF file and return the file path.
  Future<String> exportToPdf(GeneratedDocument document) async {
    final pdfPath = await PdfGenerator.generatePdf(
      title: document.title,
      content: document.content,
      type: document.type,
      metadata: document.metadata,
    );
    document.markPdfExported(pdfPath);
    await _saveTags(pdfPath, document.tags);
    return pdfPath;
  }

  /// Export a document to DOCX-compatible RTF file.
  Future<String> exportToDocx(GeneratedDocument document) async {
    final filePath = await OutputStorageService.instance.generatePath(OutputType.documents, 'rtf');
    final file = File(filePath);

    final buffer = StringBuffer();
    buffer.writeln('{\\rtf1\\ansi\\deff0');
    buffer.writeln('{\\fonttbl{\\f0\\fswiss\\fcharset0 Arial;}}');
    buffer.writeln('\\pard\\qc\\fs32\\b ${_escapeRtf(document.title)}\\b0\\par');
    buffer.writeln('\\pard\\fs20\\par');
    buffer.writeln('\\pard\\fs20 ${_escapeRtf(document.content)}\\par');
    buffer.writeln('}');

    await file.writeAsString(buffer.toString());
    document.markDocxExported(file.path);
    await _saveTags(filePath, document.tags);
    return file.path;
  }

  /// Export a document to text file.
  Future<String> exportToText(GeneratedDocument document) async {
    final filePath = await OutputStorageService.instance.generatePath(OutputType.documents, 'txt');
    final file = File(filePath);

    final buffer = StringBuffer();
    buffer.writeln('=' * 60);
    buffer.writeln(document.title.toUpperCase());
    buffer.writeln('Type: ${document.type.label}');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('=' * 60);
    buffer.writeln();
    buffer.writeln(document.content);

    await file.writeAsString(buffer.toString());
    await _saveTags(filePath, document.tags);
    return file.path;
  }

  /// Export a document to Markdown file.
  Future<String> exportToMarkdown(GeneratedDocument document) async {
    final filePath = await OutputStorageService.instance.generatePath(OutputType.documents, 'md');
    final file = File(filePath);

    final buffer = StringBuffer();
    buffer.writeln('# ${document.title}');
    buffer.writeln();
    buffer.writeln('**Type:** ${document.type.label}  ');
    buffer.writeln('**Generated:** ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(document.content);

    await file.writeAsString(buffer.toString());
    await _saveTags(filePath, document.tags);
    return file.path;
  }

  /// Share a document file via the system share sheet.
  /// Returns true if sharing was successful.
  static Future<bool> shareFile(String filePath, {String? subject}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Ambot AI Document',
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }

  /// Get all generated documents.
  Future<List<GeneratedFileInfo>> getGeneratedDocuments() async {
    final dir = await OutputStorageService.instance.dir(OutputType.documents);
    if (!await dir.exists()) return [];

    final files = <GeneratedFileInfo>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        files.add(GeneratedFileInfo(
          path: entity.path,
          name: entity.uri.pathSegments.last,
          size: stat.size,
          createdAt: stat.modified,
          type: DocumentType.general,
        ));
      }
    }

    files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files;
  }

  /// Delete a generated document.
  Future<void> deleteDocument(String path) async {
    await OutputStorageService.instance.deleteFile(path);
  }

  String _escapeRtf(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('\n', '\\par\n');
  }

  Future<void> _saveTags(String filePath, List<String> tags) async {
    if (tags.isEmpty) return;
    await OutputStorageService.instance.saveTags(filePath, tags);
  }
}

/// Information about a generated document file.
class GeneratedFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;
  final DocumentType type;

  const GeneratedFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.type,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }
}
