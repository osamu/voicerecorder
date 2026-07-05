import 'dart:io';

/// Google Drive 操作の抽象インターフェース（DESIGN.md §7）。
///
/// 実装は googleapis Drive v3 ラッパ（別担当）。本ファイルは契約のみを定義する。
///
/// 設計上の不変条件:
/// - スコープは `drive.file` のみ。アプリ自作 `/VoiceRecorder/` 配下のみ扱う。
/// - すべての操作は fileId 基準。冪等化は appProperties の `vrId`（UUID）で行う。
/// - 一時エラー（[DriveTransientException]）と恒久エラー（[DriveAuthException] /
///   [DriveFolderMissingException] / [DriveQuotaException]）を型で区別する。
abstract interface class DriveClient {
  /// `/VoiceRecorder/` ルートフォルダを取得（無ければ作成）し fileId を返す。
  /// 既存が trashed の場合は [DriveFolderMissingException] を投げてよい。
  Future<String> ensureRootFolder();

  /// 録音開始時刻に対応する日付サブフォルダ
  /// `/VoiceRecorder/<YYYY>/<YYYY-MM>/` を get-or-create し fileId を返す。
  Future<String> ensureDateFolder(DateTime startedAt);

  /// resumable アップロードのセッションを開始し、再開用の session URI を返す。
  ///
  /// [parentFolderId] はアップ先フォルダの fileId。
  /// [vrId] / [vrKind] は appProperties に付与する冪等化キー。
  Future<String> startResumableSession({
    required String parentFolderId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String vrId,
    required String vrKind,
  });

  /// resumable セッションへ実データを送信する。中断後の再開に対応する
  /// （実装は session URI に対する現在オフセットを問い合わせ、続きから送る）。
  ///
  /// [sessionUri] は [startResumableSession] の戻り値。
  /// [onProgress] は送信済み/全体バイト数の進捗コールバック（任意）。
  /// 成功時にアップロードされたファイルのメタデータを返す。
  Future<DriveFile> uploadResumable({
    required String sessionUri,
    required File file,
    required String mimeType,
    void Function(int sentBytes, int totalBytes)? onProgress,
  });

  /// appProperties の `vrId` + `vrKind` で既存ファイルを検索し fileId を返す。
  /// 見つからなければ null。二重アップロード防止（リトライ前検索）に使う。
  Future<String?> findByVrId(String vrId, String vrKind);

  /// ファイル名を変更する（fileId 基準）。
  Future<void> renameFile(String fileId, String newName);

  /// ファイルを削除する（fileId 基準）。
  Future<void> deleteFile(String fileId);

  /// Drive 上のファイルをローカルパスへダウンロードする（再取得・再生用）。
  Future<void> downloadFile(String fileId, String localPath);

  /// 既存ファイルの内容を上書き更新する（fileId 維持。再文字起こし txt 用）。
  /// 成功時に更新後のメタデータを返す。
  Future<DriveFile> updateFileContent(
    String fileId, {
    required File content,
    required String mimeType,
  });
}

/// Drive ファイルの最小メタデータ。
class DriveFile {
  const DriveFile({
    required this.id,
    required this.name,
    this.mimeType,
    this.sizeBytes,
    this.appProperties = const {},
  });

  /// Drive fileId（以後の操作の基準）。
  final String id;

  /// ファイル名。
  final String name;

  /// MIME タイプ（判明時）。
  final String? mimeType;

  /// サイズ（判明時）。
  final int? sizeBytes;

  /// appProperties（`vrId` / `vrKind` 等）。
  final Map<String, String> appProperties;
}

// ---------------------------------------------------------------------------
// 例外型 — 一時 / 恒久エラーの分類に足るもの（§7.5 の状態遷移に対応）
// ---------------------------------------------------------------------------

/// Drive 操作の基底例外。
sealed class DriveException implements Exception {
  const DriveException(this.message);

  /// 人間向けの短い説明（ログには機微情報を含めないこと）。
  final String message;

  /// 一時エラー（バックオフで再試行可）か。恒久エラーは false。
  bool get isRetryable;

  @override
  String toString() => '$runtimeType: $message';
}

/// 認証エラー（401 / トークン失効）。恒久。キューを一時停止し再サインインを誘導。
class DriveAuthException extends DriveException {
  const DriveAuthException([super.message = 'authentication required']);

  @override
  bool get isRetryable => false;
}

/// ルート/対象フォルダが削除・trashed されている。恒久。再作成の導線を出す。
class DriveFolderMissingException extends DriveException {
  const DriveFolderMissingException([super.message = 'target folder missing']);

  @override
  bool get isRetryable => false;
}

/// Drive 容量超過。恒久（ユーザー対応が必要）。
class DriveQuotaException extends DriveException {
  const DriveQuotaException([super.message = 'drive storage quota exceeded']);

  @override
  bool get isRetryable => false;
}

/// ネットワーク断 / 5xx / 429 等の一時エラー。バックオフで再試行する。
class DriveTransientException extends DriveException {
  const DriveTransientException([super.message = 'transient drive error', this.statusCode]);

  /// HTTP ステータスコード（判明時）。
  final int? statusCode;

  @override
  bool get isRetryable => true;
}
