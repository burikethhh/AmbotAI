import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/roles/role.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/long_press_preview.dart';
import '../../../shared/widgets/role_preview_popup.dart';

class RoleCard extends ConsumerWidget {
  final Role role;

  const RoleCard({required this.role, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    final installedRoles = ref.watch(rolesProvider);
    final isInstalled = installedRoles.any((r) => r.id == role.id);
    final roleWithInstallStatus = role.copyWith(isInstalled: isInstalled);

    return LongPressPreview(
      previewBuilder: (context) => RolePreviewPopup(role: role, c: c),
      child: Container(
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.borderColor, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppIcon(
              icon: role.icon,
              size: 48,
              backgroundColor: c.isDark
                  ? AppColors.cardDarkElevated
                  : AppColors.surfaceLight,
              iconColor: c.textSecondary,
              borderColor: c.borderColor,
              borderWidth: 1.5,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name.toUpperCase(),
                    style: AppTypography.headlineSmall(c.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: AppTypography.bodySmall(c.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        _MiniBadge(
                          label: role.category.name.toUpperCase(),
                          isDark: c.isDark,
                        ),
                        _MiniBadge(
                          label: role.domain.name.toUpperCase(),
                          isDark: c.isDark,
                        ),
                        if (role.acceptsImage)
                          _MiniBadge(label: 'IMAGE', isDark: c.isDark),
                        if (role.acceptsDocument)
                          _MiniBadge(label: 'DOC', isDark: c.isDark),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _InstallButton(role: roleWithInstallStatus, isDark: c.isDark),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: AppTypography.labelMicro(
          isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
      ),
    );
  }
}

class _InstallButton extends ConsumerWidget {
  final Role role;
  final bool isDark;

  const _InstallButton({required this.role, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (role.isInstalled) {
      return GestureDetector(
        onTap: () => ref.read(rolesProvider.notifier).toggleInstall(role.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.white : AppColors.black,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'INSTALLED',
            style: AppTypography.labelMedium(
              isDark ? AppColors.black : AppColors.white,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => ref.read(rolesProvider.notifier).toggleInstall(role.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 2,
          ),
        ),
        child: Text(
          'INSTALL',
          style: AppTypography.labelMedium(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}
