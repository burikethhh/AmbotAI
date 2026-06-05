import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ModelDownloader {
  HttpClient? _httpClient;
  bool _cancelRequested = false;
  final bool _throwOnCancel;

  ModelDownloader({bool throwOnCancel = false}) : _throwOnCancel = throwOnCancel;

  bool get isCancelRequested => _cancelRequested;

  void cancelDownload() {
    _cancelRequested = true;
    _httpClient?.close(force: true);
  }

  static Future<HttpClientResponse> sendRequest(
    HttpClient client,
    Uri url, {
    String? hfToken,
    int? rangeStart,
    String? userAgent,
  }) async {
    final request = await client.getUrl(url);
    if (userAgent != null && userAgent.isNotEmpty) {
      request.headers.set('User-Agent', userAgent);
    }
    if (hfToken != null && hfToken.isNotEmpty) {
      request.headers.set('Authorization', 'Bearer $hfToken');
    }
    if (rangeStart != null && rangeStart > 0) {
      request.headers.set('Range', 'bytes=$rangeStart-');
    }
    request.followRedirects = false;
    return request.close();
  }

  Future<String?> downloadModel({
    required String url,
    required String fileName,
    required String destinationDir,
    required int sizeMB,
    String? hfToken,
    String? userAgent,
    void Function(double progress)? onProgress,
    void Function()? onVerifying,
  }) async {
    _cancelRequested = false;

    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('MODEL_DL: wakelock enable failed: $e');
    }

    try {
      final dir = Directory(destinationDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      final tempPath = '$filePath.tmp';
      final tempFile = File(tempPath);

      int existingBytes = 0;
      if (await tempFile.exists()) {
        existingBytes = await tempFile.length();
      }

      if (existingBytes > 0) {
        final totalEstimate = sizeMB * 1024 * 1024;
        final resumeProgress = totalEstimate > 0
            ? (existingBytes / totalEstimate).clamp(0.0, 0.99)
            : 0.0;
        onProgress?.call(resumeProgress);
      }

      _httpClient = HttpClient();
      _httpClient!.connectionTimeout = const Duration(seconds: 30);
      _httpClient!.idleTimeout = const Duration(minutes: 5);
      _httpClient!.autoUncompress = false;

      HttpClientResponse response = await sendRequest(
        _httpClient!,
        Uri.parse(url),
        hfToken: hfToken,
        rangeStart: existingBytes > 0 ? existingBytes : null,
        userAgent: userAgent,
      );

      int redirectCount = 0;
      while ((response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 303 ||
              response.statusCode == 307) &&
          redirectCount < 5) {
        final location = response.headers.value('location');
        if (location == null) break;
        await response.drain<void>();
        _httpClient!.close();
        _httpClient = HttpClient();
        _httpClient!.autoUncompress = false;
        response = await sendRequest(
          _httpClient!,
          Uri.parse(location),
          rangeStart: existingBytes > 0 ? existingBytes : null,
          userAgent: userAgent,
        );
        redirectCount++;
      }

      if (response.statusCode != 200 && response.statusCode != 206) {
        await response.drain<void>();
        throw Exception(
          'Download failed (HTTP ${response.statusCode})',
        );
      }

      final totalBytes = (response.contentLength > 0)
          ? response.contentLength + existingBytes
          : sizeMB * 1024 * 1024;

      final sink = tempFile.openWrite(mode: FileMode.append);
      int received = existingBytes;

      try {
        await for (final chunk in response) {
          if (_cancelRequested) {
            await sink.close();
            if (_throwOnCancel) {
              throw Exception('Download cancelled');
            }
            return null;
          }

          sink.add(chunk);
          received += chunk.length;

          final progress = totalBytes > 0 ? received / totalBytes : 0.0;
          onProgress?.call(progress.clamp(0.0, 1.0));
        }

        await sink.flush();
        await sink.close();

        onVerifying?.call();

        if (await file.exists()) {
          await file.delete();
        }
        await tempFile.rename(filePath);

        return filePath;
      } catch (_) {
        await sink.close();
        rethrow;
      }
    } catch (_) {
      rethrow;
    } finally {
      _httpClient?.close();
      _httpClient = null;
      try {
        await WakelockPlus.disable();
      } catch (e) {
        debugPrint('MODEL_DL: wakelock disable failed: $e');
      }
    }
  }
}
