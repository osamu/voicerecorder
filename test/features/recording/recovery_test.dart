import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/features/recording/domain/recovery.dart';

void main() {
  group('Recovery.isUnclosedMs', () {
    test('durationMs==0 は未クローズ', () {
      expect(Recovery.isUnclosedMs(0), isTrue);
    });
    test('durationMs>0 はクローズ済み', () {
      expect(Recovery.isUnclosedMs(1), isFalse);
      expect(Recovery.isUnclosedMs(60000), isFalse);
    });
  });

  group('Recovery.estimateDurationMs', () {
    test('32kbps 基準でサイズから概算', () {
      // 32kbps = 4000 bytes/sec。4000 bytes → 約1000ms。
      expect(Recovery.estimateDurationMs(4000), 1000);
      expect(Recovery.estimateDurationMs(40000), 10000);
    });
    test('0 以下は 0', () {
      expect(Recovery.estimateDurationMs(0), 0);
      expect(Recovery.estimateDurationMs(-5), 0);
    });
  });

  group('Recovery.assessRaw', () {
    test('クローズ済み(duration>0)は none', () {
      final a = Recovery.assessRaw(
        durationMs: 5000,
        localPath: '/x/a.m4a',
        fileExists: true,
        fileSizeBytes: 20000,
      );
      expect(a.action, RecoveryAction.none);
    });

    test('未クローズ＋実ファイルあり → finalizeFromFile（推定長・サイズ確定）', () {
      final a = Recovery.assessRaw(
        durationMs: 0,
        localPath: '/x/a.m4a',
        fileExists: true,
        fileSizeBytes: 40000,
      );
      expect(a.action, RecoveryAction.finalizeFromFile);
      expect(a.sizeBytes, 40000);
      expect(a.estimatedDurationMs, 10000);
    });

    test('未クローズだが localPath 無し → markMissing', () {
      final a = Recovery.assessRaw(
        durationMs: 0,
        localPath: null,
        fileExists: false,
        fileSizeBytes: 0,
      );
      expect(a.action, RecoveryAction.markMissing);
    });

    test('未クローズだがファイル実体無し → markMissing', () {
      final a = Recovery.assessRaw(
        durationMs: 0,
        localPath: '/x/gone.m4a',
        fileExists: false,
        fileSizeBytes: 0,
      );
      expect(a.action, RecoveryAction.markMissing);
    });

    test('未クローズ・ファイルはあるがサイズ0 → markMissing', () {
      final a = Recovery.assessRaw(
        durationMs: 0,
        localPath: '/x/empty.m4a',
        fileExists: true,
        fileSizeBytes: 0,
      );
      expect(a.action, RecoveryAction.markMissing);
    });
  });
}
