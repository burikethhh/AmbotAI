import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

class AccessibilitySetupScreen extends StatefulWidget {
  final VoidCallback onEnabled;
  final VoidCallback onSkip;

  const AccessibilitySetupScreen({
    super.key,
    required this.onEnabled,
    required this.onSkip,
  });

  @override
  State<AccessibilitySetupScreen> createState() =>
      _AccessibilitySetupScreenState();
}

class _AccessibilitySetupScreenState extends State<AccessibilitySetupScreen>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('ambot_ai/device_control');

  bool _isEnabled = false;
  bool _checking = true;
  int _currentStep = 0;
  late AnimationController _pulseController;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      if (mounted) {
        setState(() {
          _isEnabled = result ?? false;
          _checking = false;
        });
        if (_isEnabled) {
          _pollTimer?.cancel();
          widget.onEnabled();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isEnabled = false;
          _checking = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _checkStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: widget.onSkip,
        ),
        title: Text(
          'DEVICE CONTROL SETUP',
          style: AppTypography.headlineSmall(textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Status indicator
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isEnabled
                          ? const Color(0xFF4CAF50)
                          : AppColors.silver.withValues(
                              alpha: 0.3 + _pulseController.value * 0.4,
                            ),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: _checking
                        ? SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: textSecondary,
                            ),
                          )
                        : Icon(
                            _isEnabled
                                ? Icons.check_circle
                                : Icons.shield_outlined,
                            size: 36,
                            color:
                                _isEnabled ? const Color(0xFF4CAF50) : textSecondary,
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _isEnabled ? 'ACCESSIBILITY SERVICE ACTIVE' : 'ACCESSIBILITY SERVICE REQUIRED',
              style: AppTypography.headlineSmall(textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _isEnabled
                  ? 'Device control is ready'
                  : 'Ambot needs this permission to interact with your screen and apps',
              style: AppTypography.bodyMedium(textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Steps
          if (!_isEnabled) ...[
            _StepCard(
              number: 1,
              title: 'TAP "OPEN SETTINGS" BELOW',
              description: 'This will take you to the Android Accessibility settings page.',
              isCompleted: false,
              isActive: _currentStep == 0,
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 12),
            _StepCard(
              number: 2,
              title: 'FIND "AMBOT AI" IN THE LIST',
              description: 'Scroll to find Ambot AI in your downloaded services.',
              isCompleted: false,
              isActive: _currentStep == 1,
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 12),
            _StepCard(
              number: 3,
              title: 'TOGGLE THE SWITCH ON',
              description: 'Tap the toggle, then confirm the security warning.',
              isCompleted: false,
              isActive: _currentStep == 2,
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 12),
            _StepCard(
              number: 4,
              title: 'RETURN TO AMBOT',
              description: 'Press back to return. Ambot will detect the service automatically.',
              isCompleted: false,
              isActive: _currentStep == 3,
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],

          const SizedBox(height: 32),

          // Security note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: const Color(0xFFFF9800)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The Accessibility Service only reads screen content when you actively use device control features. '
                    'No data is sent to external servers.',
                    style: AppTypography.bodySmall(textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          if (!_isEnabled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openSettings();
                  setState(() => _currentStep = 1);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('OPEN SETTINGS'),
              ),
            ),

          const SizedBox(height: 12),

          if (!_isEnabled)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onSkip,
                child: const Text('SKIP FOR NOW'),
              ),
            ),

          if (_isEnabled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onEnabled,
                child: const Text('CONTINUE'),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.isActive,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final int number;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isActive;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive
              ? (isDark ? AppColors.white : AppColors.black)
              : borderColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : (isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF4CAF50)
                    : borderColor,
                width: 1,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$number',
                      style: AppTypography.labelSmall(textSecondary),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium(textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall(textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
