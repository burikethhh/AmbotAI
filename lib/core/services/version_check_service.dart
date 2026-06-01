import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo {
  final String version;
  final int build;
  final String releaseDate;
  final String updateUrl;
  final String changelog;

  const VersionInfo({
    required this.version,
    required this.build,
    required this.releaseDate,
    required this.updateUrl,
    required this.changelog,
  });

  bool get isNewerThan => false; // compared externally

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String? ?? '0.0.0',
      build: json['build'] as int? ?? 0,
      releaseDate: json['releaseDate'] as String? ?? '',
      updateUrl: json['updateUrl'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
    );
  }
}

enum UpdateStatus { checking, upToDate, updateAvailable, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final VersionInfo? latest;
  final String? error;

  const UpdateCheckResult({
    required this.status,
    this.latest,
    this.error,
  });
}

class VersionCheckService {
  final String checkUrl;

  VersionCheckService({this.checkUrl = _defaultCheckUrl});

  static const _defaultCheckUrl =
      'https://ambot-ai.vercel.app/version.json';

  Future<UpdateCheckResult> check() async {
    try {
      final current = await PackageInfo.fromPlatform();
      final currentVersion = _parseVersion(current.version);
      final currentBuild = int.tryParse(current.buildNumber) ?? 0;

      final response = await http
          .get(Uri.parse(checkUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          status: UpdateStatus.error,
          error: 'Could not reach update server (HTTP ${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = VersionInfo.fromJson(data);

      final latestVersion = _parseVersion(latest.version);

      if (latestVersion == null) {
        return const UpdateCheckResult(
          status: UpdateStatus.error,
          error: 'Invalid version format from server',
        );
      }

      final isNewer = _isNewerVersion(currentVersion, currentBuild, latestVersion, latest.build);

      if (isNewer) {
        return UpdateCheckResult(
          status: UpdateStatus.updateAvailable,
          latest: latest,
        );
      }

      return const UpdateCheckResult(status: UpdateStatus.upToDate);
    } catch (e) {
      return UpdateCheckResult(
        status: UpdateStatus.error,
        error: 'Update check failed: ${e.toString().replaceFirst("Exception: ", "")}',
      );
    }
  }

  List<int>? _parseVersion(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s)).toList();
    if (parts.any((p) => p == null) || parts.length < 3) return null;
    return parts.cast<int>();
  }

  bool _isNewerVersion(
    List<int>? currentVersion,
    int currentBuild,
    List<int>? latestVersion,
    int latestBuild,
  ) {
    if (currentVersion == null || latestVersion == null) return false;
    for (var i = 0; i < 3; i++) {
      if (latestVersion[i] > currentVersion[i]) return true;
      if (latestVersion[i] < currentVersion[i]) return false;
    }
    return latestBuild > currentBuild;
  }
}
