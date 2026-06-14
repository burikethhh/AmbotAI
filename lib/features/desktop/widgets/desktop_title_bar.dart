import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/window_manager.dart';
import '../../../shared/theme/theme_colors.dart';

class DesktopTitleBar extends ConsumerStatefulWidget {
  final VoidCallback? onCollapseSidebar;
  final bool sidebarCollapsed;

  const DesktopTitleBar({
    super.key,
    this.onCollapseSidebar,
    this.sidebarCollapsed = false,
  });

  @override
  ConsumerState<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends ConsumerState<DesktopTitleBar> {
  bool _isMaximized = false;
  bool _hoveringClose = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    final maximized = await DesktopWindowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = maximized);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return GestureDetector(
      onDoubleTap: () async {
        if (_isMaximized) {
          // Can't unmaximize via API easily, just ignore
        } else {
          await DesktopWindowManager.maximize();
          setState(() => _isMaximized = true);
        }
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F8F8),
          border: Border(
            bottom: BorderSide(color: c.borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            _buildSidebarToggle(c),
            const SizedBox(width: 8),
            _buildAppIcon(c),
            const SizedBox(width: 8),
            _buildTitle(c),
            const Spacer(),
            _buildWindowControls(c),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarToggle(ThemeColors c) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onCollapseSidebar,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(
            widget.sidebarCollapsed ? Icons.menu : Icons.menu_open,
            size: 16,
            color: c.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(ThemeColors c) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: c.isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          'A',
          style: TextStyle(
            color: c.isDark ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeColors c) {
    return Text(
      'AMBOT AI',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: c.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildWindowControls(ThemeColors c) {
    return Row(
      children: [
        _WindowButton(
          icon: Icons.remove,
          color: c.textTertiary,
          onTap: () async {},
        ),
        _WindowButton(
          icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
          color: c.textTertiary,
          onTap: () async {
            if (_isMaximized) {
              await DesktopWindowManager.maximize();
            } else {
              await DesktopWindowManager.maximize();
            }
            setState(() => _isMaximized = !_isMaximized);
          },
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _hoveringClose = true),
          onExit: (_) => setState(() => _hoveringClose = false),
          child: GestureDetector(
            onTap: () async => await DesktopWindowManager.close(),
            child: Container(
              width: 46,
              height: 32,
              alignment: Alignment.center,
              color: _hoveringClose ? const Color(0xFFC42B1C) : Colors.transparent,
              child: Icon(
                Icons.close,
                size: 16,
                color: _hoveringClose ? Colors.white : c.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
