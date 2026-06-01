import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class RoleSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onChanged;

  const RoleSearchBar({required this.onChanged, super.key});

  @override
  ConsumerState<RoleSearchBar> createState() => _RoleSearchBarState();
}

class _RoleSearchBarState extends ConsumerState<RoleSearchBar> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.borderColor, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.search, color: c.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: AppTypography.bodyMedium(c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search roles...',
                  hintStyle: AppTypography.bodyMedium(c.textTertiary),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (v) {
                  setState(() => _query = v);
                  widget.onChanged(v);
                },
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 18, color: c.textSecondary),
                onPressed: () {
                  _controller.clear();
                  setState(() => _query = '');
                  widget.onChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }
}
