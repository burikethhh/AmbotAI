({String content, String? thinking, List<String>? planSteps})
parseResponse(String raw) {
  String? thinking;
  List<String>? planSteps;
  String content = raw;

  final thinkingStart = raw.indexOf('<thinking>');
  if (thinkingStart != -1) {
    final thinkingEnd = raw.indexOf('</thinking>', thinkingStart);
    if (thinkingEnd != -1) {
      thinking = raw.substring(thinkingStart + 10, thinkingEnd).trim();
      content = raw.replaceRange(thinkingStart, thinkingEnd + 11, '').trim();
    }
  }

  final planStart = content.indexOf('<plan>');
  if (planStart != -1) {
    final planEnd = content.indexOf('</plan>', planStart);
    if (planEnd != -1) {
      final planRaw = content.substring(planStart + 6, planEnd).trim();
      planSteps = planRaw
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => s.replaceFirst(RegExp(r'^Step\s*\d+:\s*'), ''))
          .toList();
      content = content.replaceRange(planStart, planEnd + 7, '').trim();
    }
  }

  return (content: content, thinking: thinking, planSteps: planSteps);
}

bool isImageRequest(String text) {
  final lower = text.toLowerCase();
  return lower.contains('generate image') ||
      lower.contains('create image') ||
      lower.contains('make an image') ||
      lower.contains('draw an image') ||
      lower.contains('generate picture') ||
      lower.contains('create picture') ||
      lower.contains('make an image') ||
      lower.contains('make a picture') ||
      lower.contains('generate a photo') ||
      lower.contains('create a photo') ||
      (lower.startsWith('image:') || lower.startsWith('image ')) ||
      (lower.startsWith('draw:') || lower.startsWith('draw '));
}

bool isDocumentRequest(String text) {
  final lower = text.toLowerCase();
  return lower.contains('generate document') ||
      lower.contains('create document') ||
      lower.contains('generate study guide') ||
      lower.contains('create study guide') ||
      lower.contains('generate quiz') ||
      lower.contains('create quiz') ||
      lower.contains('generate flashcard') ||
      lower.contains('create flashcard') ||
      lower.contains('generate summary') ||
      lower.contains('create summary') ||
      lower.contains('generate lesson plan') ||
      lower.contains('create lesson plan');
}
