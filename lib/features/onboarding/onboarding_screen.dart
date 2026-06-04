import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/ambot_avatar.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/hex_dot.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      icon: null,
      useAvatar: true,
      title: 'AMBOT AI',
      subtitle: 'Your offline AI classroom.\nNo internet. No subscriptions. No limits.',
    ),
    _PageData(
      icon: Icons.tune_outlined,
      useAvatar: false,
      title: 'MODULAR ROLES',
      subtitle: 'Tutor. Quiz Maker. Debate Partner.\nInstall only what you need.',
    ),
    _PageData(
      icon: Icons.lock_outlined,
      useAvatar: false,
      title: 'PRIVATE BY DESIGN',
      subtitle: 'Everything runs on your device.\nYour data never leaves your phone.',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(onboardingCompleteProvider.notifier).complete();
    context.go('/ai-setup');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'SKIP',
                    style: AppTypography.labelLarge(c.textTertiary),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (page.useAvatar)
                          AmbotAvatar(size: 96, isDark: c.isDark)
                        else
                          AppIcon(
                            icon: page.icon ?? Icons.auto_awesome,
                            size: 72,
                            backgroundColor: c.isDark
                                ? AppColors.cardDarkElevated
                                : AppColors.surfaceLight,
                            iconColor: c.isDark
                                ? AppColors.silver
                                : AppColors.grey,
                            borderColor: c.isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderWidth: 2,
                          ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: AppTypography.displayMedium(c.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: AppTypography.bodyLarge(c.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Hex dots
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: HexDot(
                    size: isActive ? 12 : 8,
                    color: isActive ? c.textPrimary : c.textTertiary,
                  ),
                  );
                }),
              ),
            ),
            // Full-width brutalist button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'GET STARTED'
                        : 'NEXT',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final IconData? icon;
  final bool useAvatar;
  final String title;
  final String subtitle;

  const _PageData({
    this.icon,
    this.useAvatar = false,
    required this.title,
    required this.subtitle,
  });
}
