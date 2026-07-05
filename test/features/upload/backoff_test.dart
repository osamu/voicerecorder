import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/features/upload/domain/backoff.dart';

void main() {
  group('computeBackoff（指数バックオフ・§7.5）', () {
    test('初回は 30 秒', () {
      expect(computeBackoff(1), const Duration(seconds: 30));
    });

    test('倍々で増加する', () {
      expect(computeBackoff(2), const Duration(seconds: 60));
      expect(computeBackoff(3), const Duration(seconds: 120));
      expect(computeBackoff(4), const Duration(seconds: 240));
    });

    test('最大 1 時間でクランプ', () {
      // 30 * 2^9 = 15360s > 3600s → 1h に頭打ち。
      expect(computeBackoff(10), const Duration(hours: 1));
      expect(computeBackoff(100), const Duration(hours: 1));
    });

    test('retryCount<1 は 1 として扱う', () {
      expect(computeBackoff(0), const Duration(seconds: 30));
      expect(computeBackoff(-5), const Duration(seconds: 30));
    });

    test('nextRetryAt は現在時刻＋バックオフ', () {
      final now = DateTime(2026, 7, 4, 12, 0, 0);
      expect(nextRetryAt(1, now: now), DateTime(2026, 7, 4, 12, 0, 30));
      expect(nextRetryAt(2, now: now), DateTime(2026, 7, 4, 12, 1, 0));
    });
  });
}
