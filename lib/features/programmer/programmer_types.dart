class ChatMessage {
  final String role;
  final String content;
  final bool isStreaming;

  const ChatMessage({
    required this.role,
    required this.content,
    this.isStreaming = false,
  });
}

class ProjectFile {
  final String filename;
  final String content;
  final String language;

  const ProjectFile({
    required this.filename,
    required this.content,
    required this.language,
  });

  ProjectFile copyWith({String? filename, String? content, String? language}) {
    return ProjectFile(
      filename: filename ?? this.filename,
      content: content ?? this.content,
      language: language ?? this.language,
    );
  }

  String get extension {
    final dot = filename.lastIndexOf('.');
    return dot == -1 ? '' : filename.substring(dot);
  }

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'content': content,
        'language': language,
      };

  factory ProjectFile.fromJson(Map<String, dynamic> json) => ProjectFile(
        filename: json['filename'] as String,
        content: json['content'] as String,
        language: json['language'] as String,
      );
}
