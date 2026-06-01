import 'package:flutter/material.dart';
import '../../core/roles/role.dart';
import '../../core/roles/role_domain.dart';
import '../theme/app_typography.dart';
import '../theme/theme_colors.dart';

class RolePreviewPopup extends StatelessWidget {
  final Role role;
  final ThemeColors c;

  const RolePreviewPopup({required this.role, required this.c, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(role.icon, size: 28, color: c.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  role.name.toUpperCase(),
                  style: AppTypography.headlineSmall(c.textPrimary),
                ),
              ),
              _MicroBadge(
                label: role.domain.label.toUpperCase(),
                c: c,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            role.description,
            style: AppTypography.bodySmall(c.textSecondary),
          ),
          if (role.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: role.tags.map((tag) => _MicroBadge(
                label: tag.toUpperCase(),
                c: c,
              )).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _PreviewChip(label: role.category.name.toUpperCase(), c: c),
              const SizedBox(width: 4),
              if (role.acceptsImage)
                _PreviewChip(label: 'IMAGE', c: c),
              if (role.acceptsDocument)
                _PreviewChip(label: 'DOC', c: c),
              if (role.producesImage)
                _PreviewChip(label: 'GEN-IMG', c: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicroBadge extends StatelessWidget {
  final String label;
  final ThemeColors c;

  const _MicroBadge({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: AppTypography.labelMicro(c.textTertiary),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final ThemeColors c;

  const _PreviewChip({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: AppTypography.labelMicro(c.textTertiary),
      ),
    );
  }
}
