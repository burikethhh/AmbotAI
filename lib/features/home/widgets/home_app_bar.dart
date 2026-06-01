import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/ambot_avatar.dart';

class HomeAppBar extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final String subtitle;
  final VoidCallback onMenuTap;
  final VoidCallback onHelpTap;
  final VoidCallback onSettingsTap;

  const HomeAppBar({
    super.key,
    required this.animation,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.subtitle,
    required this.onMenuTap,
    required this.onHelpTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(animation),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onMenuTap,
                    child: Icon(Icons.menu, color: textSecondary, size: 24),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => context.pushNamed('generalChat'),
                    child: AmbotAvatar(size: 44, isDark: isDark),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMBOT AI',
                          style: AppTypography.displayLarge(textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.labelSmall(textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onHelpTap,
                  icon: Icon(Icons.help_outline, color: textSecondary),
                  tooltip: 'Quick Guide',
                ),
                IconButton(
                  onPressed: onSettingsTap,
                  icon: Icon(Icons.settings_outlined, color: textSecondary),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
