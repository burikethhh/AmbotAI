import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/engine_selector.dart';
import '../../core/providers/app_providers.dart';
import '../../core/roles/role.dart';
import '../../core/services/haptic_feedback_service.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/widgets/app_icon.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_quick_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _entranceController;
  late Animation<double> _headerAnimation;
  late Animation<double> _gridAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _gridAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final roles = ref.watch(rolesProvider);
    final installed = roles.where((r) => r.isInstalled).toList();

    final engineSelection = ref.watch(engineSelectionProvider);
    final subtitle = engineSelection.when(
      data: (s) {
        switch (s.mode) {
          case EngineMode.local:
            return 'OFFLINE AI READY';
          case EngineMode.cloud:
            final name = s.cloudProvider?.name.toUpperCase() ?? 'CLOUD';
            return 'CLOUD AI ($name)';
          case EngineMode.mock:
            return 'DEMO MODE';
        }
      },
      loading: () => 'LOADING ENGINE...',
      error: (e, _) => 'ENGINE ERROR',
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, c),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              sliver: SliverToBoxAdapter(
                child: HomeAppBar(
                  animation: _headerAnimation,
                  isDark: c.isDark,
                  textPrimary: c.textPrimary,
                  textSecondary: c.textSecondary,
                  subtitle: subtitle,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onHelpTap: () => _showQuickGuide(context),
                  onSettingsTap: () => _showSettings(context),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              sliver: SliverToBoxAdapter(
                child: HomeQuickActions(
                  headerAnimation: _headerAnimation,
                  gridAnimation: _gridAnimation,
                  isDark: c.isDark,
                  textPrimary: c.textPrimary,
                  textSecondary: c.textSecondary,
                  textTertiary: c.textTertiary,
                  borderColor: c.borderColor,
                  cardColor: c.cardColor,
                  installed: installed,
                  onBrowseAll: () => _showRolesBrowser(context),
                  onRoleTap: (role) => _onRoleTap(context, role),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  void _onRoleTap(BuildContext context, Role role) {
    HapticFeedbackService.tap();
    ref.read(activeRoleProvider.notifier).state = role;
    if (role.id == 'commander') {
      context.pushNamed('commander', extra: role);
    } else {
      context.pushNamed('chat', extra: role);
    }
  }

  Widget _buildDrawer(BuildContext context, ThemeColors c) {
    return Drawer(
      backgroundColor: c.surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.borderColor, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(
                    icon: Icons.auto_awesome,
                    size: 36,
                    backgroundColor: Colors.transparent,
                    iconColor: c.textSecondary,
                    borderColor: c.borderColor,
                    borderWidth: 1.5,
                  ),
                  AppSpacing.h12,
                  Text('TOOLS', style: AppTypography.headlineMedium(c.textPrimary)),
                  AppSpacing.h4,
                  Text('Image, Document & Voice Generation',
                      style: AppTypography.bodySmall(c.textTertiary)),
                ],
              ),
            ),

            // Menu items
            _DrawerItem(
              icon: Icons.chat_outlined,
              label: 'General Chat',
              description: 'Ask Ambot AI anything',
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('generalChat');
              },
            ),
            _DrawerItem(
              icon: Icons.forum_outlined,
              label: 'Role Chat',
              description: 'Chat with AI role personas',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.image_outlined,
              label: 'Image Generation',
              description: 'Generate images from text prompts',
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('imageGen');
              },
            ),
            _DrawerItem(
              icon: Icons.description_outlined,
              label: 'Documents',
              description: 'Rich text editor with AI formatting & PDF/DOCX export',
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('documentGen');
              },
            ),
            _DrawerItem(
              icon: Icons.volume_up_outlined,
              label: 'Voice',
              description: 'Convert text to speech offline',
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('voiceGen');
              },
            ),
            _DrawerItem(
              icon: Icons.apps_outlined,
              label: 'All Roles',
              description: 'Browse & install AI role personas',
              onTap: () {
                Navigator.pop(context);
                _showRolesBrowser(context);
              },
            ),
            _DrawerItem(
              icon: Icons.storage_outlined,
              label: 'Models',
              description: 'Download & manage AI models',
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('models');
              },
            ),

            const Spacer(),

            // Footer
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.borderColor, width: 2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_outlined, size: 12, color: c.textTertiary),
                  const SizedBox(width: 6),
                  Text('ALL LOCAL · OFFLINE',
                      style: AppTypography.labelSmall(c.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickGuide(BuildContext context) {
    HapticFeedbackService.tap();
    context.pushNamed('quickGuide');
  }

  void _showSettings(BuildContext context) {
    HapticFeedbackService.tap();
    context.pushNamed('settings');
  }

  void _showRolesBrowser(BuildContext context) {
    HapticFeedbackService.tap();
    context.pushNamed('roles');
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: AppTypography.bodyMedium(c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: AppTypography.bodySmall(c.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
