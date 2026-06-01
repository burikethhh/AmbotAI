import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/ai/downloadable_model.dart';

void main() {
  group('GenericDownloadState', () {
    test('initial state has notDownloaded status and zero progress', () {
      const state = GenericDownloadState();
      expect(state.status, GenericStatus.notDownloaded);
      expect(state.progress, 0.0);
      expect(state.error, isNull);
      expect(state.modelId, isNull);
    });

    test('copyWith updates status', () {
      const state = GenericDownloadState();
      final updated = state.copyWith(status: GenericStatus.downloading);
      expect(updated.status, GenericStatus.downloading);
      expect(updated.progress, 0.0);
    });

    test('copyWith updates progress', () {
      const state = GenericDownloadState();
      final updated = state.copyWith(progress: 0.5);
      expect(updated.status, GenericStatus.notDownloaded);
      expect(updated.progress, 0.5);
    });

    test('copyWith updates error', () {
      const state = GenericDownloadState();
      final updated = state.copyWith(error: 'something went wrong');
      expect(updated.error, 'something went wrong');
      expect(updated.status, GenericStatus.notDownloaded);
    });

    test('copyWith updates modelId', () {
      const state = GenericDownloadState();
      final updated = state.copyWith(modelId: 'model-123');
      expect(updated.modelId, 'model-123');
    });

    test('copyWith with no arguments returns equal state', () {
      const state = GenericDownloadState(status: GenericStatus.ready, progress: 1.0);
      final updated = state.copyWith();
      expect(updated.status, GenericStatus.ready);
      expect(updated.progress, 1.0);
    });

    group('isReady getter', () {
      test('returns true when status is ready', () {
        const state = GenericDownloadState(status: GenericStatus.ready);
        expect(state.isReady, isTrue);
      });

      test('returns false for other statuses', () {
        expect(
          const GenericDownloadState(status: GenericStatus.notDownloaded).isReady,
          isFalse,
        );
        expect(
          const GenericDownloadState(status: GenericStatus.downloading).isReady,
          isFalse,
        );
        expect(
          const GenericDownloadState(status: GenericStatus.paused).isReady,
          isFalse,
        );
        expect(
          const GenericDownloadState(status: GenericStatus.verifying).isReady,
          isFalse,
        );
        expect(
          const GenericDownloadState(status: GenericStatus.error).isReady,
          isFalse,
        );
      });
    });

    group('isDownloading getter', () {
      test('returns true when status is downloading', () {
        const state = GenericDownloadState(status: GenericStatus.downloading);
        expect(state.isDownloading, isTrue);
      });

      test('returns false for other statuses', () {
        expect(
          const GenericDownloadState(status: GenericStatus.ready).isDownloading,
          isFalse,
        );
        expect(
          const GenericDownloadState(status: GenericStatus.paused).isDownloading,
          isFalse,
        );
      });
    });

    group('isPaused getter', () {
      test('returns true when status is paused', () {
        const state = GenericDownloadState(status: GenericStatus.paused);
        expect(state.isPaused, isTrue);
      });

      test('returns false for other statuses', () {
        expect(
          const GenericDownloadState(status: GenericStatus.downloading).isPaused,
          isFalse,
        );
        expect(const GenericDownloadState(status: GenericStatus.ready).isPaused, isFalse);
      });
    });

    group('hasError getter', () {
      test('returns true when status is error', () {
        const state = GenericDownloadState(status: GenericStatus.error);
        expect(state.hasError, isTrue);
      });

      test('returns false for other statuses', () {
        expect(
          const GenericDownloadState(status: GenericStatus.ready).hasError,
          isFalse,
        );
        expect(
          const GenericDownloadState(status: GenericStatus.downloading).hasError,
          isFalse,
        );
      });
    });

    group('statusLabel', () {
      test('returns NOT DOWNLOADED for notDownloaded status', () {
        const state = GenericDownloadState(status: GenericStatus.notDownloaded);
        expect(state.statusLabel, 'NOT DOWNLOADED');
      });

      test('includes progress percentage for downloading status', () {
        const state = GenericDownloadState(
          status: GenericStatus.downloading,
          progress: 0.456,
        );
        expect(state.statusLabel, 'DOWNLOADING 46%');
      });

      test('includes progress percentage for paused status', () {
        const state = GenericDownloadState(
          status: GenericStatus.paused,
          progress: 0.7,
        );
        expect(state.statusLabel, 'PAUSED 70%');
      });

      test('returns VERIFYING for verifying status', () {
        const state = GenericDownloadState(status: GenericStatus.verifying);
        expect(state.statusLabel, 'VERIFYING');
      });

      test('returns READY for ready status', () {
        const state = GenericDownloadState(status: GenericStatus.ready);
        expect(state.statusLabel, 'READY');
      });

      test('returns ERROR for error status', () {
        const state = GenericDownloadState(status: GenericStatus.error);
        expect(state.statusLabel, 'ERROR');
      });
    });
  });
}
