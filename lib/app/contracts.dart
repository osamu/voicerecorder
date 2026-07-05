/// UI 層（本エージェント所有）が依存する、他 feature のコントローラ契約。
///
/// これらの実装は録音 / アップロード / 認証 / 文字起こし / 権限の各 feature が
/// 並行実装中である。UI はここで定義した抽象インターフェースにのみ依存し、
/// 実体は統合フェーズで Riverpod の `overrideWithValue` により差し替えられる。
///
/// ここに置く型は「UI が呼ぶ最小限のシグネチャ」であり、各 feature の内部
/// ドメイン型とは独立している（統合時に薄いアダプタで橋渡しする想定）。
library;

// ---------------------------------------------------------------------------
// 認証（auth feature）
// ---------------------------------------------------------------------------

/// サインイン状態。
enum AuthStatus { signedOut, signedIn }

/// サインイン中の Google アカウント情報（表示用）。
class AuthAccount {
  const AuthAccount({required this.email, this.displayName, this.photoUrl});

  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// 認証状態のスナップショット。
class AuthState {
  const AuthState({required this.status, this.account});

  final AuthStatus status;
  final AuthAccount? account;

  bool get isSignedIn => status == AuthStatus.signedIn;

  static const AuthState signedOut = AuthState(status: AuthStatus.signedOut);
}

/// 認証操作の UI 向け契約。
abstract interface class AuthController {
  /// 認証状態の変化を購読する。
  Stream<AuthState> watch();

  /// 現在の認証状態（同期取得）。
  AuthState get current;

  /// Google サインイン（`drive.file` スコープ）を実行する。
  Future<void> signIn();

  /// サインアウト（トークン revoke 含む）。キューは破棄しない。
  Future<void> signOut();
}

// ---------------------------------------------------------------------------
// 録音（recording feature）
// ---------------------------------------------------------------------------

/// 進行中の録音セッション（録音中バー用）。
class ActiveRecording {
  const ActiveRecording({required this.recordingId, required this.startedAt});

  final String recordingId;

  /// 録音開始時刻（経過時間はここから算出する）。
  final DateTime startedAt;
}

/// 録音操作の UI 向け契約。
abstract interface class RecordingController {
  /// 進行中セッションを購読する（無ければ null を流す）。
  Stream<ActiveRecording?> watchActive();

  /// 現在進行中のセッション（同期取得。無ければ null）。
  ActiveRecording? get active;

  /// 録音を開始する（フォアグラウンド起点）。
  Future<void> start();

  /// 録音を停止し、確定保存＋アップロードキュー投入を行う。
  Future<void> stop();

  /// 起動時: 未クローズ録音のリカバリ（DESIGN §6.2 / §12-2）。
  Future<void> recoverInterrupted();
}

// ---------------------------------------------------------------------------
// アップロード（upload feature）
// ---------------------------------------------------------------------------

/// ストレージ使用量サマリ（設定画面用）。
class StorageUsage {
  const StorageUsage({
    required this.totalBytes,
    required this.reclaimableBytes,
    required this.reclaimableFileCount,
  });

  /// ローカルに保持している録音・txt の合計バイト数。
  final int totalBytes;

  /// アップロード完了済みで削除可能なローカルファイルの合計バイト数（§7.7）。
  final int reclaimableBytes;

  /// 上記の対象ファイル数。
  final int reclaimableFileCount;

  static const StorageUsage empty = StorageUsage(
    totalBytes: 0,
    reclaimableBytes: 0,
    reclaimableFileCount: 0,
  );
}

/// アップロード・Drive 反映・ローカル整理の UI 向け契約。
abstract interface class UploadController {
  /// タイトル部を改名する。ローカルファイル改名＋Drive 反映（fileId 基準）。
  Future<void> renameRecording(String recordingId, String newTitle);

  /// 録音を削除する。既定はローカルのみ。[alsoDeleteFromDrive] で Drive 側も削除。
  /// 未アップの場合はキューからジョブも除去する。
  Future<void> deleteRecording(
    String recordingId, {
    required bool alsoDeleteFromDrive,
  });

  /// 恒久失敗（要対応）ジョブの手動再試行。
  Future<void> retryUpload(String recordingId);

  /// ローカル実体が無い録音を Drive から再取得しローカルへ復元する（要オンライン）。
  Future<void> refetchLocalCopy(String recordingId);

  /// 未アップロード（pending / retryableFailed）件数（サインアウト警告用）。
  Future<int> pendingUploadCount();

  /// 起動時: 中断アップロードの再開（DESIGN §12-3）。
  Future<void> resumeQueue();

  /// ストレージ使用量サマリを取得する。
  Future<StorageUsage> storageUsage();

  /// アップロード完了済みのローカルファイルを一括削除する（localPath=NULL 化）。
  Future<void> deleteUploadedLocalFiles();
}

// ---------------------------------------------------------------------------
// 文字起こし（transcription feature）
// ---------------------------------------------------------------------------

/// 設定画面のエンジン選択肢。
class TranscriptionEngineInfo {
  const TranscriptionEngineInfo({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

/// 文字起こし操作の UI 向け契約。
abstract interface class TranscriptionController {
  /// 録音単位の再文字起こし（失敗後リトライ / 手動再実行）。
  Future<void> retranscribe(String recordingId);

  /// 起動時: submitted/running ジョブの再購読（DESIGN §12-4）。
  Future<void> resumePendingJobs();

  /// 選択可能なエンジン一覧（MVP はクラウド STT のみ）。
  List<TranscriptionEngineInfo> availableEngines();

  /// 指定エンジンが対応する言語の一覧（設定の言語リスト用）。
  /// autoDetect エンジンの場合は空リストを返す。
  Future<List<String>> supportedLocales(String engineId);
}

// ---------------------------------------------------------------------------
// 権限（onboarding / recording feature）
// ---------------------------------------------------------------------------

/// OS 権限の状態。
enum AppPermissionStatus { granted, denied, permanentlyDenied }

/// 権限フローの UI 向け契約。
abstract interface class PermissionController {
  /// マイク権限の現在状態を取得する。
  Future<AppPermissionStatus> microphoneStatus();

  /// マイク権限を要求する。
  Future<AppPermissionStatus> requestMicrophone();

  /// OS のアプリ設定画面を開く（永久拒否時の誘導）。
  Future<void> openAppSettings();
}

// ---------------------------------------------------------------------------
// Drive 再取得の進捗（再生画面用の軽量結果型）
// ---------------------------------------------------------------------------

/// UI からのアクションが未接続（統合前）であることを表す例外。
///
/// スタブ実装が投げる。UI は握りつぶしてスナックバーで案内する。
class NotWiredException implements Exception {
  const NotWiredException([this.feature = 'この機能']);
  final String feature;

  @override
  String toString() => 'NotWiredException: $feature は統合フェーズで接続されます';
}
