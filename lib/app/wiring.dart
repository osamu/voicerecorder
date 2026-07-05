import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/database/tables.dart';
import '../core/naming/naming.dart';
import '../core/security/app_logger.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/domain/auth_state.dart' as auth_domain;
import '../features/auth/presentation/auth_providers.dart' as auth;
import '../features/recording/domain/recording_paths.dart';
import '../features/recording/domain/recording_runtime.dart';
import '../features/recording/domain/recording_service.dart';
import '../features/recording/presentation/mic_permission.dart';
import '../features/recording/presentation/recording_providers.dart' as rec;
import '../features/transcription/presentation/transcription_providers.dart'
    as stt;
import '../features/upload/domain/upload_queue.dart';
import '../features/upload/infra/local_notifications_stale_notifier.dart';
import '../features/upload/presentation/upload_providers.dart' as upload;
import 'contracts.dart';
import 'providers.dart';

/// 統合配線（app 層）。
///
/// 各 feature が並列実装したドメインサービス／プロバイダを、UI が依存する
/// [contracts.dart] の抽象へ橋渡しするアダプタ群と、bootstrap で
/// [ProviderContainer] に与える override 一覧を定義する。
///
/// 既定（override 無し＝widget テスト環境）では [providers.dart] のスタブが
/// 使われ、プラットフォームチャネルに触れない。実機動作時のみ本配線が有効。

const _log = AppLogger('wiring');

/// 実アプリ用の [ProviderContainer] を構築する（bootstrap から呼ぶ）。
///
/// [db] は bootstrap で開いた共有 [AppDatabase]。各 feature が個別に定義した
/// DB プロバイダ shim もすべて同一インスタンスへ寄せる（単一 DB 原則）。
///
/// NOTE: flutter_riverpod 3.x は `Override` 型を export しないため、
/// override 一覧を返す形ではなくコンテナ生成までをここで行う。
ProviderContainer createAppContainer(AppDatabase db) {
  return ProviderContainer(overrides: [
    // --- Foundation: 共有 DB を全 feature の shim に注入 ---
    appDatabaseProvider.overrideWithValue(db),
    rec.appDatabaseProvider.overrideWith((ref) => db),
    auth.appDatabaseProvider.overrideWith((ref) => db),
    stt.appDatabaseProvider.overrideWithValue(db),
    upload.uploadDatabaseProvider.overrideWithValue(db),

    // --- upload feature の Foundation 依存 ---
    // DriveClient は auth feature（認証済みクライアント供給）から取得。
    upload.uploadDriveClientProvider.overrideWith(
      (ref) => ref.watch(auth.driveClientProvider),
    ),
    upload.staleQueueNotifierProvider.overrideWith(
      (ref) =>
          LocalNotificationsStaleNotifier(FlutterLocalNotificationsPlugin()),
    ),

    // --- 録音停止 → 即時アップロード＋文字起こし投入（§6.1 / §7.6）---
    rec.recordingSegmentFinalizedHookProvider.overrideWith(
      (ref) => (recordingId) => _onSegmentFinalized(ref, recordingId),
    ),

    // --- UI 契約（contracts.dart）の実体アダプタ ---
    authControllerProvider.overrideWith(AppAuthController.new),
    recordingControllerProvider.overrideWith(AppRecordingController.new),
    uploadControllerProvider.overrideWith(AppUploadController.new),
    transcriptionControllerProvider
        .overrideWith(AppTranscriptionController.new),
    permissionControllerProvider.overrideWith(AppPermissionController.new),

    // --- 実 connectivity 監視（オフラインバナー用）---
    connectivityProvider.overrideWith((ref) => _onlineStream()),
  ]);
}

/// connectivity_plus を「オンラインか」の bool ストリームへ変換する。
Stream<bool> _onlineStream() async* {
  final connectivity = Connectivity();
  final current = await connectivity.checkConnectivity();
  yield !current.contains(ConnectivityResult.none);
  yield* connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
}

/// セグメント確定直後の統合フロー（録音優先・fire-and-forget）。
///
/// 1. UploadQueue.uploadNow — FG 中の即時アップロード（§7.6）。
/// 2. 文字起こし ON なら TranscriptionService.transcribe（ベストエフォート）。
/// いずれの失敗も録音の確定保存には影響しない。
void _onSegmentFinalized(Ref ref, String recordingId) {
  unawaited(Future(() async {
    try {
      await ref.read(upload.uploadQueueProvider).uploadNow(recordingId);
    } catch (e) {
      _log.error('uploadNow', recordingId: recordingId, error: e);
    }
  }));
  unawaited(Future(() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final enabled =
          await db.settingsDao.getValue(SettingsKeys.transcriptionEnabled);
      if (enabled == 'true') {
        // transcribe は内部で例外を握る（録音優先）。
        await ref.read(stt.transcriptionServiceProvider).transcribe(recordingId);
      }
    } catch (e) {
      _log.error('transcribeKickoff', recordingId: recordingId, error: e);
    }
  }));
}

// ---------------------------------------------------------------------------
// 認証（auth feature → contracts.AuthController）
// ---------------------------------------------------------------------------

class AppAuthController implements AuthController {
  AppAuthController(this._ref);

  final Ref _ref;

  AuthService get _service => _ref.read(auth.authServiceProvider);

  @override
  AuthState get current => _map(_service.currentState);

  @override
  Stream<AuthState> watch() => _service.authStateChanges.map(_map);

  @override
  Future<void> signIn() async {
    await _service.signIn();
    // サインイン成功でアップロードキューを自動再開（§7.5）。
    final queue = _ref.read(upload.uploadQueueProvider);
    await queue.resumeAfterSignIn();
    unawaited(queue.flush());
  }

  @override
  Future<void> signOut() async {
    // revoke ＋トークン破棄。キューは破棄せず保持（§7.5 / §9）。
    await _service.signOut();
  }

  static AuthState _map(auth_domain.AuthState state) {
    return switch (state) {
      auth_domain.AuthSignedOut() => AuthState.signedOut,
      auth_domain.AuthSignedIn(
        :final email,
        :final displayName,
        :final photoUrl,
      ) =>
        AuthState(
          status: AuthStatus.signedIn,
          account: AuthAccount(
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
          ),
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// 録音（recording feature → contracts.RecordingController）
// ---------------------------------------------------------------------------

class AppRecordingController implements RecordingController {
  AppRecordingController(this._ref);

  final Ref _ref;

  /// 同期 getter（[active]）用のキャッシュ。実体は provider が保持する。
  RecordingService? _cached;

  Future<RecordingService> _service() async {
    final cached = _cached;
    if (cached != null) return cached;
    final service = await _ref.read(rec.recordingServiceProvider.future);
    _cached = service;
    return service;
  }

  static ActiveRecording? _toActive(RecordingRuntime runtime) {
    final id = runtime.recordingId;
    if (!runtime.isActive || id == null) return null;
    return ActiveRecording(
      recordingId: id,
      startedAt: runtime.groupStartedAt ?? DateTime.now(),
    );
  }

  @override
  ActiveRecording? get active {
    final service = _cached;
    return service == null ? null : _toActive(service.runtime);
  }

  @override
  Stream<ActiveRecording?> watchActive() async* {
    final service = await _service();
    yield _toActive(service.runtime);
    yield* service.runtimeStream.map(_toActive);
  }

  @override
  Future<void> start() async {
    await (await _service()).start();
  }

  @override
  Future<void> stop() async {
    await (await _service()).stop();
  }

  @override
  Future<void> recoverInterrupted() async {
    await (await _service()).recoverInterruptedRecordings();
  }
}

// ---------------------------------------------------------------------------
// アップロード（upload feature → contracts.UploadController）
// ---------------------------------------------------------------------------

class AppUploadController implements UploadController {
  AppUploadController(this._ref);

  final Ref _ref;

  UploadQueue get _queue => _ref.read(upload.uploadQueueProvider);
  AppDatabase get _db => _ref.read(appDatabaseProvider);

  @override
  Future<void> renameRecording(String recordingId, String newTitle) =>
      _queue.renameRecording(recordingId, newTitle);

  @override
  Future<void> deleteRecording(
    String recordingId, {
    required bool alsoDeleteFromDrive,
  }) =>
      _queue.deleteRecording(recordingId, deleteFromDrive: alsoDeleteFromDrive);

  @override
  Future<void> retryUpload(String recordingId) => _queue.retry(recordingId);

  @override
  Future<void> refetchLocalCopy(String recordingId) async {
    final recording = await _db.recordingsDao.getById(recordingId);
    if (recording == null) return;
    final fileId = recording.driveFileId;
    if (fileId == null) {
      throw StateError('Drive 上にファイルがありません');
    }
    final paths = await RecordingPaths.create();
    await paths.ensureDir();
    final fileName = Naming.audioFileName(
      DateTime.parse(recording.startedAt),
      recording.codec,
      title: recording.title,
    );
    final localPath = paths.pathFor(fileName);
    await _ref
        .read(upload.uploadDriveClientProvider)
        .downloadFile(fileId, localPath);
    await _db.recordingsDao.setLocalPath(recordingId, localPath);
  }

  @override
  Future<int> pendingUploadCount() async {
    final jobs = await _db.uploadJobsDao.watchOutstanding().first;
    return jobs.length;
  }

  @override
  Future<void> resumeQueue() async {
    // 未サインイン時に flush すると認証エラーでキューが「再認証待ち」に
    // 一時停止してしまうため、サインイン済みのときのみ再開する（§7.5）。
    // 未サインインでもジョブは pending で保持される（Drive未設定バッジ）。
    if (_ref.read(auth.authServiceProvider).isSignedIn) {
      await _queue.recoverOnStartup();
    } else {
      await _db.uploadJobsDao.resetStuckUploading();
    }
  }

  @override
  Future<StorageUsage> storageUsage() async {
    final all = await _db.recordingsDao.watchAll().first;
    var totalBytes = 0;
    var reclaimableBytes = 0;
    var reclaimableCount = 0;
    for (final recording in all) {
      if (recording.localPath == null) continue;
      totalBytes += recording.sizeBytes;
      if (recording.uploadState == UploadState.done) {
        reclaimableBytes += recording.sizeBytes;
        reclaimableCount += 1;
      }
    }
    return StorageUsage(
      totalBytes: totalBytes,
      reclaimableBytes: reclaimableBytes,
      reclaimableFileCount: reclaimableCount,
    );
  }

  @override
  Future<void> deleteUploadedLocalFiles() async {
    // 対象はアップロード完了済みのみ（未アップは決して消さない・§7.7）。
    final candidates = await _db.recordingsDao.getReclaimableOldestFirst();
    for (final recording in candidates) {
      final path = recording.localPath;
      if (path == null) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        _log.error('deleteUploadedLocal', recordingId: recording.id, error: e);
        continue;
      }
      await _db.recordingsDao.setLocalPath(recording.id, null);
    }
  }
}

// ---------------------------------------------------------------------------
// 文字起こし（transcription feature → contracts.TranscriptionController）
// ---------------------------------------------------------------------------

class AppTranscriptionController implements TranscriptionController {
  AppTranscriptionController(this._ref);

  final Ref _ref;

  @override
  Future<void> retranscribe(String recordingId) =>
      _ref.read(stt.transcriptionServiceProvider).transcribe(recordingId);

  @override
  Future<void> resumePendingJobs() =>
      _ref.read(stt.transcriptionServiceProvider).resumePendingJobs();

  @override
  List<TranscriptionEngineInfo> availableEngines() {
    final registry = _ref.read(stt.transcriptionEngineRegistryProvider);
    return registry.all
        .map((e) => TranscriptionEngineInfo(id: e.id, displayName: e.displayName))
        .toList(growable: false);
  }

  @override
  Future<List<String>> supportedLocales(String engineId) async {
    final engine =
        _ref.read(stt.transcriptionEngineRegistryProvider).engine(engineId);
    if (engine == null) return const [];
    return engine.supportedLocales();
  }
}

// ---------------------------------------------------------------------------
// 権限（recording feature の MicPermissionFlow → contracts.PermissionController）
// ---------------------------------------------------------------------------

class AppPermissionController implements PermissionController {
  AppPermissionController(this._ref);

  final Ref _ref;

  MicPermissionFlow get _flow => _ref.read(micPermissionFlowProvider);

  static AppPermissionStatus _map(MicPermissionStatus status) {
    return switch (status) {
      MicPermissionStatus.granted => AppPermissionStatus.granted,
      MicPermissionStatus.denied => AppPermissionStatus.denied,
      MicPermissionStatus.permanentlyDenied =>
        AppPermissionStatus.permanentlyDenied,
    };
  }

  @override
  Future<AppPermissionStatus> microphoneStatus() async =>
      _map(await _flow.check());

  @override
  Future<AppPermissionStatus> requestMicrophone() async =>
      _map(await _flow.request());

  @override
  Future<void> openAppSettings() => _flow.openSettings();
}
