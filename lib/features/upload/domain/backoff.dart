import 'dart:math' as math;

import '../../../core/constants.dart';

/// 指数バックオフの待機時間を計算する（DESIGN.md §7.5）。
///
/// 初回 [AppConstants.backoffInitial]（30 秒）、以後 [AppConstants.backoffMultiplier]
/// 倍（倍々）で増加し、[AppConstants.backoffMax]（1 時間）で頭打ちにする。
///
/// [retryCount] は「今回の失敗を含む累計リトライ回数」（1 以上）。
/// - retryCount=1 → 30s
/// - retryCount=2 → 60s
/// - retryCount=3 → 120s
/// - … → 最大 1h でクランプ
Duration computeBackoff(int retryCount) {
  final n = retryCount < 1 ? 1 : retryCount;
  final initialMs = AppConstants.backoffInitial.inMilliseconds;
  final maxMs = AppConstants.backoffMax.inMilliseconds;
  final factor = math.pow(AppConstants.backoffMultiplier, n - 1).toDouble();
  var ms = initialMs * factor;
  if (ms.isNaN || ms.isInfinite || ms > maxMs) {
    ms = maxMs.toDouble();
  }
  return Duration(milliseconds: ms.round());
}

/// 現在時刻から [retryCount] 回目の次回試行時刻を返す（nextRetryAt 永続化用）。
DateTime nextRetryAt(int retryCount, {DateTime? now}) {
  return (now ?? DateTime.now()).add(computeBackoff(retryCount));
}
