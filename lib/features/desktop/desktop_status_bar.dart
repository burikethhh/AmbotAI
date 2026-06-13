import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/engine_selector.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/version_check_service.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/theme_colors.dart';

class DesktopUpdateBanner extends ConsumerWidget {
  const DesktopUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    final updateAsync = ref.watch(updateCheckFutureProvider);
    final hasUpdate = updateAsync.valueOrNull?.status == UpdateStatus.updateAvailable;

    if (!hasUpdate) return const SizedBox.shrink();

    final latest = updateAsync.valueOrNull?.latest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8EAF6),
        border: Border(
          bottom: BorderSide(color: c.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update_outlined, size: 16, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Update v${latest?.version ?? ''} available',
              style: AppTypography.bodyMedium(c.textPrimary),
            ),
          ),
          if (latest?.changelog != null)
            Text(
              latest!.changelog!.split('\n').first,
              style: AppTypography.bodySmall(c.textSecondary),
            ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                final url = latest?.updateUrl;
                if (url != null && url.isNotEmpty) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: c.borderColor, width: 1),
                ),
                child: Text('DOWNLOAD', style: AppTypography.labelSmall(c.textPrimary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
