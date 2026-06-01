import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum MessageRole { user, assistant }

enum MessageAttachmentType { image, document }

class MessageAttachment {
  final MessageAttachmentType type;
  final String path;
  final String? caption;
  final int? width;
  final int? height;
  final Map<String, dynamic>? metadata;

  const MessageAttachment({
    required this.type,
    required this.path,
    this.caption,
    this.width,
    this.height,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'path': path,
        if (caption != null) 'caption': caption,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (metadata != null) 'metadata': metadata,
      };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) => MessageAttachment(
        type: MessageAttachmentType.values.byName(json['type'] as String),
        path: json['path'] as String,
        caption: json['caption'] as String?,
        width: json['width'] as int?,
        height: json['height'] as int?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final String? thinking;
  final List<String>? planSteps;
  final List<MessageAttachment>? attachments;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.isStreaming = false,
    this.thinking,
    this.planSteps,
    this.attachments,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    String? thinking,
    List<String>? planSteps,
    List<MessageAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      thinking: thinking ?? this.thinking,
      planSteps: planSteps ?? this.planSteps,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
        if (thinking != null) 'thinking': thinking,
        if (planSteps != null) 'planSteps': planSteps,
        if (attachments != null)
          'attachments': attachments!.map((a) => a.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        role: MessageRole.values.byName(json['role'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        thinking: json['thinking'] as String?,
        planSteps: (json['planSteps'] as List?)?.map((e) => e as String).toList(),
        attachments: (json['attachments'] as List?)
            ?.map((a) => MessageAttachment.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

class Conversation {
  final String id;
  final String roleId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    String? id,
    required this.roleId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get preview {
    if (messages.isEmpty) return 'New conversation';
    final lastMsg = messages.last;
    final text = lastMsg.content;
    return text.length > 80 ? '${text.substring(0, 80)}...' : text;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roleId': roleId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        roleId: json['roleId'] as String,
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
