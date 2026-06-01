import 'package:flutter/material.dart';
import '../../../shared/theme/app_typography.dart';

class SettingsTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class SettingsInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const SettingsInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(labelColor)),
        Text(value, style: AppTypography.labelMedium(valueColor)),
      ],
    );
  }
}

class SettingsKeyStatusRow extends StatelessWidget {
  final String label;
  final bool hasBuiltIn;
  final bool hasUser;
  final Color textPrimary;
  final Color textSecondary;
  final Color dotActive;
  final Color dotInactive;

  const SettingsKeyStatusRow({
    super.key,
    required this.label,
    required this.hasBuiltIn,
    required this.hasUser,
    required this.textPrimary,
    required this.textSecondary,
    required this.dotActive,
    required this.dotInactive,
  });

  @override
  Widget build(BuildContext context) {
    String status;
    Color dotColor;
    if (hasUser) {
      status = 'USER KEY';
      dotColor = dotActive;
    } else if (hasBuiltIn) {
      status = 'BUILT-IN';
      dotColor = dotActive;
    } else {
      status = 'NOT SET';
      dotColor = dotInactive;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(textSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(status, style: AppTypography.labelMedium(textPrimary)),
          ],
        ),
      ],
    );
  }
}
