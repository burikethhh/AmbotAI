import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/engine_selector.dart';
import '../../core/platform/platform_guard.dart';
import '../../core/platform/desktop_keyboard.dart';
import '../../core/platform/window_manager.dart';
import '../../core/providers/app_providers.dart';
import '../../core/roles/role.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
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
import 'desktop_context_menu.dart';
import 'desktop_status_bar.dart';

class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen> {
  int _selectedIndex = 0;
  Role? _selectedRole;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWindow();
    });
  }

  Future<void> _initWindow() async {
    if (PlatformGuard.isWindows || PlatformGuard.isMacOS || PlatformGuard.isLinux) {
      await DesktopWindowManager.setMinimumSize(900, 600);
      await DesktopWindowManager.centerWindow();
      await DesktopWindowManager.setTitle('Ambot AI - Desktop');
    }
  }

  void _handleNewChat() {
    setState(() {
      _selectedIndex = 0;
      _selectedRole = null;
    });
  }

  void _handleSearch() {
    // TODO: Implement search modal
  }

  void _handleSettings() {
    setState(() {
      _selectedIndex = 8;
      _selectedRole = null;
    });
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
              const DesktopUpdateBanner(),
              Expanded(
                child: Row(
                  children: [
                    _buildSidebar(c, subtitle),
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
    // Handle dropped files - switch to document gen or attach to chat
    setState(() {
      _selectedIndex = 3; // Documents
      _selectedRole = null;
    });
  }

  Widget _buildSidebar(ThemeColors c, String subtitle) {
    return Container(
      width: 220,
      color: c.surfaceColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.borderColor, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('AMBOT', style: AppTypography.headlineMedium(c.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: subtitle == 'ERROR'
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        border: Border.all(
                          color: subtitle == 'ERROR' ? Colors.red : Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        subtitle,
                        style: AppTypography.labelSmall(
                          subtitle == 'ERROR' ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('DESKTOP v1.6.6', style: AppTypography.labelSmall(c.textTertiary)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _SidebarItem(
                  icon: Icons.chat_outlined,
                  label: 'General Chat',
                  shortcut: 'Ctrl+N',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() { _selectedIndex = 0; _selectedRole = null; }),
                ),
                _SidebarItem(
                  icon: Icons.forum_outlined,
                  label: 'Role Chat',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _SidebarItem(
                  icon: Icons.image_outlined,
                  label: 'Image Gen',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() { _selectedIndex = 2; _selectedRole = null; }),
                ),
                _SidebarItem(
                  icon: Icons.description_outlined,
                  label: 'Documents',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() { _selectedIndex = 3; _selectedRole = null; }),
                ),
                _SidebarItem(
                  icon: Icons.code_outlined,
                  label: 'Programmer',
                  isSelected: _selectedIndex == 4,
                  onTap: () => setState(() { _selectedIndex = 4; _selectedRole = null; }),
                ),
                _SidebarItem(
                  icon: Icons.apps_outlined,
                  label: 'All Roles',
                  isSelected: _selectedIndex == 5,
                  onTap: () => setState(() { _selectedIndex = 5; _selectedRole = null; }),
                ),
                _SidebarItem(
                  icon: Icons.storage_outlined,
                  label: 'Models',
                  shortcut: 'Ctrl+M',
                  isSelected: _selectedIndex == 6,
                  onTap: () => setState(() { _selectedIndex = 6; _selectedRole = null; }),
                ),
                _SidebarItem(
                  icon: Icons.memory_outlined,
                  label: 'Memory',
                  isSelected: _selectedIndex == 7,
                  onTap: () => setState(() { _selectedIndex = 7; _selectedRole = null; }),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  shortcut: 'Ctrl+,',
                  isSelected: _selectedIndex == 8,
                  onTap: () => setState(() { _selectedIndex = 8; _selectedRole = null; }),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.borderColor, width: 2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: c.textTertiary),
                    const SizedBox(width: 6),
                    Text(Platform.operatingSystem.toUpperCase(), style: AppTypography.labelSmall(c.textTertiary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Ctrl+N: New  Ctrl+K: Search  Ctrl+,: Settings', style: AppTypography.labelSmall(c.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          color: isSelected ? (c.isDark ? AppColors.cardDark : AppColors.cardLight) : Colors.transparent,
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? c.textPrimary : c.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.bodyMedium(isSelected ? c.textPrimary : c.textSecondary),
                ),
              ),
              if (shortcut != null)
                Text(
                  shortcut!,
                  style: AppTypography.labelSmall(c.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
          Icon(Icons.forum_outlined, size: 48, color: c.textSecondary),
          const SizedBox(height: 16),
          Text('SELECT A ROLE', style: AppTypography.headlineMedium(c.textPrimary)),
          const SizedBox(height: 8),
          Text('Choose a persona to start chatting', style: AppTypography.bodyMedium(c.textSecondary)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: installed.map((role) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onRoleSelected(role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.borderColor, width: 2),
                    ),
                    child: Text(role.name.toUpperCase(), style: AppTypography.bodyMedium(c.textPrimary)),
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
