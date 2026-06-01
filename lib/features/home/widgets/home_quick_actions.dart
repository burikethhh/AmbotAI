import 'package:flutter/material.dart';
import '../../../core/roles/role.dart';
import '../../../core/roles/role_domain.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/long_press_preview.dart';
import '../../../shared/widgets/role_preview_popup.dart';

class HomeQuickActions extends StatelessWidget {
  final Animation<double> headerAnimation;
  final Animation<double> gridAnimation;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderColor;
  final Color cardColor;
  final List<Role> installed;
  final VoidCallback onBrowseAll;
  final void Function(Role role) onRoleTap;

  const HomeQuickActions({
    super.key,
    required this.headerAnimation,
    required this.gridAnimation,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.cardColor,
    required this.installed,
    required this.onBrowseAll,
    required this.onRoleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: headerAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOUR ROLES',
                    style: AppTypography.headlineMedium(textPrimary),
                  ),
                  TextButton(
                    onPressed: onBrowseAll,
                    child: Text(
                      'BROWSE ALL',
                      style: AppTypography.labelLarge(textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                color: borderColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        FadeTransition(
          opacity: gridAnimation,
          child: installed.isEmpty
              ? _EmptyState(isDark: isDark, onBrowse: onBrowseAll)
              : GridView.custom(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  childrenDelegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == installed.length) {
                        return _AddRoleCard(
                          isDark: isDark,
                          onTap: onBrowseAll,
                        );
                      }
                      return LongPressPreview(
                        onTap: () => onRoleTap(installed[index]),
                        previewBuilder: (context) => RolePreviewPopup(
                          role: installed[index],
                          c: ThemeColors.of(context),
                        ),
                        child: _RoleCard(
                          role: installed[index],
                          isDark: isDark,
                          borderColor: borderColor,
                          textTertiary: textTertiary,
                        ),
                      );
                    },
                    childCount: installed.length + 1,
                  ),
                ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Role role;
  final bool isDark;
  final Color borderColor;
  final Color textTertiary;

  const _RoleCard({
    required this.role,
    required this.isDark,
    required this.borderColor,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final iconColor = isDark ? AppColors.silver : AppColors.grey;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            icon: role.icon,
            size: 44,
            backgroundColor: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
            iconColor: iconColor,
            borderColor: borderColor,
            borderWidth: 1.5,
          ),
          const SizedBox(height: 14),
          Text(
            role.name.toUpperCase(),
            style: AppTypography.headlineSmall(textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            role.description,
            style: AppTypography.bodySmall(textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _SimpleBadge(
                label: _categoryLabel(role.category),
                textColor: textTertiary,
                isDark: isDark,
              ),
              _DomainChip(domain: role.domain, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(RoleCategory cat) {
    switch (cat) {
      case RoleCategory.student:
        return 'STUDENT';
      case RoleCategory.teacher:
        return 'TEACHER';
      case RoleCategory.universal:
        return 'ALL';
    }
  }
}

class _SimpleBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final bool isDark;

  const _SimpleBadge({
    required this.label,
    required this.textColor,
    required this.isDark,
  });

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
        style: AppTypography.labelMicro(textColor),
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  const _DomainChip({required this.domain, required this.isDark});

  final RoleDomain domain;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final bg = isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(domain.icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            domain.name.toUpperCase(),
            style: AppTypography.labelMicro(color),
          ),
        ],
      ),
    );
  }
}

class _AddRoleCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddRoleCard({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: borderColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              icon: Icons.add_rounded,
              size: 40,
              backgroundColor: Colors.transparent,
              iconColor: textSecondary,
              borderColor: borderColor,
              borderWidth: 1.5,
            ),
            const SizedBox(height: 10),
            Text(
              'ADD ROLE',
              style: AppTypography.labelLarge(textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBrowse;

  const _EmptyState({required this.isDark, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              icon: Icons.apps_outlined,
              size: 56,
              backgroundColor: Colors.transparent,
              iconColor: textSecondary,
              borderColor: borderColor,
              borderWidth: 1.5,
            ),
            const SizedBox(height: 16),
            Text(
              'NO ROLES INSTALLED',
              style: AppTypography.bodyLarge(textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse and install roles to get started',
              style: AppTypography.bodySmall(textTertiary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onBrowse,
              child: const Text('BROWSE ROLES'),
            ),
          ],
        ),
      ),
    );
  }
}
