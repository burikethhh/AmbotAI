import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/engine_selector.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';

class DesktopStatusBar extends ConsumerWidget {
  const DesktopStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    final engineSelection = ref.watch(engineSelectionProvider);

    final status = engineSelection.when(
      data: (s) {
        switch (s.mode) {
          case EngineMode.local:
            return 'LOCAL AI';
          case EngineMode.cloud:
            return 'CLOUD (${s.cloudProvider?.name.toUpperCase() ?? "AI"})';
          case EngineMode.mock:
            return 'DEMO';
        }
      },
      loading: () => 'LOADING...',
      error: (e, _) => 'ERROR',
    );

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: c.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: status == 'ERROR' ? Colors.red : Colors.green),
          const SizedBox(width: 6),
          Text(status, style: AppTypography.labelSmall(c.textTertiary)),
          const Spacer(),
          Text(
            Platform.operatingSystem.toUpperCase(),
            style: AppTypography.labelSmall(c.textTertiary),
          ),
          const SizedBox(width: 12),
          Text(
            'v1.6.6',
            style: AppTypography.labelSmall(c.textTertiary),
          ),
        ],
      ),
    );
  }
}
