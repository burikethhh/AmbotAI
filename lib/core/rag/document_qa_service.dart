import 'dart:math' as math;

class DocumentQaService {
  List<Chunk> _chunks = [];

  /// Ingest text by splitting into paragraph-sized chunks.
  void ingest(String text) {
    final raw = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join('\n');
    final paragraphs = raw.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    _chunks = paragraphs.asMap().entries.map((e) {
      return Chunk(index: e.key, text: e.value.trim());
    }).toList();
  }

  bool get hasContent => _chunks.isNotEmpty;
  int get chunkCount => _chunks.length;
  void clear() => _chunks = [];

  /// Find the top-k chunks most relevant to [question] using keyword overlap.
  List<ScoredChunk> retrieve(String question, {int topK = 5}) {
    if (_chunks.isEmpty) return [];
    final queryTokens = _tokenize(question);
    if (queryTokens.isEmpty) return _chunks.map((c) => ScoredChunk(c, 0)).toList();

    final scored = <ScoredChunk>[];
    for (final chunk in _chunks) {
      final score = _scoreChunk(chunk, queryTokens);
      if (score > 0) scored.add(ScoredChunk(chunk, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  /// Build a Q&A prompt from the retrieved chunks and the user's question.
  String buildQaPrompt(String question, {int topK = 5}) {
    final relevant = retrieve(question, topK: topK);
    if (relevant.isEmpty) return question;

    final context = relevant.map((s) => s.chunk.text).join('\n\n---\n\n');
    return 'Context from the document:\n$context\n\n---\n\nBased on the context above, answer: $question';
  }

  double _scoreChunk(Chunk chunk, Set<String> queryTokens) {
    final chunkTokens = _tokenize(chunk.text);
    if (chunkTokens.isEmpty) return 0.0;

    var overlap = 0;
    for (final t in queryTokens) {
      if (chunkTokens.contains(t)) overlap++;
    }
    if (overlap == 0) return 0.0;
    return overlap / math.max(queryTokens.length, 1);
  }

  static final RegExp _nonWord = RegExp(r'[^a-z0-9]+');
  static const _stopwords = <String>{
    'the', 'a', 'an', 'and', 'or', 'but', 'if', 'then', 'is', 'are', 'was',
    'were', 'be', 'been', 'being', 'i', 'you', 'he', 'she', 'it', 'we',
    'they', 'me', 'my', 'your', 'our', 'their', 'to', 'of', 'in', 'on',
    'at', 'for', 'with', 'by', 'as', 'this', 'that', 'these', 'those',
    'do', 'does', 'did', 'have', 'has', 'had', 'can', 'could', 'should',
    'would', 'will', 'just', 'about', 'so', 'not', 'no', 'yes',
  };

  static Set<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final parts = lower.split(_nonWord).where((t) => t.isNotEmpty && t.length > 2 && !_stopwords.contains(t));
    return parts.toSet();
  }
}

class Chunk {
  final int index;
  final String text;
  const Chunk({required this.index, required this.text});
}

class ScoredChunk {
  final Chunk chunk;
  final double score;
  const ScoredChunk(this.chunk, this.score);
}
