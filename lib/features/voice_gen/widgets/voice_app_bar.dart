import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class VoiceAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showSettings;
  final VoidCallback onToggleSettings;

  const VoiceAppBar({
    super.key,
    required this.showSettings,
    required this.onToggleSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textPrimary),
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('VOICE', style: AppTypography.headlineMedium(c.textPrimary)),
      actions: [
        IconButton(
          icon: Icon(Icons.tune,
              color: showSettings ? AppColors.accent(c.isDark) : c.textPrimary),
          onPressed: onToggleSettings,
          tooltip: 'Voice Settings',
        ),
      ],
    );
  }
}
