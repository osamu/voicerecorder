import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/drive/drive_client.dart';
import '../domain/upload_ports.dart';
import '../domain/upload_queue.dart';

// NOTE(統合): drift 生成型（UploadJob 等）を provider シグネチャに含めると
// riverpod_generator がビルドフェーズ順序の都合で型解決に失敗するため、
// 本ファイルは手書き provider で定義する（名前・挙動は codegen 版と互換）。

// ---------------------------------------------------------------------------
// Foundation 依存（統合フェーズで override / 差し替え）
// ---------------------------------------------------------------------------

/// アプリ共有の [AppDatabase]。ProviderScope の override で本物を注入する。
///
/// core 側で共通の DB プロバイダが用意された場合はそちらへ委譲する。
final uploadDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'uploadDatabaseProvider must be overridden at app bootstrap '
    '(ProviderScope overrides) with the shared AppDatabase.',
  );
});

/// サインイン済みの [DriveClient]。ProviderScope の override で注入する。
final uploadDriveClientProvider = Provider<DriveClient>((ref) {
  throw UnimplementedError(
    'uploadDriveClientProvider must be overridden at app bootstrap '
    'with an authenticated DriveClient.',
  );
});

/// 滞留通知の実装。既定は no-op（infra の LocalNotifications 実装で override 可）。
final staleQueueNotifierProvider = Provider<StaleQueueNotifier>(
  (ref) => const NoopStaleQueueNotifier(),
);

// ---------------------------------------------------------------------------
// UploadQueue（キュー本体）
// ---------------------------------------------------------------------------

/// アプリ全体で単一の [UploadQueue]。ネット復帰で自動 flush する。
final uploadQueueProvider = Provider<UploadQueue>((ref) {
  final queue = UploadQueue(
    db: ref.watch(uploadDatabaseProvider),
    drive: ref.watch(uploadDriveClientProvider),
    staleNotifier: ref.watch(staleQueueNotifierProvider),
  );
  // ネット復帰イベントを橋渡し（connectivity_plus → ドメイン）。
  queue.attachConnectivity(
    Connectivity().onConnectivityChanged.map(
          (results) => !results.contains(ConnectivityResult.none),
        ),
  );
  ref.onDispose(queue.dispose);
  return queue;
});

// ---------------------------------------------------------------------------
// キュー状態のリアクティブ購読（バッジ・バナー・件数）
// ---------------------------------------------------------------------------

/// 未アップロード（pending / retryableFailed）ジョブ一覧。
final outstandingUploadsProvider = StreamProvider.autoDispose<List<UploadJob>>(
  (ref) => ref.watch(uploadDatabaseProvider).uploadJobsDao.watchOutstanding(),
);

/// 恒久失敗（要対応）ジョブ一覧。
final permanentFailedUploadsProvider =
    StreamProvider.autoDispose<List<UploadJob>>(
  (ref) =>
      ref.watch(uploadDatabaseProvider).uploadJobsDao.watchPermanentFailed(),
);

/// 再サインインが必要か（認証エラーでキュー一時停止中）。
final uploadNeedsReauthProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final queue = ref.watch(uploadQueueProvider);
  yield queue.needsReauth;
  yield* queue.needsReauthStream;
});

/// オンライン状態（true=接続あり）。
final uploadOnlineProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final connectivity = Connectivity();
  final current = await connectivity.checkConnectivity();
  yield !current.contains(ConnectivityResult.none);
  yield* connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
});

/// 一覧上部に出すバナー種別（優先度: 再認証 > 要対応 > オフライン）。
enum UploadBannerKind {
  /// バナー無し。
  none,

  /// 再サインインが必要（認証エラーで一時停止中）。
  reauthRequired,

  /// 恒久失敗ジョブがある（要対応）。
  actionRequired,

  /// オフライン（未アップが滞留中の可能性）。
  offline,
}

/// バナー状態（各ストリームから導出）。
final uploadBannerProvider = Provider.autoDispose<UploadBannerKind>((ref) {
  final needsReauth = ref.watch(uploadNeedsReauthProvider).value ?? false;
  if (needsReauth) return UploadBannerKind.reauthRequired;

  final failed = ref.watch(permanentFailedUploadsProvider).value ?? const [];
  if (failed.isNotEmpty) return UploadBannerKind.actionRequired;

  final online = ref.watch(uploadOnlineProvider).value ?? true;
  final outstanding =
      ref.watch(outstandingUploadsProvider).value ?? const [];
  if (!online && outstanding.isNotEmpty) return UploadBannerKind.offline;

  return UploadBannerKind.none;
});

// ---------------------------------------------------------------------------
// 手動アクション（UI から呼ぶ）
// ---------------------------------------------------------------------------

/// 手動再試行・再開などのアクションをまとめた薄いファサード。
class UploadActions {
  const UploadActions(this._queue);

  final UploadQueue _queue;

  /// 指定録音の失敗ジョブを再試行する（要対応バッジのボタン）。
  Future<void> retry(String recordingId) => _queue.retry(recordingId);

  /// 恒久失敗を一括再試行する。
  Future<void> retryAll() => _queue.retryAllPermanentFailed();

  /// 再サインイン成功後にキューを再開する。
  Future<void> resumeAfterSignIn() => _queue.resumeAfterSignIn();

  /// 録音停止直後の即時アップロード。
  Future<void> uploadNow(String recordingId) => _queue.uploadNow(recordingId);
}

/// [UploadActions] プロバイダ。
final uploadActionsProvider = Provider.autoDispose<UploadActions>(
  (ref) => UploadActions(ref.watch(uploadQueueProvider)),
);
