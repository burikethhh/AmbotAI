import 'dart:math' as math;

class AppKnowledge {
  static List<String> get sections => _sections;

  /// Retrieve the most relevant knowledge sections for a user query.
  static List<String> retrieve(String query, {int topK = 3}) {
    final qTokens = _tokenize(query);
    if (qTokens.isEmpty) return _sections.take(topK).toList();

    final scored = <_Scored>[];
    for (final section in _sections) {
      final sTokens = _tokenize(section);
      var overlap = 0;
      for (final t in qTokens) {
        if (sTokens.contains(t)) overlap++;
      }
      final score = sTokens.isEmpty ? 0.0 : overlap / math.max(qTokens.length, 1);
      if (score > 0) scored.add(_Scored(section, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).map((s) => s.text).toList();
  }

  /// Build a context block to inject into the system prompt.
  static String buildContext(String userMessage) {
    final relevant = retrieve(userMessage);
    if (relevant.isEmpty) return '';
    return '\n[APP KNOWLEDGE]\n${relevant.join('\n\n')}\n[/APP KNOWLEDGE]';
  }

  static final _nonWord = RegExp(r'[^a-z0-9]+');
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
    final parts = lower.split(_nonWord)
        .where((t) => t.isNotEmpty && t.length > 2 && !_stopwords.contains(t));
    return parts.toSet();
  }

  static const _sections = [
    // === WHAT IS AMBOT AI ===
    'Ambot AI is an offline-first artificial intelligence assistant designed for Android mobile devices. '
        'It runs entirely on-device using local AI models — no internet connection or cloud API keys are required for core functionality. '
        'The app is built with Flutter and Riverpod for state management, and uses native C++ bindings through llama.cpp and MediaPipe for on-device inference.',

    // === CREATOR ===
    'Ambot AI was created by a developer with the username "DEVinci" (also known as "codeitman"). '
        'The project is an open-source personal assistant platform focused on privacy, offline capabilities, and mobile-first AI interaction.',

    // === CORE FEATURES ===
    'Ambot AI has five core features: Chat, Agent Driven Environment, Image Generation, Voice Generation, and Document Generation. '
        'The Chat feature provides conversational AI with thinking and planning modes. '
        'Agent Driven Environment provides device control and automation through voice or text commands. '
        'Image Generation creates images using Stable Diffusion models running locally on the device. '
        'Voice Generation synthesizes speech using Piper TTS models. '
        'Document Generation creates study guides, quizzes, flashcards, summaries, and lesson plans.',

    // === LOCAL AI MODELS ===
    'Ambot AI supports multiple local AI models that run entirely on-device. '
        'Text models include Google Gemma 3 (1B and 4B), Microsoft Phi-4 Mini (3.8B), LLaMA 3.2 (1B and 3B), and Qwen 2.5 (1.5B and 3B) in various quantizations optimized for mobile. '
        'Image generation uses Stable Diffusion 1.5, SDXL Turbo, and FLUX.1-schnell models optimized for ARM devices. '
        'Voice synthesis uses Piper TTS models from the rhasspy/piper-voices repository with multiple English accents. '
        'Models are downloaded from HuggingFace and managed through an in-app model manager with progress, pause, resume, and cancel support. '
        'Google Gemma 3 and Phi-4 Mini are the recommended models for the best quality-speed tradeoff on modern devices.',

    // === PRIVACY ===
    'Ambot AI is designed with privacy as a core principle. '
        'All AI processing happens on-device — no user data, messages, or files are sent to external servers. '
        'The app does not require an internet connection for normal operation. '
        'Cloud API keys are optional and only used as a fallback when no local model is available. '
        'User conversations, memories, and documents are stored locally on the device only.',

    // === MEMORY SYSTEM ===
    'Ambot AI includes a persistent memory system that allows the AI to remember information across conversations. '
        'Memories can be global, role-scoped, or chat-scoped. '
        'The memory system uses keyword-based retrieval (not embeddings) to stay lightweight on mobile hardware. '
        'Users can enable or disable memory at any time from the settings or the memory screen.',

    // === RAG FEATURES ===
    'Ambot AI includes several Retrieval-Augmented Generation features: '
        'Document Q&A allows pasting text and asking questions about it using keyword-overlap chunk retrieval. '
        'Memory-Augmented Generation enriches document creation with relevant context from stored memories. '
        'Conversation Full-Text Search enables searching past conversations by content. '
        'Auto-Tagging automatically categorizes generated documents using the AI model. '
        'Session Context Compression summarizes old conversation turns to stay within context limits.',

    // === VOICE GENERATION ===
    'Ambot AI generates speech using Piper TTS models downloaded from HuggingFace. '
        'The app supports multiple English voices with different accents and qualities (low, medium). '
        'Voice generation runs on-device through Android\'s TextToSpeech engine as a fallback. '
        'Generated audio files are saved to the ambot_output/voice/ directory and can be played, shared, or deleted.',

    // === IMAGE GENERATION ===
    'Ambot AI generates images using Stable Diffusion models optimized for mobile devices. '
        'The app supports multiple SD model variants for different quality/speed tradeoffs. '
        'Images are generated locally using native C++ bindings, with GPU acceleration when available. '
        'Generated images are saved to the ambot_output/images/ directory.',

    // === DOCUMENT GENERATION ===
    'Ambot AI can generate structured documents including study guides, quizzes, flashcards, summaries, and lesson plans. '
        'Documents can be exported as PDF or DOCX files. '
        'The built-in editor supports formatting (bold, italic, headings, lists), AI-assisted writing with tone selection, '
        'live word/character/line/paragraph statistics, and auto-save drafts. '
        'A smart formatter automatically fixes punctuation, spacing, heading style, and list formatting.',

    // === AGENT DRIVEN ENVIRONMENT ===
    'The Agent Driven Environment allows Ambot AI to control Android device functions through natural language commands. '
        'It can open apps, take screenshots, adjust settings, and perform automation tasks. '
        'The agent uses Android\'s accessibility service for device interaction. '
        'Safety rules prevent the AI from performing potentially dangerous operations.',

    // === DESIGN ===
    'Ambot AI features a minimalist black-and-white monochrome design. '
        'The interface is designed for mobile-first use with a clean, distraction-free aesthetic. '
        'The app uses Material Design components with a custom monochrome theme.',
  ];
}

class _Scored {
  final String text;
  final double score;
  const _Scored(this.text, this.score);
}
