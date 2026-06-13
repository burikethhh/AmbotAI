import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/engine_selector.dart';
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

class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen> {
  int _selectedIndex = 0;
  Role? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    final engineSelection = ref.watch(engineSelectionProvider);
    final subtitle = engineSelection.when(
      data: (s) {
        switch (s.mode) {
          case EngineMode.local:
            return 'OFFLINE AI';
          case EngineMode.cloud:
            return 'CLOUD (${s.cloudProvider?.name.toUpperCase() ?? "AI"})';
          case EngineMode.mock:
            return 'DEMO';
        }
      },
      loading: () => 'LOADING...',
      error: (e, _) => 'ERROR',
    );

    return Scaffold(
      backgroundColor: c.surfaceColor,
      body: Row(
        children: [
          _buildSidebar(c, subtitle),
          Container(width: 1, color: c.borderColor),
          Expanded(child: _buildContent()),
        ],
      ),
    );
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
                Text('AMBOT AI', style: AppTypography.headlineMedium(c.textPrimary)),
                const SizedBox(height: 2),
                Text('DESKTOP  $subtitle', style: AppTypography.labelSmall(c.textTertiary)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _SidebarItem(icon: Icons.chat_outlined, label: 'General Chat', isSelected: _selectedIndex == 0, onTap: () => setState(() { _selectedIndex = 0; _selectedRole = null; })),
                _SidebarItem(icon: Icons.forum_outlined, label: 'Role Chat', isSelected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
                _SidebarItem(icon: Icons.image_outlined, label: 'Image Gen', isSelected: _selectedIndex == 2, onTap: () => setState(() { _selectedIndex = 2; _selectedRole = null; })),
                _SidebarItem(icon: Icons.description_outlined, label: 'Documents', isSelected: _selectedIndex == 3, onTap: () => setState(() { _selectedIndex = 3; _selectedRole = null; })),
                _SidebarItem(icon: Icons.code_outlined, label: 'Programmer', isSelected: _selectedIndex == 4, onTap: () => setState(() { _selectedIndex = 4; _selectedRole = null; })),
                _SidebarItem(icon: Icons.apps_outlined, label: 'All Roles', isSelected: _selectedIndex == 5, onTap: () => setState(() { _selectedIndex = 5; _selectedRole = null; })),
                _SidebarItem(icon: Icons.storage_outlined, label: 'Models', isSelected: _selectedIndex == 6, onTap: () => setState(() { _selectedIndex = 6; _selectedRole = null; })),
                _SidebarItem(icon: Icons.memory_outlined, label: 'Memory', isSelected: _selectedIndex == 7, onTap: () => setState(() { _selectedIndex = 7; _selectedRole = null; })),
                _SidebarItem(icon: Icons.settings_outlined, label: 'Settings', isSelected: _selectedIndex == 8, onTap: () => setState(() { _selectedIndex = 8; _selectedRole = null; })),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.borderColor, width: 2)),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: c.textTertiary),
                const SizedBox(width: 6),
                Text('ALL LOCAL', style: AppTypography.labelSmall(c.textTertiary)),
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
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
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
              Text(label.toUpperCase(), style: AppTypography.bodyMedium(isSelected ? c.textPrimary : c.textSecondary)),
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
          Text('SELECT A ROLE', style: AppTypography.headlineMedium(c.textPrimary)),
          const SizedBox(height: 8),
          Text('Choose a role persona to start chatting', style: AppTypography.bodyMedium(c.textSecondary)),
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
