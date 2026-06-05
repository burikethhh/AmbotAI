import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/ambot_avatar.dart';
import '../../shared/widgets/app_icon.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ABOUT',
          style: AppTypography.headlineMedium(c.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App Icon + Name
          Center(
            child: AmbotAvatar(size: 80, isDark: c.isDark),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'AMBOT AI',
              style: AppTypography.displayLarge(c.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'v1.0.0 \u00B7 PHASE 2 - AI ENGINE',
              style: AppTypography.labelMedium(c.textTertiary),
            ),
          ),

          const SizedBox(height: 32),

          // Introduction
          _Section(
            title: 'INTRODUCTION',
            c: c,
          ),
          const SizedBox(height: 12),
          Text(
            'Ambot AI is an offline-first education platform that runs entirely on your device. '
            'No internet required. No data leaves your phone. No subscriptions.',
            style: AppTypography.bodyMedium(c.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Built around modular AI roles \u2014 each one a specialized assistant for a specific domain. '
            'Install only what you need. Tutor, QuizMaker, DebatePartner, and more.',
            style: AppTypography.bodyMedium(c.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Ambot combines local AI inference with a rich set of productivity tools: '
            'document generation, image creation, voice synthesis, and device control \u2014 '
            'all working together in a seamless, privacy-first experience.',
            style: AppTypography.bodyMedium(c.textSecondary),
          ),

          const SizedBox(height: 32),

          // Features
          _Section(
            title: 'KEY FEATURES',
            c: c,
          ),
          const SizedBox(height: 12),
          _FeatureItem(
            icon: Icons.lock_outlined,
            label: 'FULLY OFFLINE',
            description: 'AI runs on your device. Your data never leaves your phone.',
            c: c,
          ),
          _FeatureItem(
            icon: Icons.apps_outlined,
            label: 'MODULAR ROLES',
            description: 'Install specialized AI assistants for any subject or task.',
            c: c,
          ),
          _FeatureItem(
            icon: Icons.chat_outlined,
            label: 'INTELLIGENT CHAT',
            description: 'Context-aware conversations with persistent memory.',
            c: c,
          ),
          _FeatureItem(
            icon: Icons.description_outlined,
            label: 'DOCUMENT GENERATION',
            description: 'Rich text editor with AI formatting and PDF/DOCX export.',
            c: c,
          ),
          _FeatureItem(
            icon: Icons.image_outlined,
            label: 'IMAGE GENERATION',
            description: 'Create images from text prompts using local or cloud AI.',
            c: c,
          ),
          _FeatureItem(
            icon: Icons.volume_up_outlined,
            label: 'VOICE SYNTHESIS',
            description: 'Offline text-to-speech with AI-enhanced punctuation.',
            c: c,
          ),
          _FeatureItem(
            icon: Icons.computer_outlined,
            label: 'DEVICE CONTROL',
            description: 'Agent Driven Environment — AI controls your device safely.',
            c: c,
          ),

          const SizedBox(height: 32),

          // Privacy
          _Section(
            title: 'PRIVACY',
            c: c,
          ),
          const SizedBox(height: 12),
          Text(
            'Ambot AI is designed with privacy as a core principle. '
            'All AI inference happens locally on your device. '
            'Conversations, memories, and generated content are stored locally '
            'and never transmitted to external servers unless you explicitly '
            'enable cloud mode with your own API keys.',
            style: AppTypography.bodyMedium(c.textSecondary),
          ),

          const SizedBox(height: 32),

          // Developer
          _Section(
            title: 'DEVELOPER',
            c: c,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.cardColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c.borderColor, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(
                      icon: Icons.person_outlined,
                      size: 40,
                      backgroundColor: c.isDark
                          ? AppColors.cardDarkElevated
                          : AppColors.surfaceLight,
                      iconColor: c.textSecondary,
                      borderColor: c.borderColor,
                      borderWidth: 1.5,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHRISTIAN KETH AGUACITO',
                            style: AppTypography.headlineSmall(c.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lead Developer',
                            style: AppTypography.labelMedium(c.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Tech stack
          _Section(
            title: 'BUILT WITH',
            c: c,
          ),
          const SizedBox(height: 12),
          _TechBadge(label: 'FLUTTER', c: c),
          const SizedBox(height: 8),
          _TechBadge(label: 'DART', c: c),
          const SizedBox(height: 8),
          _TechBadge(label: 'RIVERPOD', c: c),
          const SizedBox(height: 8),
          _TechBadge(label: 'GO ROUTER', c: c),
          const SizedBox(height: 8),
          _TechBadge(label: 'HIVE', c: c),
          const SizedBox(height: 8),
          _TechBadge(label: 'LLAMADART', c: c),

          const SizedBox(height: 40),

          // Footer
          Center(
            child: Text(
              'Made with care for students and educators worldwide.',
              style: AppTypography.bodySmall(c.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '\u00A9 2025 Christian Keth Aguacito. All rights reserved.',
              style: AppTypography.labelSmall(c.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final ThemeColors c;

  const _Section({required this.title, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge(c.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          color: c.borderColor,
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final ThemeColors c;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium(c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall(c.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechBadge extends StatelessWidget {
  final String label;
  final ThemeColors c;

  const _TechBadge({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: c.borderColor, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(c.textSecondary),
      ),
    );
  }
}
