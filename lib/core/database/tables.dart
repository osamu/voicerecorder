import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// enum 定義（DB には TextColumn で「名前」を格納する。整数インデックス格納は避け、
// マイグレーション耐性を確保する。drift の textEnum を使用）
// ---------------------------------------------------------------------------

/// 音声コーデック。拡張子・MIME 決定に使用する。
/// iOS = AAC(.m4a) / Android = Ogg Opus(.opus)。
enum Codec {
  /// iOS: AAC in M4A コンテナ
  aacM4a,

  /// Android: Ogg Opus
  oggOpus,
}

/// recordings.uploadState — 一覧バッジ用の非正規化された射影値（§7.5）。
/// 真の状態は upload_jobs が持つ。
enum UploadState {
  /// 未アップロード（pending / retryableFailed の射影）
  pending,

  /// アップロード中
  uploading,

  /// 完了
  done,

  /// 要対応（permanentFailed の射影。手動再試行の導線を出す）
  actionRequired,
}

/// recordings.transcriptState — 一覧バッジ用の非正規化された射影値（§8.6）。
enum TranscriptState {
  /// 文字起こし OFF、または権限縮退
  off,

  /// 処理中（job が queued / submitted / running）
  processing,

  /// 完了
  done,

  /// 一部のみ（partialText を保存）
  partial,

  /// 失敗（再試行可）
  failed,
}

/// upload_jobs.kind — アップロード対象の種別。
enum UploadJobKind {
  /// 音声ファイル（高優先度）
  audio,

  /// 文字起こし .txt（低優先度）
  transcript,
}

/// upload_jobs.state — アップロードキューの状態機械（§7.5）。
enum UploadJobState {
  /// 実行待ち
  pending,

  /// アップロード中
  uploading,

  /// 完了
  done,

  /// 一時エラー（バックオフで pending へ戻す）
  retryableFailed,

  /// 恒久エラー（手動再試行 / 原因解消が必要）
  permanentFailed,
}

/// transcription_jobs.state — 文字起こしジョブの状態（§5.3 / §8.6）。
enum TranscriptionJobState {
  /// 投入待ち
  queued,

  /// エンジンへ投入済み（jobHandle 取得済み）
  submitted,

  /// 実行中
  running,

  /// 完了
  done,

  /// 一部のみ成功
  partial,

  /// 失敗
  failed,
}

// ---------------------------------------------------------------------------
// テーブル定義
// ---------------------------------------------------------------------------

/// 録音メタデータ（§5.1）。状態の single source of truth は本 DB。
@DataClassName('Recording')
class Recordings extends Table {
  /// UUID v4。ローカル録音開始時に生成。Drive appProperties(vrId) にも同値を付与。
  TextColumn get id => text()();

  /// 録音開始時刻。ISO8601 + タイムゾーンオフセット（端末ローカル時刻基準）。
  TextColumn get startedAt => text()();

  /// 録音時間（ミリ秒）。リカバリ復元時は推定値。
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// 端末内ファイルの絶対パス。逼迫時自動削除後は NULL。
  TextColumn get localPath => text().nullable()();

  /// ユーザー指定タイトル（ファイル名のタイトル部）。空なら日時のみの名前。
  TextColumn get title => text().withDefault(const Constant(''))();

  /// 音声ファイルの Drive fileId。アップ成功時に保存。
  TextColumn get driveFileId => text().nullable()();

  /// .txt の Drive fileId。
  TextColumn get txtDriveFileId => text().nullable()();

  /// アップロード状態バッジ（射影値）。
  TextColumn get uploadState =>
      textEnum<UploadState>().withDefault(const Constant('pending'))();

  /// 文字起こし状態バッジ（射影値）。
  TextColumn get transcriptState =>
      textEnum<TranscriptState>().withDefault(const Constant('off'))();

  /// ファイルサイズ（バイト）。
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  /// 音声コーデック（拡張子・MIME 決定に使用）。
  TextColumn get codec => textEnum<Codec>()();

  /// 生成済み .txt のローカルパス（閲覧用）。
  TextColumn get transcriptLocalPath => text().nullable()();

  /// 監査・ソート用（ISO8601）。
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// アップロードジョブ（§5.2）。UNIQUE(recordingId, kind) が冪等性の第一防壁。
@DataClassName('UploadJob')
class UploadJobs extends Table {
  /// UUID。
  TextColumn get id => text()();

  /// 対象録音（FK → recordings.id）。
  TextColumn get recordingId =>
      text().references(Recordings, #id, onDelete: KeyAction.cascade)();

  /// audio / transcript。transcript は低優先度。
  TextColumn get kind => textEnum<UploadJobKind>()();

  /// キュー状態機械。
  TextColumn get state =>
      textEnum<UploadJobState>().withDefault(const Constant('pending'))();

  /// リトライ回数。
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// 指数バックオフの次回試行時刻（ISO8601）。
  TextColumn get nextRetryAt => text().nullable()();

  /// Drive resumable session URI（再開用）。
  TextColumn get resumableUri => text().nullable()();

  /// アップ先（年-月フォルダ）の fileId。解決済みならキャッシュ。
  TextColumn get driveFolderId => text().nullable()();

  /// 直近エラー（機微情報を含めない）。
  TextColumn get lastError => text().nullable()();

  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  /// 同一録音・同一種別のジョブは常に1つ（冪等性の第一防壁）。
  @override
  List<Set<Column>> get uniqueKeys => [
        {recordingId, kind},
      ];
}

/// 文字起こしジョブ（§5.3）。起動時に submitted/running を再購読する。
@DataClassName('TranscriptionJob')
class TranscriptionJobs extends Table {
  /// UUID。
  TextColumn get id => text()();

  /// 対象録音（FK → recordings.id）。
  TextColumn get recordingId =>
      text().references(Recordings, #id, onDelete: KeyAction.cascade)();

  /// cloud_stt 等。Registry のキー。
  TextColumn get engineId => text()();

  /// エンジン固有のジョブ識別子を JSON 文字列でシリアライズ保存。再購読に必須。
  TextColumn get jobHandle => text().nullable()();

  /// ジョブ状態。
  TextColumn get state =>
      textEnum<TranscriptionJobState>().withDefault(const Constant('queued'))();

  /// 試行回数。
  IntColumn get attempt => integer().withDefault(const Constant(0))();

  /// ジョブ投入時点の言語設定（ja-JP 等）。autoDetect エンジンは NULL。
  TextColumn get localeId => text().nullable()();

  /// 直近エラー（機微情報を含めない）。
  TextColumn get lastError => text().nullable()();

  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// key-value 設定（§5.4）。OAuth トークンはここに置かず flutter_secure_storage へ。
@DataClassName('SettingEntry')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
