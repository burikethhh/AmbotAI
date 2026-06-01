import 'package:flutter/material.dart';

/// The vertical domain a role belongs to. Used by the Role Hub for
/// filtering and by analytics to group usage.
///
/// [category] (student/teacher/universal) still describes the audience;
/// [RoleDomain] describes the subject-matter vertical.
enum RoleDomain {
  education,
  agriculture,
  medicine,
  mentalHealth,
  law,
  engineering,
  business,
  languages,
  creative,
  productivity,
  general,
}

/// Scope of long-term memory for a role. Determines where extracted
/// facts are stored and which memories are injected on each turn.
enum MemoryScope {
  /// No long-term memory. Only the current chat's messages are used.
  none,

  /// Memory is stored per chat. Useful for document-grounded sessions.
  chat,

  /// Memory is stored per role. Every chat with that role shares it.
  role,

  /// Memory is stored globally and available to every role.
  global,
}

/// Minimum device tier required to run a role comfortably.
enum DeviceTier {
  lowEnd,
  mid,
  flagship,
}

extension RoleDomainX on RoleDomain {
  String get label {
    switch (this) {
      case RoleDomain.education:
        return 'Education';
      case RoleDomain.agriculture:
        return 'Agriculture';
      case RoleDomain.medicine:
        return 'Medicine';
      case RoleDomain.mentalHealth:
        return 'Mental Health';
      case RoleDomain.law:
        return 'Law';
      case RoleDomain.engineering:
        return 'Engineering';
      case RoleDomain.business:
        return 'Business';
      case RoleDomain.languages:
        return 'Languages';
      case RoleDomain.creative:
        return 'Creative';
      case RoleDomain.productivity:
        return 'Productivity';
      case RoleDomain.general:
        return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case RoleDomain.education:
        return Icons.school_outlined;
      case RoleDomain.agriculture:
        return Icons.agriculture_outlined;
      case RoleDomain.medicine:
        return Icons.medical_services_outlined;
      case RoleDomain.mentalHealth:
        return Icons.self_improvement_outlined;
      case RoleDomain.law:
        return Icons.gavel_outlined;
      case RoleDomain.engineering:
        return Icons.engineering_outlined;
      case RoleDomain.business:
        return Icons.business_center_outlined;
      case RoleDomain.languages:
        return Icons.translate_outlined;
      case RoleDomain.creative:
        return Icons.palette_outlined;
      case RoleDomain.productivity:
        return Icons.task_alt_outlined;
      case RoleDomain.general:
        return Icons.all_inclusive_outlined;
    }
  }
}

extension MemoryScopeX on MemoryScope {
  String get label {
    switch (this) {
      case MemoryScope.none:
        return 'No memory';
      case MemoryScope.chat:
        return 'Per-chat memory';
      case MemoryScope.role:
        return 'Per-role memory';
      case MemoryScope.global:
        return 'Global memory';
    }
  }
}

extension DeviceTierX on DeviceTier {
  String get label {
    switch (this) {
      case DeviceTier.lowEnd:
        return 'Low-end';
      case DeviceTier.mid:
        return 'Mid-range';
      case DeviceTier.flagship:
        return 'Flagship';
    }
  }
}
