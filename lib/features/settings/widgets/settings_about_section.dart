import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/version_check_service.dart';
import '../../../shared/theme/app_typography.dart';
import 'settings_tile.dart';

class SettingsAboutSection extends StatefulWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color cardColor;

  const SettingsAboutSection({
    super.key,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.cardColor,
  });

  @override
  State<SettingsAboutSection> createState() => _SettingsAboutSectionState();
}

class _SettingsAboutSectionState extends State<SettingsAboutSection> {
  String _appVersion = '...';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);

    final service = VersionCheckService();
    final result = await service.check();

    if (!mounted) return;
    setState(() => _checking = false);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _UpdateDialog(
        isDark: widget.isDark,
        textPrimary: widget.textPrimary,
        textSecondary: widget.textSecondary,
        borderColor: widget.borderColor,
        cardColor: widget.cardColor,
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: widget.borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsInfoRow(
            label: 'VERSION',
            value: _appVersion,
            labelColor: widget.textSecondary,
            valueColor: widget.textPrimary,
          ),
          const SizedBox(height: 8),
          SettingsInfoRow(
            label: 'BUILD',
            value: 'PHASE 2 - AI ENGINE',
            labelColor: widget.textSecondary,
            valueColor: widget.textPrimary,
          ),
          const SizedBox(height: 8),
          SettingsInfoRow(
            label: 'DEVELOPER',
            value: 'Christian Keth Aguacito',
            labelColor: widget.textSecondary,
            valueColor: widget.textPrimary,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIcon(
                svg: _fbSvg,
                url: 'https://www.facebook.com/christiankethzink',
                isDark: widget.isDark,
                borderColor: widget.borderColor,
              ),
              const SizedBox(width: 16),
              _SocialIcon(
                svg: _igSvg,
                url: 'https://www.instagram.com/beeersachiiii/',
                isDark: widget.isDark,
                borderColor: widget.borderColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pushNamed('about'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.borderColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'ABOUT AMBOT AI',
                style: AppTypography.labelLarge(widget.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _checking ? null : _checkForUpdates,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.borderColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _checking
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.textSecondary,
                      ),
                    )
                  : Text(
                      'CHECK FOR UPDATES',
                      style: AppTypography.labelLarge(widget.textPrimary),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateDialog extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color cardColor;
  final UpdateCheckResult result;

  const _UpdateDialog({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.cardColor,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (result.status) {
                UpdateStatus.upToDate => 'UP TO DATE',
                UpdateStatus.updateAvailable => 'UPDATE AVAILABLE',
                UpdateStatus.error => 'CHECK FAILED',
                UpdateStatus.checking => 'CHECKING...',
              },
              style: AppTypography.headlineMedium(textPrimary),
            ),
            const SizedBox(height: 16),
            ..._body(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final isUpdate = result.status == UpdateStatus.updateAvailable && result.latest != null;
                  if (isUpdate && result.latest!.updateUrl.isNotEmpty) {
                    await launchUrl(Uri.parse(result.latest!.updateUrl), mode: LaunchMode.externalApplication);
                  }
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  result.status == UpdateStatus.updateAvailable && result.latest != null
                      ? 'DOWNLOAD'
                      : 'CLOSE',
                  style: AppTypography.labelLarge(textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (result.status) {
      case UpdateStatus.upToDate:
        return [
          Text(
            'You\'re running the latest version.',
            style: AppTypography.bodyMedium(textSecondary),
          ),
        ];
      case UpdateStatus.updateAvailable:
        final latest = result.latest!;
        return [
          Text(
            'Version ${latest.version} is now available!',
            style: AppTypography.labelLarge(textPrimary),
          ),
          if (latest.releaseDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Released: ${latest.releaseDate}',
              style: AppTypography.bodySmall(textSecondary),
            ),
          ],
          if (latest.changelog.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'What\'s new:',
              style: AppTypography.labelMedium(textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              latest.changelog,
              style: AppTypography.bodySmall(textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Current version: $_appVersion',
            style: AppTypography.bodySmall(textSecondary),
          ),
        ];
      case UpdateStatus.error:
        return [
          Text(
            result.error ?? 'An unknown error occurred.',
            style: AppTypography.bodyMedium(textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your internet connection and try again.',
            style: AppTypography.bodySmall(textSecondary),
          ),
        ];
      case UpdateStatus.checking:
        return [];
    }
  }

  String get _appVersion => '...';
}

class _SocialIcon extends StatelessWidget {
  final String svg;
  final String url;
  final bool isDark;
  final Color borderColor;

  const _SocialIcon({
    required this.svg,
    required this.url,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async => await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SvgPicture.string(
            svg,
            colorFilter: ColorFilter.mode(
              isDark ? const Color(0xFFF0F0F0) : const Color(0xFF0A0A0A),
              BlendMode.srcIn,
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

const _fbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.879v-6.988h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.989C18.343 21.129 22 16.99 22 12z"/>
</svg>
''';

const _igSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
</svg>
''';
