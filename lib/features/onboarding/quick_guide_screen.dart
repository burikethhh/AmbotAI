import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/hex_dot.dart';

class QuickGuideScreen extends ConsumerStatefulWidget {
  const QuickGuideScreen({super.key});

  @override
  ConsumerState<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends ConsumerState<QuickGuideScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _steps = [
    _GuideStep(
      icon: Icons.school_outlined,
      title: 'ROLES',
      body:
          'Ambot is built around Roles — each one is a specialized AI assistant.\n\n'
          'Tutor explains concepts. QuizCraft generates tests. Commander controls your device.\n\n'
          'Install only the roles you need. Browse more anytime.',
    ),
    _GuideStep(
      icon: Icons.chat_outlined,
      title: 'CHAT',
      body:
          'Every role has its own chat. Conversations are saved locally.\n\n'
          'Persistent memory lets Ambot remember your name, goals, and preferences across sessions.\n\n'
          'You can view, pin, or delete memories in Settings > Memory.',
    ),
    _GuideStep(
      icon: Icons.computer_outlined,
      title: 'DEVICE CONTROL',
      body:
          'Commander role lets Ambot control your device.\n\n'
          'Open apps, send messages, toggle settings, read your screen — all with AI assistance.\n\n'
          'Three modes: Ask (confirm every action), Autopilot (safe actions auto-run), Ambot Decides (AI uses trust score).',
    ),
    _GuideStep(
      icon: Icons.mic_outlined,
      title: 'VOICE',
      body:
          'Tap the mic button in Commander to speak commands.\n\n'
          '"Open WhatsApp" — "Set a timer for 10 minutes" — "Turn on WiFi"\n\n'
          'Works offline on Android 12+. Ambot speaks responses back to you.',
    ),
    _GuideStep(
      icon: Icons.shield_outlined,
      title: 'PRIVACY',
      body:
          'Everything runs on your device. No data leaves your phone.\n\n'
          'AI inference is local. Memory is stored locally. Screen capture never transmits.\n\n'
          'You control what Ambot remembers. Wipe anytime.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QUICK GUIDE',
          style: AppTypography.headlineSmall(c.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentPage == _steps.length - 1 ? 'DONE' : 'SKIP',
              style: AppTypography.labelLarge(c.textTertiary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(color: c.borderColor, thickness: 2, height: 2),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(
                        icon: step.icon,
                        size: 72,
                        backgroundColor: c.isDark
                            ? AppColors.cardDarkElevated
                            : AppColors.surfaceLight,
                        iconColor: c.isDark
                            ? AppColors.silver
                            : AppColors.grey,
                        borderColor: c.borderColor,
                        borderWidth: 2,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        step.title,
                        style: AppTypography.displayMedium(c.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step.body,
                        style: AppTypography.bodyLarge(c.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Dots
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) {
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
          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  _currentPage == _steps.length - 1 ? 'GOT IT' : 'NEXT',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String body;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.body,
  });
}
