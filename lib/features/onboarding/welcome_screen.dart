import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/ambot_avatar.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  UserType _selectedType = UserType.student;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _continue() {
    ref.read(userTypeProvider.notifier).state = _selectedType;
    ref.read(onboardingCompleteProvider.notifier).complete();
    context.go('/ai-setup');
  }

  void _showQuickGuide() {
    context.pushNamed('quickGuide');
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Top bar with quick guide
              Align(
                alignment: Alignment.topRight,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton.icon(
                    onPressed: _showQuickGuide,
                    icon: Icon(Icons.help_outline, size: 18, color: c.textSecondary),
                    label: Text(
                      'QUICK GUIDE',
                      style: AppTypography.labelLarge(c.textSecondary),
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated avatar
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: AmbotAvatar(size: 100, isDark: c.isDark),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          'AMBOT AI',
                          style: AppTypography.displayLarge(c.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          '"I don\'t know? Now you will."',
                          style: AppTypography.bodyLarge(c.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          'Offline AI. Modular roles. Zero subscriptions.',
                          style: AppTypography.labelMedium(c.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // User type selection
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I AM A',
                              style: AppTypography.labelSmall(c.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _UserTypeButton(
                                    label: 'STUDENT',
                                    icon: Icons.school_outlined,
                                    isSelected: _selectedType == UserType.student,
                                    isDark: c.isDark,
                                    borderColor: c.borderColor,
                                    cardColor: c.cardColor,
                                    onTap: () => setState(
                                      () => _selectedType = UserType.student,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _UserTypeButton(
                                    label: 'TEACHER',
                                    icon: Icons.menu_book_outlined,
                                    isSelected: _selectedType == UserType.teacher,
                                    isDark: c.isDark,
                                    borderColor: c.borderColor,
                                    cardColor: c.cardColor,
                                    onTap: () => setState(
                                      () => _selectedType = UserType.teacher,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _UserTypeButton(
                                  label: 'BOTH',
                                  icon: Icons.people_outline,
                                  isSelected: _selectedType == UserType.both,
                                  isDark: c.isDark,
                                  borderColor: c.borderColor,
                                  cardColor: c.cardColor,
                                onTap: () => setState(
                                  () => _selectedType = UserType.both,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom CTA
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _continue,
                            child: const Text('CONTINUE'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Developed by Christian Keth Aguacito',
                          style: AppTypography.labelSmall(c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeButton extends StatelessWidget {
  const _UserTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.borderColor,
    required this.cardColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final Color borderColor;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.white.withValues(alpha: 0.1) : AppColors.black.withValues(alpha: 0.05))
              : cardColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? textPrimary : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? textPrimary : textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge(
                isSelected ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
