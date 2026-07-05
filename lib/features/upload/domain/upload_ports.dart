/// アップロードキューが外部インフラへ依存するための抽象ポート群（DESIGN.md §7）。
///
/// ドメイン層を Flutter / プラグイン非依存（plain Dart）に保つために、
/// 通知・空き容量取得などプラットフォーム依存の操作は本ファイルの
/// 抽象インターフェース越しに扱う。具体実装は `infra/` 配下（Flutter プラグイン可）。
library;

/// 24 時間以上滞留したキューをユーザーへ知らせるローカル通知ポート（§7.6）。
///
/// 具体実装は flutter_local_notifications を用いる（`infra/`）。
/// 通知本文にタイトル・文字起こし本文・トークンを含めてはならない（§9）。
abstract interface class StaleQueueNotifier {
  /// 未アップロード件数 [outstandingCount] を通知する。
  Future<void> notifyStale(int outstandingCount);
}

/// 端末ストレージの空き容量を取得するポート（§7.7 の逼迫判定用）。
abstract interface class DeviceStorageProbe {
  /// 現在の空き容量（バイト）。
  Future<int> freeBytes();
}

/// 何もしない通知ポート（未配線時 / テスト用の安全な既定）。
class NoopStaleQueueNotifier implements StaleQueueNotifier {
  const NoopStaleQueueNotifier();

  @override
  Future<void> notifyStale(int outstandingCount) async {}
}

/// 常に十分な空き容量を返すプローブ（逼迫削除を発動させない安全な既定）。
///
/// 実機で逼迫削除を有効化するには、ディスク空き容量を取得できる具体実装
/// （プラグイン）へ差し替えること。未配線時は「削除しない」側に倒れる。
class UnlimitedDeviceStorageProbe implements DeviceStorageProbe {
  const UnlimitedDeviceStorageProbe();

  @override
  Future<int> freeBytes() async => 1 << 62;
}
