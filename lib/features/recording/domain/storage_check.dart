import '../../../core/constants.dart';

/// 録音開始時の空き容量判定結果（§6.2）。
enum StorageStartDecision {
  /// 十分な空きがある。通常開始。
  ok,

  /// 閾値（既定 200MB）未満。警告付きで開始は許可する。
  warn,
}

/// 録音中の定期チェックによる判定結果（§6.2）。
enum StorageRuntimeAction {
  /// 継続。
  keepGoing,

  /// 閾値割れ。ユーザーへ警告表示（録音は継続）。
  warn,

  /// 枯渇寸前。安全クローズ（それまでの録音を確定保存）する。
  safeClose,
}

/// 空き容量に基づく録音可否・継続可否の純粋判定（§6.2）。
///
/// 判定ロジックのみを持ち、実際のディスク問い合わせ（`空きバイト数`の取得）は
/// 呼び出し側が行う。これによりプラットフォーム非依存で単体テスト可能にする。
///
/// 閾値:
/// - 開始/警告閾値: [AppConstants.minFreeSpaceToStartBytes]（200MB）
/// - 安全クローズ閾値: [criticalFreeSpaceBytes]（既定 50MB）。定数集に無いため
///   本クラスのローカル定数として定義する（DESIGN §6.2「枯渇寸前で安全クローズ」）。
abstract final class StorageCheck {
  /// 枯渇寸前とみなす空き容量。これを下回ったら安全クローズする。50MB。
  static const int criticalFreeSpaceBytes = 50 * 1024 * 1024;

  /// 開始時判定。
  ///
  /// [freeBytes] が [AppConstants.minFreeSpaceToStartBytes] 未満なら
  /// [StorageStartDecision.warn]、以上なら [StorageStartDecision.ok]。
  static StorageStartDecision assessStart(int freeBytes) {
    return freeBytes < AppConstants.minFreeSpaceToStartBytes
        ? StorageStartDecision.warn
        : StorageStartDecision.ok;
  }

  /// 録音中の定期チェック判定。
  ///
  /// - [freeBytes] が [criticalFreeSpaceBytes] 未満 → [StorageRuntimeAction.safeClose]
  /// - [AppConstants.minFreeSpaceToStartBytes] 未満 → [StorageRuntimeAction.warn]
  /// - それ以外 → [StorageRuntimeAction.keepGoing]
  ///
  /// [criticalOverride] を渡すと安全クローズ閾値を差し替えられる（テスト用）。
  static StorageRuntimeAction assessRuntime(
    int freeBytes, {
    int? criticalOverride,
  }) {
    final critical = criticalOverride ?? criticalFreeSpaceBytes;
    if (freeBytes < critical) {
      return StorageRuntimeAction.safeClose;
    }
    if (freeBytes < AppConstants.minFreeSpaceToStartBytes) {
      return StorageRuntimeAction.warn;
    }
    return StorageRuntimeAction.keepGoing;
  }
}
