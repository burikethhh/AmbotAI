enum GenericStatus { notDownloaded, downloading, paused, verifying, ready, error }

abstract class DownloadableState {
  double get progress;
  String? get error;
  String? get modelId;
  bool get isReady;
  bool get isDownloading;
  bool get isPaused;
  bool get hasError;
  String get statusLabel;
}

class GenericDownloadState implements DownloadableState {
  final GenericStatus status;
  @override
  final double progress;
  @override
  final String? error;
  @override
  final String? modelId;

  const GenericDownloadState({
    this.status = GenericStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
    this.modelId,
  });

  GenericDownloadState copyWith({
    GenericStatus? status,
    double? progress,
    String? error,
    String? modelId,
  }) {
    return GenericDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      modelId: modelId ?? this.modelId,
    );
  }

  @override
  bool get isReady => status == GenericStatus.ready;

  @override
  bool get isDownloading => status == GenericStatus.downloading;

  @override
  bool get isPaused => status == GenericStatus.paused;

  @override
  bool get hasError => status == GenericStatus.error;

  @override
  String get statusLabel {
    switch (status) {
      case GenericStatus.notDownloaded:
        return 'NOT DOWNLOADED';
      case GenericStatus.downloading:
        return 'DOWNLOADING ${(progress * 100).toStringAsFixed(0)}%';
      case GenericStatus.paused:
        return 'PAUSED ${(progress * 100).toStringAsFixed(0)}%';
      case GenericStatus.verifying:
        return 'VERIFYING';
      case GenericStatus.ready:
        return 'READY';
      case GenericStatus.error:
        return 'ERROR';
    }
  }
}
