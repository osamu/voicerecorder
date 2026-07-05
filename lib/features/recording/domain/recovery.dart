import '../../../core/database/app_database.dart';

/// 未クローズ録音のリカバリで取るべきアクション（§6.2 / §12）。
enum RecoveryAction {
  /// クローズ処理が完了済み、または録音対象でない。何もしない。
  none,

  /// ファイル実体があり修復して確定できる。durationMs/sizeBytes を推定・確定し、
  /// タイトルを「中断された録音を復元しました」相当にしてキュー投入する。
  finalizeFromFile,

  /// 行はあるがファイル実体が無い（消失）。**failed 扱いにはしない**。
  /// localPath を NULL 化し、一覧には残すが再生・アップロード対象外にする。
  markMissing,
}

/// 1件の録音行に対するリカバリ判定結果。
class RecoveryAssessment {
  const RecoveryAssessment({
    required this.action,
    this.estimatedDurationMs = 0,
    this.sizeBytes = 0,
  });

  final RecoveryAction action;

  /// [RecoveryAction.finalizeFromFile] のとき、ファイルサイズから推定した長さ(ms)。
  final int estimatedDurationMs;

  /// [RecoveryAction.finalizeFromFile] のとき、確定させる実ファイルサイズ。
  final int sizeBytes;

  @override
  String toString() =>
      'RecoveryAssessment(action: $action, estMs: $estimatedDurationMs, size: $sizeBytes)';
}

/// 起動時リカバリの純粋判定ロジック（§6.2 / §12）。
///
/// DB 行・ファイル存在・ファイルサイズという「事実」から、取るべきアクションを
/// 決める純粋関数群。実 I/O（ファイル存在確認・サイズ取得・DB 更新）は呼び出し側。
abstract final class Recovery {
  /// 各コーデックの録音ビットレート（bps・モノラル 32kbps 目安）。
  /// ファイルサイズから録音長を概算するために使う（あくまで推定値）。
  static const int _bitsPerSecond = 32 * 1000;

  /// 「未クローズ」とみなす条件（§6.2）:
  /// durationMs == 0（停止時に確定される値が入っていない）。
  ///
  /// 録音中フラグ列は持たないため、`durationMs == 0` を未クローズの代理指標とする。
  /// 正常停止時は必ず durationMs > 0 が書かれるため、0 のまま残っている行は
  /// クローズ処理に到達しなかった（クラッシュ/kill）ものと判断できる。
  static bool isUnclosed(Recording rec) => isUnclosedMs(rec.durationMs);

  /// [durationMs] だけで未クローズ判定する純粋版（テスト用）。
  static bool isUnclosedMs(int durationMs) => durationMs == 0;

  /// 未クローズ録音に対する判定。
  ///
  /// [rec] 対象行、[fileExists] localPath のファイルが実在するか、
  /// [fileSizeBytes] 実ファイルのサイズ（存在しないなら 0）。
  static RecoveryAssessment assess(
    Recording rec, {
    required bool fileExists,
    required int fileSizeBytes,
  }) {
    return assessRaw(
      durationMs: rec.durationMs,
      localPath: rec.localPath,
      fileExists: fileExists,
      fileSizeBytes: fileSizeBytes,
    );
  }

  /// [assess] のプリミティブ入力版（生成データクラス非依存・テスト対象）。
  static RecoveryAssessment assessRaw({
    required int durationMs,
    required String? localPath,
    required bool fileExists,
    required int fileSizeBytes,
  }) {
    if (!isUnclosedMs(durationMs)) {
      return const RecoveryAssessment(action: RecoveryAction.none);
    }
    // localPath が無い（開始直後に落ちた等）→ 実体不明。missing 扱い。
    if (localPath == null || !fileExists || fileSizeBytes <= 0) {
      return const RecoveryAssessment(action: RecoveryAction.markMissing);
    }
    return RecoveryAssessment(
      action: RecoveryAction.finalizeFromFile,
      estimatedDurationMs: estimateDurationMs(fileSizeBytes),
      sizeBytes: fileSizeBytes,
    );
  }

  /// ファイルサイズ(bytes)から録音長(ms)を概算する。
  ///
  /// `ms = bytes * 8 / bitsPerSecond * 1000`。コンテナのオーバーヘッドは無視する
  /// 粗い推定。リカバリ表示・ソート用途には十分。
  static int estimateDurationMs(int sizeBytes) {
    if (sizeBytes <= 0) return 0;
    return (sizeBytes * 8 * 1000 / _bitsPerSecond).round();
  }
}
