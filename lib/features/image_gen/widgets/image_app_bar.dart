import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class ImageAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ImageAppBar({super.key});

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
      title: Text('IMAGE GEN', style: AppTypography.headlineMedium(c.textPrimary)),
    );
  }
}
