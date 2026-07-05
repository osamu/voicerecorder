import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/constants.dart';
import 'package:voicerecorder/features/recording/domain/storage_check.dart';

void main() {
  const mb = 1024 * 1024;

  group('StorageCheck.assessStart', () {
    test('200MB 以上は ok', () {
      expect(
        StorageCheck.assessStart(AppConstants.minFreeSpaceToStartBytes),
        StorageStartDecision.ok,
      );
      expect(StorageCheck.assessStart(500 * mb), StorageStartDecision.ok);
    });

    test('200MB 未満は warn', () {
      expect(
        StorageCheck.assessStart(AppConstants.minFreeSpaceToStartBytes - 1),
        StorageStartDecision.warn,
      );
      expect(StorageCheck.assessStart(100 * mb), StorageStartDecision.warn);
    });
  });

  group('StorageCheck.assessRuntime', () {
    test('十分な空きは keepGoing', () {
      expect(StorageCheck.assessRuntime(500 * mb),
          StorageRuntimeAction.keepGoing);
    });

    test('警告閾値未満だが致命的ではない → warn', () {
      expect(StorageCheck.assessRuntime(100 * mb), StorageRuntimeAction.warn);
    });

    test('致命的閾値(50MB)未満 → safeClose', () {
      expect(
        StorageCheck.assessRuntime(StorageCheck.criticalFreeSpaceBytes - 1),
        StorageRuntimeAction.safeClose,
      );
      expect(StorageCheck.assessRuntime(10 * mb),
          StorageRuntimeAction.safeClose);
    });

    test('境界: ちょうど致命的閾値は safeClose ではない', () {
      expect(
        StorageCheck.assessRuntime(StorageCheck.criticalFreeSpaceBytes),
        StorageRuntimeAction.warn,
      );
    });

    test('criticalOverride で閾値差し替え', () {
      expect(
        StorageCheck.assessRuntime(80 * mb, criticalOverride: 100 * mb),
        StorageRuntimeAction.safeClose,
      );
    });
  });
}
