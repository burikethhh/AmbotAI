import 'dart:math';
import '../ai_engine.dart';

class MockAIEngine implements AIEngine {
  bool _isReady = false;
  final _random = Random();

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isReady = true;
  }

  @override
  Future<String> generate(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(700)));
    return _generateResponse(prompt, systemPrompt);
  }

  @override
  Stream<String> generateStream(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async* {
    final response = _generateResponse(prompt, systemPrompt);
    final words = response.split(' ');
    for (final word in words) {
      await Future.delayed(Duration(milliseconds: 20 + _random.nextInt(60)));
      yield '$word ';
    }
  }

  @override
  Future<void> dispose() async {
    _isReady = false;
  }

  @override
  Future<void> handleMemoryPressure() async {}

  @override
  void cancelStream() {}

  @override
  String get engineName => 'Mock Engine (Development)';

  @override
  DeviceTier get tier => DeviceTier.mid;

  @override
  bool get isReady => _isReady;

  String _generateResponse(String prompt, String? systemPrompt) {
    final lowerPrompt = prompt.toLowerCase();

    if (systemPrompt != null && systemPrompt.contains('quiz generator')) {
      return _quizResponse(prompt);
    }

    if (systemPrompt != null && systemPrompt.contains('simplifier')) {
      return _eli5Response(prompt);
    }

    if (systemPrompt != null && systemPrompt.contains('lesson plan')) {
      return _lessonResponse(prompt);
    }

    if (lowerPrompt.contains('hello') || lowerPrompt.contains('hi')) {
      return 'Hello! I\'m ready to help you learn. What would you like to explore today?';
    }

    if (lowerPrompt.contains('math') || lowerPrompt.contains('calculus')) {
      return 'That\'s a great math question. Let me break it down step by step.\n\n'
          '**Step 1:** First, let\'s identify what we\'re working with.\n\n'
          '**Step 2:** We can apply the relevant formula or principle here.\n\n'
          '**Step 3:** Working through the calculation gives us our answer.\n\n'
          'Would you like me to go deeper into any of these steps?';
    }

    if (lowerPrompt.contains('history') || lowerPrompt.contains('war')) {
      return 'This is a fascinating period in history. Here are the key points:\n\n'
          '**Context:** Understanding the broader situation helps us see why events unfolded as they did.\n\n'
          '**Key Events:** Several pivotal moments shaped the outcome.\n\n'
          '**Impact:** The lasting effects can still be seen today.\n\n'
          'Which aspect would you like to explore further?';
    }

    if (lowerPrompt.contains('science') || lowerPrompt.contains('physics')) {
      return 'Great science question! Let\'s approach this systematically.\n\n'
          '**The Concept:** At its core, this involves fundamental principles that govern how things work.\n\n'
          '**How It Works:** Think of it like this — imagine a simple everyday example.\n\n'
          '**Why It Matters:** Understanding this helps us make sense of the world around us.\n\n'
          'Shall I explain any part in more detail?';
    }

    return 'That\'s an interesting question. Let me think about this carefully.\n\n'
        'Here\'s my understanding:\n\n'
        '**Key Point 1:** The most important thing to understand is the foundation of this topic.\n\n'
        '**Key Point 2:** Building on that, we can see how different elements connect.\n\n'
        '**Key Point 3:** Finally, the practical application ties everything together.\n\n'
        'Would you like me to elaborate on any of these points, or would you prefer a different angle?';
  }

  String _quizResponse(String prompt) {
    return '**Quiz: Based on your notes**\n\n'
        '**Question 1** (Multiple Choice)\n'
        'What is the primary concept discussed in the material?\n'
        'a) Option A\n'
        'b) Option B\n'
        'c) Option C\n'
        'd) Option D\n'
        'Answer: b) Option B\n\n'
        '**Question 2** (True/False)\n'
        'The secondary concept directly supports the primary one.\n'
        'Answer: True\n\n'
        '**Question 3** (Fill in the blank)\n'
        'The process involves three steps: first _____, then analysis, and finally synthesis.\n'
        'Answer: observation\n\n'
        'Want me to generate more questions or adjust the difficulty?';
  }

  String _eli5Response(String prompt) {
    return '**Like you\'re 5:**\n'
        'Imagine you have a big box of building blocks. This concept is like stacking them up '
        'in a special way so they don\'t fall down.\n\n'
        '**Like you\'re in high school:**\n'
        'This is a structured approach where multiple components interact according to '
        'defined principles to produce a predictable outcome.\n\n'
        '**Like you\'re in college:**\n'
        'The underlying theory involves systematic analysis of interrelated variables, '
        'governed by established frameworks and empirical evidence.\n\n'
        'Which level would you like me to stick with?';
  }

  String _lessonResponse(String prompt) {
    return '**Lesson Plan**\n\n'
        '**Subject:** As specified\n'
        '**Duration:** 50 minutes\n'
        '**Objective:** Students will understand and apply the key concepts.\n\n'
        '**Warm-up (5 min)**\n'
        'Quick discussion prompt to activate prior knowledge.\n\n'
        '**Direct Instruction (15 min)**\n'
        'Present core concepts with examples and visual aids.\n\n'
        '**Guided Practice (15 min)**\n'
        'Students work through problems with teacher support.\n\n'
        '**Independent Practice (10 min)**\n'
        'Students apply concepts independently.\n\n'
        '**Closure (5 min)**\n'
        'Exit ticket: 3 things learned, 2 connections made, 1 question remaining.\n\n'
        'Shall I adjust the timing or add differentiation strategies?';
  }
}
