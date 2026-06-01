import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/roles/role_domain.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class RoleFilterBar extends ConsumerWidget {
  final RoleDomain? selectedDomain;
  final ValueChanged<RoleDomain?> onDomainChanged;

  const RoleFilterBar({
    required this.selectedDomain,
    required this.onDomainChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _DomainChip(
            label: 'ALL',
            icon: Icons.apps_outlined,
            isSelected: selectedDomain == null,
            isDark: c.isDark,
            onTap: () => onDomainChanged(null),
          ),
          const SizedBox(width: 8),
          ...RoleDomain.values.map((d) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _DomainChip(
                  label: d.name.toUpperCase(),
                  icon: d.icon,
                  isSelected: selectedDomain == d,
                  isDark: c.isDark,
                  onTap: () => onDomainChanged(d),
                ),
              )),
        ],
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _DomainChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.white : AppColors.black)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.white : AppColors.black)
                : borderColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? AppColors.black : AppColors.white)
                  : textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSmall(
                isSelected
                    ? (isDark ? AppColors.black : AppColors.white)
                    : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
