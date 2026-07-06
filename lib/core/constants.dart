/// アプリ全体で共有する閾値・定数を一元管理する（DESIGN.md 各章の「仮値」を集約）。
///
/// マジックナンバーを各所に散らさず、ここを single source of truth とする。
abstract final class AppConstants {
  // -------------------------------------------------------------------------
  // ストレージ（§6.2 / §7.7）
  // -------------------------------------------------------------------------

  /// 録音開始時に必要な最低空き容量（未満なら警告付き開始）。200MB。
  static const int minFreeSpaceToStartBytes = 200 * 1024 * 1024;

  /// 逼迫時自動削除を発動する空き容量閾値。500MB 未満で発動。
  /// 対象はアップロード完了済みローカルファイルのみ・古い順。
  static const int reclaimThresholdBytes = 500 * 1024 * 1024;

  // -------------------------------------------------------------------------
  // アップロード リトライ / バックオフ（§7.5）
  // -------------------------------------------------------------------------

  /// 指数バックオフの初回待機時間。30 秒。
  static const Duration backoffInitial = Duration(seconds: 30);

  /// 指数バックオフの上限。1 時間。
  static const Duration backoffMax = Duration(hours: 1);

  /// バックオフ倍率（倍々）。
  static const double backoffMultiplier = 2.0;

  // -------------------------------------------------------------------------
  // 文字起こし（§8.4）
  // -------------------------------------------------------------------------

  /// クラウド STT（Whisper API 等）の最大ファイルサイズ。25MB。
  /// 超過時は MVP では failed（理由バッジ）。
  static const int sttMaxFileSizeBytes = 25 * 1024 * 1024;

  // -------------------------------------------------------------------------
  // 通知 / 滞留（§7.6）
  // -------------------------------------------------------------------------

  /// キュー滞留の通知閾値。24 時間以上未アップロードで通知。
  static const Duration staleQueueNotifyThreshold = Duration(hours: 24);

  // -------------------------------------------------------------------------
  // 録音（§6.2 / §11）
  // -------------------------------------------------------------------------

  /// 録音データの定期フラッシュ間隔（目安 5 秒）。
  static const Duration recordingFlushInterval = Duration(seconds: 5);

  /// タイトル部（ファイル名）の最大文字数。
  static const int maxTitleLength = 80;

  // -------------------------------------------------------------------------
  // Drive（§7.1）
  // -------------------------------------------------------------------------

  /// アプリ自作ルートフォルダ名。
  static const String driveRootFolderName = 'CloudRecorder';

  /// Drive appProperties の UUID キー（冪等化）。
  static const String drivePropVrId = 'vrId';

  /// Drive appProperties の種別キー（'audio' / 'transcript'）。
  static const String drivePropVrKind = 'vrKind';

  /// Drive フォルダの階層パスキー（フォルダ検索用）。
  static const String drivePropFolderPath = 'vrFolderPath';
}
