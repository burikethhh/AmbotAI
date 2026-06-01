import 'package:flutter/material.dart';
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
                onPressed: () {
                  final isUpdate = result.status == UpdateStatus.updateAvailable && result.latest != null;
                  if (isUpdate && result.latest!.updateUrl.isNotEmpty) {
                    launchUrl(Uri.parse(result.latest!.updateUrl), mode: LaunchMode.externalApplication);
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
