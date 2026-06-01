import 'package:flutter/material.dart';
import 'role_domain.dart';

enum RoleCategory { student, teacher, universal }

enum ResponseMode {
  chat,
  thinking,
  plan,
}

class Role {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final RoleCategory category;
  final RoleDomain domain;
  final List<String> tags;
  final IconData icon;
  final bool isCustom;
  final bool isInstalled;
  final DateTime createdAt;

  final bool acceptsText;
  final bool acceptsImage;
  final bool acceptsDocument;
  final bool producesImage;
  final MemoryScope defaultMemoryScope;
  final DeviceTier minimumTier;

  /// Default response mode for this role.
  final ResponseMode defaultResponseMode;

  /// Whether this role supports autonomous background processing.
  final bool supportsAutonomous;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.category,
    required this.icon,
    required this.createdAt,
    this.domain = RoleDomain.education,
    this.tags = const [],
    this.isCustom = false,
    this.isInstalled = false,
    this.acceptsText = true,
    this.acceptsImage = false,
    this.acceptsDocument = false,
    this.producesImage = false,
    this.defaultMemoryScope = MemoryScope.role,
    this.minimumTier = DeviceTier.lowEnd,
    this.defaultResponseMode = ResponseMode.chat,
    this.supportsAutonomous = false,
  });

  Role copyWith({
    String? name,
    String? description,
    String? systemPrompt,
    RoleCategory? category,
    RoleDomain? domain,
    List<String>? tags,
    IconData? icon,
    bool? isCustom,
    bool? isInstalled,
    bool? acceptsText,
    bool? acceptsImage,
    bool? acceptsDocument,
    bool? producesImage,
    MemoryScope? defaultMemoryScope,
    DeviceTier? minimumTier,
    ResponseMode? defaultResponseMode,
    bool? supportsAutonomous,
  }) {
    return Role(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      category: category ?? this.category,
      domain: domain ?? this.domain,
      tags: tags ?? this.tags,
      icon: icon ?? this.icon,
      isCustom: isCustom ?? this.isCustom,
      isInstalled: isInstalled ?? this.isInstalled,
      createdAt: createdAt,
      acceptsText: acceptsText ?? this.acceptsText,
      acceptsImage: acceptsImage ?? this.acceptsImage,
      acceptsDocument: acceptsDocument ?? this.acceptsDocument,
      producesImage: producesImage ?? this.producesImage,
      defaultMemoryScope: defaultMemoryScope ?? this.defaultMemoryScope,
      minimumTier: minimumTier ?? this.minimumTier,
      defaultResponseMode: defaultResponseMode ?? this.defaultResponseMode,
      supportsAutonomous: supportsAutonomous ?? this.supportsAutonomous,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'systemPrompt': systemPrompt,
        'category': category.name,
        'domain': domain.name,
        'tags': tags,
        'iconCodePoint': icon.codePoint,
        'isCustom': isCustom,
        'isInstalled': isInstalled,
        'createdAt': createdAt.toIso8601String(),
        'acceptsText': acceptsText,
        'acceptsImage': acceptsImage,
        'acceptsDocument': acceptsDocument,
        'producesImage': producesImage,
        'defaultMemoryScope': defaultMemoryScope.name,
        'minimumTier': minimumTier.name,
        'defaultResponseMode': defaultResponseMode.name,
        'supportsAutonomous': supportsAutonomous,
      };

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        systemPrompt: json['systemPrompt'] as String,
        category: RoleCategory.values.byName(json['category'] as String),
        domain: json['domain'] != null
            ? RoleDomain.values.byName(json['domain'] as String)
            : RoleDomain.education,
        tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
        icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
        isCustom: json['isCustom'] as bool? ?? false,
        isInstalled: json['isInstalled'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        acceptsText: json['acceptsText'] as bool? ?? true,
        acceptsImage: json['acceptsImage'] as bool? ?? false,
        acceptsDocument: json['acceptsDocument'] as bool? ?? false,
        producesImage: json['producesImage'] as bool? ?? false,
        defaultMemoryScope: json['defaultMemoryScope'] != null
            ? MemoryScope.values.byName(json['defaultMemoryScope'] as String)
            : MemoryScope.role,
        minimumTier: json['minimumTier'] != null
            ? DeviceTier.values.byName(json['minimumTier'] as String)
            : DeviceTier.lowEnd,
        defaultResponseMode: json['defaultResponseMode'] != null
            ? ResponseMode.values.byName(json['defaultResponseMode'] as String)
            : ResponseMode.chat,
        supportsAutonomous: json['supportsAutonomous'] as bool? ?? false,
      );
}
