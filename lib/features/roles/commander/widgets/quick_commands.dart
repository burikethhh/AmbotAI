import 'package:flutter/material.dart';

import '../../../../core/device_control/app_registry.dart';
import '../../../../core/device_control/device_controller.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class QuickCommands extends StatelessWidget {
  final bool isDark;
  final bool isNarrow;
  final bool captureReady;
  final VoidCallback onToggleCapture;
  final VoidCallback onReadScreen;
  final VoidCallback onQuickLaunch;
  final VoidCallback onEmergencyStop;
  final VoidCallback onAiAnalyze;
  final VoidCallback onGoBack;

  const QuickCommands({
    super.key,
    required this.isDark,
    required this.isNarrow,
    required this.captureReady,
    required this.onToggleCapture,
    required this.onReadScreen,
    required this.onQuickLaunch,
    required this.onEmergencyStop,
    required this.onAiAnalyze,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chipWidth = isNarrow ? 0.45 : 0.22;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: constraints.maxWidth * chipWidth,
                child: QuickChip(
                  icon: captureReady
                      ? Icons.videocam_off
                      : Icons.videocam_outlined,
                  label: captureReady ? 'Stop Capture' : 'Start Capture',
                  isDark: isDark,
                  onTap: onToggleCapture,
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * chipWidth,
                child: QuickChip(
                  icon: Icons.read_more,
                  label: 'Read Screen',
                  isDark: isDark,
                  onTap: onReadScreen,
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * chipWidth,
                child: QuickChip(
                  icon: Icons.apps,
                  label: 'Quick Launch',
                  isDark: isDark,
                  onTap: onQuickLaunch,
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * chipWidth,
                child: QuickChip(
                  icon: Icons.auto_awesome,
                  label: 'AI Analyze',
                  isDark: isDark,
                  onTap: onAiAnalyze,
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * chipWidth,
                child: QuickChip(
                  icon: Icons.arrow_back,
                  label: 'Go Back',
                  isDark: isDark,
                  onTap: onGoBack,
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * chipWidth,
                child: QuickChip(
                  icon: Icons.emergency,
                  label: 'Emergency Stop',
                  isDark: isDark,
                  danger: true,
                  onTap: onEmergencyStop,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool danger;

  const QuickChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = danger
        ? AppColors.error.withValues(alpha: 0.1)
        : (isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight);
    final textColor = danger
        ? AppColors.error
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: textColor, fontSize: 12),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppLauncherDialog extends StatefulWidget {
  final List<InstalledApp> apps;
  final bool isDark;
  final Function(InstalledApp) onLaunch;

  const AppLauncherDialog({
    super.key,
    required this.apps,
    required this.isDark,
    required this.onLaunch,
  });

  @override
  State<AppLauncherDialog> createState() => _AppLauncherDialogState();
}

class _AppLauncherDialogState extends State<AppLauncherDialog> {
  final _searchController = TextEditingController();
  List<InstalledApp> _filteredApps = [];
  List<AppEntry> _registryApps = [];

  @override
  void initState() {
    super.initState();
    _filteredApps = widget.apps;
    _registryApps = AppRegistry.entries;
    _searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = widget.apps;
      } else {
        _filteredApps = widget.apps.where((app) {
          return app.label.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  List<AppEntry> get _filteredRegistry {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _registryApps.take(20).toList();
    return _registryApps.where((entry) {
      return entry.displayName.toLowerCase().contains(query) ||
          entry.keywords.any((k) => k.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final cardColor =
        widget.isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor =
        widget.isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dialog(
      backgroundColor:
          widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('Quick Launch',
                      style: AppTypography.headlineSmall(textPrimary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search apps or type command...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: cardColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_filteredRegistry.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Popular Apps',
                        style: AppTypography.labelSmall(textSecondary)),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _filteredRegistry.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredRegistry[index];
                    return AppGridTile(
                      entry: entry,
                      isDark: widget.isDark,
                      onTap: () {
                        HapticFeedbackService.tap();
                        Navigator.pop(context);
                        widget.onLaunch(InstalledApp(
                          label: entry.displayName,
                          packageName: entry.packageName,
                        ));
                      },
                    );
                  },
                ),
              ),
              Divider(color: borderColor),
            ],
            Expanded(
              child: _filteredApps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apps_outlined,
                              size: 48,
                              color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('No apps found',
                              style: AppTypography.bodyMedium(textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: widget.isDark
                                ? AppColors.cardDarkElevated
                                : AppColors.surfaceLight,
                            child: Text(
                              app.label[0].toUpperCase(),
                              style: AppTypography.labelMedium(textPrimary),
                            ),
                          ),
                          title: Text(app.label,
                              style: AppTypography.bodyMedium(textPrimary)),
                          subtitle: Text(app.packageName,
                              style:
                                  AppTypography.labelSmall(textSecondary)),
                          trailing: Icon(Icons.open_in_new,
                              size: 18, color: textSecondary),
                          onTap: () {
                            HapticFeedbackService.tap();
                            Navigator.pop(context);
                            widget.onLaunch(app);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppGridTile extends StatelessWidget {
  final AppEntry entry;
  final bool isDark;
  final VoidCallback onTap;

  const AppGridTile({
    super.key,
    required this.entry,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final cardColor =
        isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                entry.displayName[0].toUpperCase(),
                style: AppTypography.headlineSmall(textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.displayName,
            style: AppTypography.labelSmall(textPrimary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
