import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/engine_selector.dart';
import '../../core/platform/platform_guard.dart';
import '../../core/platform/desktop_keyboard.dart';
import '../../core/platform/window_manager.dart';
import '../../core/providers/app_providers.dart';
import '../../core/roles/role.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/theme_colors.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/general_chat/general_chat_screen.dart';
import '../../features/document_gen/document_gen_screen.dart';
import '../../features/image_gen/image_gen_screen.dart';
import '../../features/programmer/programmer_screen.dart';
import '../../features/memory/memory_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/models_screen.dart';
import '../../features/roles/roles_browser_screen.dart';
import 'desktop_drag_drop.dart';
import 'desktop_status_bar.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/desktop_toast.dart';
import 'widgets/desktop_command_palette.dart';

class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen> {
  int _selectedIndex = 0;
  Role? _selectedRole;
  bool _sidebarCollapsed = false;
  bool _showCommandPalette = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWindow();
      DesktopToastManager().init(context);
    });
  }

  Future<void> _initWindow() async {
    if (PlatformGuard.isWindows || PlatformGuard.isMacOS || PlatformGuard.isLinux) {
      await DesktopWindowManager.setMinimumSize(900, 600);
      await DesktopWindowManager.centerWindow();
      await DesktopWindowManager.setTitle('Ambot AI');
    }
  }

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedRole = null;
    });
  }

  void _handleNewChat() {
    _navigateTo(0);
    DesktopToastManager().show('New chat started', icon: Icons.chat_bubble_outline);
  }

  void _handleSearch() {
    setState(() => _showCommandPalette = true);
  }

  void _handleSettings() {
    _navigateTo(8);
  }

  void _handleCommandNavigate(int index) {
    _navigateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    final engineSelection = ref.watch(engineSelectionProvider);
    final subtitle = engineSelection.when(
      data: (s) {
        switch (s.mode) {
          case EngineMode.local:
            return 'LOCAL';
          case EngineMode.cloud:
            return s.cloudProvider?.name.toUpperCase() ?? 'CLOUD';
          case EngineMode.mock:
            return 'DEMO';
        }
      },
      loading: () => 'LOADING...',
      error: (e, _) => 'ERROR',
    );

    return DesktopKeyboardHandler(
      onNewChat: _handleNewChat,
      onSearch: _handleSearch,
      onSettings: _handleSettings,
      child: DesktopDragDropHandler(
        onFilesDropped: _handleFilesDropped,
        child: Scaffold(
          backgroundColor: c.surfaceColor,
          body: Column(
            children: [
              DesktopTitleBar(
                onCollapseSidebar: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                sidebarCollapsed: _sidebarCollapsed,
              ),
              Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: _sidebarCollapsed ? 52 : 240,
                      child: _buildSidebar(c, subtitle),
                    ),
                    Container(width: 1, color: c.borderColor),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
              const DesktopStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFilesDropped(List<String> files) {
    _navigateTo(3);
    DesktopToastManager().show(
      '${files.length} file(s) dropped',
      icon: Icons.upload_file,
    );
  }

  Widget _buildSidebar(ThemeColors c, String subtitle) {
    return Container(
      color: c.isDark ? const Color(0xFF111111) : const Color(0xFFFAFAFA),
      child: Column(
        children: [
          if (!_sidebarCollapsed) _buildSidebarHeader(c, subtitle),
          if (_sidebarCollapsed) const SizedBox(height: 12),
          Expanded(
            child: _sidebarCollapsed
                ? _buildCollapsedNav(c)
                : _buildExpandedNav(c, subtitle),
          ),
          if (!_sidebarCollapsed) _buildSidebarFooter(c),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(ThemeColors c, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: c.isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: c.isDark ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AMBOT',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: subtitle == 'ERROR' ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: subtitle == 'ERROR' ? AppColors.error : AppColors.success,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'v1.6.6',
                style: TextStyle(fontSize: 10, color: c.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedNav(ThemeColors c) {
    final items = [
      _NavData(icon: Icons.chat_outlined, index: 0, tooltip: 'General Chat'),
      _NavData(icon: Icons.forum_outlined, index: 1, tooltip: 'Role Chat'),
      _NavData(icon: Icons.image_outlined, index: 2, tooltip: 'Image Gen'),
      _NavData(icon: Icons.description_outlined, index: 3, tooltip: 'Documents'),
      _NavData(icon: Icons.code_outlined, index: 4, tooltip: 'Programmer'),
      _NavData(icon: Icons.apps_outlined, index: 5, tooltip: 'All Roles'),
      _NavData(icon: Icons.storage_outlined, index: 6, tooltip: 'Models'),
      _NavData(icon: Icons.memory_outlined, index: 7, tooltip: 'Memory'),
      _NavData(icon: Icons.settings_outlined, index: 8, tooltip: 'Settings'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIndex == item.index;

        return Tooltip(
          message: item.tooltip,
          waitDuration: const Duration(milliseconds: 400),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _navigateTo(item.index),
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (c.isDark ? AppColors.cardDark : AppColors.cardLight)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? c.textPrimary : c.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedNav(ThemeColors c, String subtitle) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      children: [
        _buildNavSection(c, 'CHAT', [
          _NavItemData(icon: Icons.chat_outlined, label: 'General Chat', index: 0, shortcut: '⌘1'),
          _NavItemData(icon: Icons.forum_outlined, label: 'Role Chat', index: 1, shortcut: '⌘2'),
        ]),
        const SizedBox(height: 8),
        _buildNavSection(c, 'CREATE', [
          _NavItemData(icon: Icons.image_outlined, label: 'Image Gen', index: 2, shortcut: '⌘3'),
          _NavItemData(icon: Icons.description_outlined, label: 'Documents', index: 3, shortcut: '⌘4'),
          _NavItemData(icon: Icons.code_outlined, label: 'Programmer', index: 4, shortcut: '⌘5'),
        ]),
        const SizedBox(height: 8),
        _buildNavSection(c, 'BROWSE', [
          _NavItemData(icon: Icons.apps_outlined, label: 'All Roles', index: 5, shortcut: '⌘6'),
          _NavItemData(icon: Icons.storage_outlined, label: 'Models', index: 6, shortcut: '⌘7'),
          _NavItemData(icon: Icons.memory_outlined, label: 'Memory', index: 7, shortcut: '⌘8'),
        ]),
        const SizedBox(height: 8),
        _buildNavSection(c, 'SYSTEM', [
          _NavItemData(icon: Icons.settings_outlined, label: 'Settings', index: 8, shortcut: '⌘,'),
        ]),
      ],
    );
  }

  Widget _buildNavSection(ThemeColors c, String title, List<_NavItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4, top: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildNavItem(c, item)),
      ],
    );
  }

  Widget _buildNavItem(ThemeColors c, _NavItemData item) {
    final isSelected = _selectedIndex == item.index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateTo(item.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (c.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: c.isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isSelected ? c.textPrimary : c.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
              if (item.shortcut != null)
                Text(
                  item.shortcut!,
                  style: TextStyle(
                    fontSize: 10,
                    color: c.textTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(ThemeColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 5, color: AppColors.success),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              Platform.operatingSystem.toUpperCase(),
              style: TextStyle(fontSize: 10, color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        _buildContentForIndex(),
        if (_showCommandPalette)
          DesktopCommandPalette(
            onNavigate: _handleCommandNavigate,
            onClose: () => setState(() => _showCommandPalette = false),
          ),
      ],
    );
  }

  Widget _buildContentForIndex() {
    switch (_selectedIndex) {
      case 0:
        return const GeneralChatScreen();
      case 1:
        if (_selectedRole != null) {
          return ChatScreen(role: _selectedRole!);
        }
        return _RolePicker(
          onRoleSelected: (role) => setState(() {
            _selectedRole = role;
          }),
        );
      case 2:
        return const ImageGenScreen();
      case 3:
        return const DocumentGenScreen();
      case 4:
        return const ProgrammerScreen();
      case 5:
        return const RolesBrowserScreen();
      case 6:
        return const ModelsScreen();
      case 7:
        return const MemoryScreen();
      case 8:
        return const SettingsScreen();
      default:
        return const GeneralChatScreen();
    }
  }
}

class _NavData {
  final IconData icon;
  final int index;
  final String tooltip;

  const _NavData({required this.icon, required this.index, required this.tooltip});
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int index;
  final String? shortcut;

  const _NavItemData({
    required this.icon,
    required this.label,
    required this.index,
    this.shortcut,
  });
}

class _RolePicker extends ConsumerWidget {
  final Function(Role) onRoleSelected;
  const _RolePicker({required this.onRoleSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    final roles = ref.watch(rolesProvider);
    final installed = roles.where((r) => r.isInstalled).toList();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 48, color: c.textTertiary),
          const SizedBox(height: 16),
          Text(
            'SELECT A ROLE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a persona to start chatting',
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: installed.map((role) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onRoleSelected(role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.borderColor, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
