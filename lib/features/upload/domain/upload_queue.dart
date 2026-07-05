import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/drive/drive_client.dart';
import '../../../core/naming/naming.dart';
import '../../../core/security/app_logger.dart';
import 'backoff.dart';
import 'upload_ports.dart';

/// 1 ジョブ処理の結果（テスト・フロー制御用）。
enum JobOutcome {
  /// アップロード完了（既存回収を含む）。
  done,

  /// 一時エラー。バックオフ後に再試行される。
  retryable,

  /// 恒久エラー。要対応（actionRequired）へ射影。
  permanent,

  /// 認証エラー。キュー全体を一時停止（ジョブは pending 保持）。
  pausedAuth,

  /// 対象録音が無い等で処理不能（ジョブ破棄）。
  skipped,
}

/// アップロードキュー（DESIGN.md §7）。ドメイン層・plain Dart。
///
/// 依存は [AppDatabase]（状態の single source of truth）と [DriveClient] 抽象のみ。
/// Riverpod / Flutter には依存しない（BG isolate から直接使用可能）。
///
/// 状態機械（§7.5）:
/// ```
/// pending → uploading → done
///   ▲          │
///   └ retryableFailed(指数バックオフ) ◀┘
///              │
///              ▼
///        permanentFailed(要対応)
/// ```
class UploadQueue {
  UploadQueue({
    required AppDatabase db,
    required DriveClient drive,
    StaleQueueNotifier staleNotifier = const NoopStaleQueueNotifier(),
    AppLogger? logger,
    Uuid? uuid,
  })  : _db = db,
        _drive = drive,
        _staleNotifier = staleNotifier,
        _log = logger ?? const AppLogger('upload'),
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final DriveClient _drive;
  final StaleQueueNotifier _staleNotifier;
  final AppLogger _log;
  final Uuid _uuid;

  // recordingId 単位の直列化ロック（同一録音への並行 Drive 操作禁止・§7.3）。
  final Map<String, Future<void>> _locks = {};

  // 認証エラー時の全体一時停止（§7.5）。
  bool _paused = false;
  final StreamController<bool> _needsReauthCtrl =
      StreamController<bool>.broadcast();

  // flush の再入防止と、実行中の追加要求フラグ。
  bool _flushing = false;
  bool _rerun = false;

  // 次回バックオフ再開用タイマ。
  Timer? _retryTimer;
  DateTime? _retryTimerFireAt;

  // ネット復帰イベント購読。
  StreamSubscription<bool>? _connectivitySub;

  bool _disposed = false;

  String get _nowIso => DateTime.now().toIso8601String();

  /// 認証エラーで一時停止中か（再サインイン誘導バナー用）。
  bool get needsReauth => _paused;

  /// 一時停止状態の変化ストリーム（true=再サインインが必要）。
  Stream<bool> get needsReauthStream => _needsReauthCtrl.stream;

  // ---------------------------------------------------------------------------
  // ジョブ投入（enqueue）
  // ---------------------------------------------------------------------------

  /// 録音停止直後に音声アップロードジョブを投入する（高優先度）。
  Future<void> enqueueAudio(String recordingId) =>
      _enqueue(recordingId, UploadJobKind.audio);

  /// 文字起こし .txt のアップロードジョブを投入する（低優先度・§7.2）。
  Future<void> enqueueTranscript(String recordingId) =>
      _enqueue(recordingId, UploadJobKind.transcript);

  Future<void> _enqueue(String recordingId, UploadJobKind kind) async {
    final existing =
        await _db.uploadJobsDao.getByRecordingAndKind(recordingId, kind);
    // 既に完了しているジョブは再投入しない（二重アップロード防止・§7.3）。
    if (existing != null && existing.state == UploadJobState.done) {
      return;
    }
    if (existing == null) {
      await _db.uploadJobsDao.upsertJob(
        UploadJobsCompanion.insert(
          id: _uuid.v4(),
          recordingId: recordingId,
          kind: kind,
          state: const Value(UploadJobState.pending),
          createdAt: _nowIso,
          updatedAt: _nowIso,
        ),
      );
    } else {
      // 失敗・中断していたジョブは pending へ戻し、id は据え置き（冪等）。
      await _db.uploadJobsDao.updateJob(
        existing.id,
        const UploadJobsCompanion(
          state: Value(UploadJobState.pending),
          nextRetryAt: Value(null),
        ),
      );
    }
    await _projectRecordingState(recordingId);
  }

  // ---------------------------------------------------------------------------
  // トリガ
  // ---------------------------------------------------------------------------

  /// 録音停止直後の即時アップロード（FG 中の最速経路・§7.6）。
  Future<void> uploadNow(String recordingId) async {
    await enqueueAudio(recordingId);
    await flush();
  }

  /// 実行可能な pending ジョブ（audio 優先・nextRetryAt 到来分）を順に処理する。
  ///
  /// FG 復帰時 / ネット復帰時 / 起動時リカバリから呼ばれる。
  Future<void> flush() async {
    if (_disposed || _paused) return;
    if (_flushing) {
      _rerun = true;
      return;
    }
    _flushing = true;
    try {
      do {
        _rerun = false;
        final runnable = await _db.uploadJobsDao.watchRunnable().first;
        for (final job in runnable) {
          if (_paused || _disposed) break;
          final outcome = await _processJob(job);
          if (outcome == JobOutcome.pausedAuth) break;
        }
      } while (_rerun && !_paused && !_disposed);
    } finally {
      _flushing = false;
    }
    await _armRetryTimer();
  }

  /// ネット復帰イベントストリームを購読し、復帰時に自動 flush する。
  ///
  /// [onlineEvents] は「オンラインになったら true」を流すストリーム
  /// （プレゼンテーション層が connectivity_plus をここへ橋渡しする）。
  void attachConnectivity(Stream<bool> onlineEvents) {
    _connectivitySub?.cancel();
    _connectivitySub = onlineEvents.listen((online) {
      if (online) {
        unawaited(flush());
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 認証エラー時の一時停止 / 再開（§7.5）
  // ---------------------------------------------------------------------------

  /// 再サインイン成功後にキューを再開する。
  Future<void> resumeAfterSignIn() async {
    if (!_paused) return;
    _paused = false;
    if (!_needsReauthCtrl.isClosed) _needsReauthCtrl.add(false);
    await flush();
  }

  Future<void> _pauseForAuth(UploadJob job, Recording rec) async {
    _paused = true;
    if (!_needsReauthCtrl.isClosed) _needsReauthCtrl.add(true);
    // ジョブは pending に戻して保持（再サインインで自動再開・§7.5）。
    await _updateJobAndProject(
      job.id,
      rec.id,
      const UploadJobsCompanion(state: Value(UploadJobState.pending)),
    );
  }

  // ---------------------------------------------------------------------------
  // 手動再試行（要対応バッジからのアクション・§7.5）
  // ---------------------------------------------------------------------------

  /// 指定録音の失敗ジョブ（retryable / permanent）を pending に戻して再試行する。
  Future<void> retry(String recordingId) async {
    final jobs = await _db.uploadJobsDao.getByRecording(recordingId);
    for (final job in jobs) {
      if (job.state == UploadJobState.permanentFailed ||
          job.state == UploadJobState.retryableFailed) {
        await _db.uploadJobsDao.updateJob(
          job.id,
          const UploadJobsCompanion(
            state: Value(UploadJobState.pending),
            retryCount: Value(0),
            nextRetryAt: Value(null),
            lastError: Value(null),
          ),
        );
      }
    }
    await _projectRecordingState(recordingId);
    await flush();
  }

  /// 恒久失敗ジョブ全件を再試行する（例: Drive 容量を空けた後の一括再開）。
  Future<void> retryAllPermanentFailed() async {
    final failed = await _db.uploadJobsDao.watchPermanentFailed().first;
    final recordingIds = <String>{};
    for (final job in failed) {
      await _db.uploadJobsDao.updateJob(
        job.id,
        const UploadJobsCompanion(
          state: Value(UploadJobState.pending),
          retryCount: Value(0),
          nextRetryAt: Value(null),
          lastError: Value(null),
        ),
      );
      recordingIds.add(job.recordingId);
    }
    for (final id in recordingIds) {
      await _projectRecordingState(id);
    }
    await flush();
  }

  // ---------------------------------------------------------------------------
  // 起動時リカバリ（§12 の 3）
  // ---------------------------------------------------------------------------

  /// 起動時: `uploading` で中断したジョブを `pending` へ戻し、射影を整合させ、
  /// nextRetryAt 経過分を含めて flush する。
  Future<void> recoverOnStartup() async {
    await _db.uploadJobsDao.resetStuckUploading();
    // 中断ジョブを持っていた録音のバッジ（uploading）を pending へ整合。
    final outstanding = await _db.uploadJobsDao.watchOutstanding().first;
    final recordingIds = outstanding.map((j) => j.recordingId).toSet();
    for (final id in recordingIds) {
      await _projectRecordingState(id);
    }
    await flush();
  }

  // ---------------------------------------------------------------------------
  // 滞留通知（§7.6）
  // ---------------------------------------------------------------------------

  /// 24 時間以上滞留している未アップロードがあればローカル通知する。
  Future<void> checkStaleQueue({DateTime? now}) async {
    final outstanding = await _db.uploadJobsDao.watchOutstanding().first;
    if (outstanding.isEmpty) return;
    final threshold =
        (now ?? DateTime.now()).subtract(AppConstants.staleQueueNotifyThreshold);
    final hasStale = outstanding.any((j) {
      final created = DateTime.tryParse(j.createdAt);
      return created != null && created.isBefore(threshold);
    });
    if (hasStale) {
      await _staleNotifier.notifyStale(outstanding.length);
    }
  }

  // ---------------------------------------------------------------------------
  // fileId 基準の改名・削除の Drive 反映（UI から呼ばれる・§7.3）
  // ---------------------------------------------------------------------------

  /// 録音タイトルを変更し、音声・txt を Drive 上でもペアで改名する。
  ///
  /// 命名の日時プレフィックスは不変。タイトル部のみが変わる（§11）。
  /// 同一録音への操作は直列化される。
  Future<void> renameRecording(String recordingId, String newTitle) {
    return _synchronized(recordingId, () async {
      final rec = await _db.recordingsDao.getById(recordingId);
      if (rec == null) return;
      final clean = Naming.sanitizeTitle(newTitle);
      final startedAt = DateTime.parse(rec.startedAt);
      await _db.recordingsDao.updateRecording(
        recordingId,
        RecordingsCompanion(title: Value(clean)),
      );
      if (rec.driveFileId != null) {
        await _drive.renameFile(
          rec.driveFileId!,
          Naming.audioFileName(startedAt, rec.codec, title: clean),
        );
      }
      if (rec.txtDriveFileId != null) {
        await _drive.renameFile(
          rec.txtDriveFileId!,
          Naming.txtFileName(startedAt, title: clean),
        );
      }
    });
  }

  /// 録音を削除する。[deleteFromDrive]=true なら Drive 上の音声・txt も削除する。
  ///
  /// [deleteLocal]=true ならローカルファイルも削除する。DB 行は削除し、
  /// FK cascade で関連ジョブも消える。同一録音への操作は直列化される。
  Future<void> deleteRecording(
    String recordingId, {
    bool deleteFromDrive = false,
    bool deleteLocal = true,
  }) {
    return _synchronized(recordingId, () async {
      final rec = await _db.recordingsDao.getById(recordingId);
      if (rec == null) return;
      if (deleteFromDrive) {
        if (rec.driveFileId != null) {
          await _drive.deleteFile(rec.driveFileId!);
        }
        if (rec.txtDriveFileId != null) {
          await _drive.deleteFile(rec.txtDriveFileId!);
        }
      }
      if (deleteLocal) {
        await _tryDeleteLocal(rec.localPath);
        await _tryDeleteLocal(rec.transcriptLocalPath);
      }
      await _db.recordingsDao.deleteRecording(recordingId);
    });
  }

  Future<void> _tryDeleteLocal(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      _log.error('localDelete', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 1 ジョブの処理（状態機械の中核）
  // ---------------------------------------------------------------------------

  Future<JobOutcome> _processJob(UploadJob job) async {
    final rec = await _db.recordingsDao.getById(job.recordingId);
    if (rec == null) {
      // 親録音が消えている → ジョブ破棄。
      await _db.uploadJobsDao.deleteJob(job.id);
      return JobOutcome.skipped;
    }
    return _synchronized(job.recordingId, () => _doUpload(job, rec));
  }

  Future<JobOutcome> _doUpload(UploadJob job, Recording rec) async {
    // 直列化待ちの間に一時停止された場合は何もしない。
    if (_paused) return JobOutcome.skipped;

    // uploading へ遷移（射影も同一トランザクションで）。
    await _updateJobAndProject(
      job.id,
      rec.id,
      const UploadJobsCompanion(state: Value(UploadJobState.uploading)),
    );

    final vrId = rec.id;
    final vrKind = job.kind.name; // 'audio' / 'transcript'

    try {
      // 冪等: 試行前に既存検索 → あれば fileId 回収して done（新規作成しない・§7.3）。
      final existingId = await _drive.findByVrId(vrId, vrKind);
      if (existingId != null) {
        await _completeJob(job, rec, existingId);
        return JobOutcome.done;
      }

      // アップロード対象ローカルファイル。
      final path =
          job.kind == UploadJobKind.audio ? rec.localPath : rec.transcriptLocalPath;
      if (path == null) {
        await _failPermanent(job, rec, 'localFileMissing');
        return JobOutcome.permanent;
      }
      final file = File(path);
      if (!await file.exists()) {
        await _failPermanent(job, rec, 'localFileMissing');
        return JobOutcome.permanent;
      }

      final startedAt = DateTime.parse(rec.startedAt);

      // 年-月フォルダ fileId を解決（解決済みならキャッシュを再利用）。
      var folderId = job.driveFolderId;
      if (folderId == null) {
        folderId = await _drive.ensureDateFolder(startedAt);
        await _db.uploadJobsDao.updateJob(
          job.id,
          UploadJobsCompanion(driveFolderId: Value(folderId)),
        );
      }

      final fileName = job.kind == UploadJobKind.audio
          ? Naming.audioFileName(startedAt, rec.codec, title: rec.title)
          : Naming.txtFileName(startedAt, title: rec.title);
      final mimeType = _mimeFor(job.kind, rec.codec);
      final sizeBytes = await file.length();

      // resumable セッション URI を解決（未取得なら開始し、永続化して再開に備える）。
      var sessionUri = job.resumableUri;
      if (sessionUri == null) {
        sessionUri = await _drive.startResumableSession(
          parentFolderId: folderId,
          fileName: fileName,
          mimeType: mimeType,
          sizeBytes: sizeBytes,
          vrId: vrId,
          vrKind: vrKind,
        );
        await _db.uploadJobsDao.updateJob(
          job.id,
          UploadJobsCompanion(resumableUri: Value(sessionUri)),
        );
      }

      final driveFile = await _drive.uploadResumable(
        sessionUri: sessionUri,
        file: file,
        mimeType: mimeType,
      );
      await _completeJob(job, rec, driveFile.id);
      return JobOutcome.done;
    } on DriveAuthException catch (e) {
      _log.error('driveAuth', recordingId: rec.id, error: e);
      await _pauseForAuth(job, rec);
      return JobOutcome.pausedAuth;
    } on DriveException catch (e) {
      if (e.isRetryable) {
        await _scheduleRetry(job, rec, e, 'driveTransient');
        return JobOutcome.retryable;
      }
      // DriveFolderMissingException / DriveQuotaException 等 → 恒久失敗。
      final category =
          e is DriveFolderMissingException ? 'driveFolderMissing' : 'driveQuota';
      _log.error(category, recordingId: rec.id, error: e);
      await _failPermanent(job, rec, category);
      return JobOutcome.permanent;
    } catch (e) {
      // 未分類の例外はデータ保全を優先し一時エラー扱い（再試行）。
      await _scheduleRetry(job, rec, e, 'unknownTransient');
      return JobOutcome.retryable;
    }
  }

  // ---------------------------------------------------------------------------
  // 遷移ヘルパ（ジョブ更新と recordings 射影を同一トランザクションで）
  // ---------------------------------------------------------------------------

  Future<void> _completeJob(UploadJob job, Recording rec, String fileId) {
    return _db.transaction(() async {
      await _db.uploadJobsDao.updateJob(
        job.id,
        const UploadJobsCompanion(
          state: Value(UploadJobState.done),
          lastError: Value(null),
        ),
      );
      // 成功時に fileId を保存（以後の改名・削除・txt 紐付けは fileId 基準）。
      if (job.kind == UploadJobKind.audio) {
        await _db.recordingsDao.updateRecording(
          rec.id,
          RecordingsCompanion(driveFileId: Value(fileId)),
        );
      } else {
        await _db.recordingsDao.updateRecording(
          rec.id,
          RecordingsCompanion(txtDriveFileId: Value(fileId)),
        );
      }
      await _projectRecordingStateInTxn(rec.id);
    });
  }

  Future<void> _scheduleRetry(
    UploadJob job,
    Recording rec,
    Object error,
    String category,
  ) async {
    final newCount = job.retryCount + 1;
    final next = nextRetryAt(newCount);
    _log.error(category, recordingId: rec.id, error: error);
    await _updateJobAndProject(
      job.id,
      rec.id,
      UploadJobsCompanion(
        state: const Value(UploadJobState.retryableFailed),
        retryCount: Value(newCount),
        nextRetryAt: Value(next.toIso8601String()),
        lastError: Value(category),
      ),
    );
    await _armRetryTimer();
  }

  Future<void> _failPermanent(UploadJob job, Recording rec, String category) {
    return _updateJobAndProject(
      job.id,
      rec.id,
      UploadJobsCompanion(
        state: const Value(UploadJobState.permanentFailed),
        lastError: Value(category),
      ),
    );
  }

  Future<void> _updateJobAndProject(
    String jobId,
    String recordingId,
    UploadJobsCompanion jobUpdate,
  ) {
    return _db.transaction(() async {
      await _db.uploadJobsDao.updateJob(jobId, jobUpdate);
      await _projectRecordingStateInTxn(recordingId);
    });
  }

  Future<void> _projectRecordingState(String recordingId) {
    return _db.transaction(() => _projectRecordingStateInTxn(recordingId));
  }

  Future<void> _projectRecordingStateInTxn(String recordingId) async {
    final jobs = await _db.uploadJobsDao.getByRecording(recordingId);
    final projected = _projectFrom(jobs);
    if (projected != null) {
      await _db.recordingsDao.updateUploadState(recordingId, projected);
    }
  }

  /// ジョブ集合から recordings.uploadState を導出する（§7.5 の射影）。
  ///
  /// 音声ジョブを主とする（文字起こしはベストエフォート・§設計原則6）。
  /// 音声ジョブが無ければ transcript ジョブで代替する。
  UploadState? _projectFrom(List<UploadJob> jobs) {
    if (jobs.isEmpty) return null;
    UploadJob? governing;
    for (final j in jobs) {
      if (j.kind == UploadJobKind.audio) {
        governing = j;
        break;
      }
    }
    governing ??= jobs.first;
    return switch (governing.state) {
      UploadJobState.pending => UploadState.pending,
      UploadJobState.retryableFailed => UploadState.pending,
      UploadJobState.uploading => UploadState.uploading,
      UploadJobState.done => UploadState.done,
      UploadJobState.permanentFailed => UploadState.actionRequired,
    };
  }

  String _mimeFor(UploadJobKind kind, Codec codec) {
    if (kind == UploadJobKind.transcript) return 'text/plain';
    return switch (codec) {
      Codec.aacM4a => 'audio/mp4',
      Codec.oggOpus => 'audio/ogg',
    };
  }

  // ---------------------------------------------------------------------------
  // バックオフ再開タイマ
  // ---------------------------------------------------------------------------

  Future<void> _armRetryTimer() async {
    if (_disposed || _paused) return;
    final outstanding = await _db.uploadJobsDao.watchOutstanding().first;
    DateTime? soonest;
    for (final j in outstanding) {
      if (j.state != UploadJobState.retryableFailed) continue;
      final at = j.nextRetryAt == null ? null : DateTime.tryParse(j.nextRetryAt!);
      if (at == null) continue;
      if (soonest == null || at.isBefore(soonest)) soonest = at;
    }
    if (soonest == null) return;
    final delay = soonest.difference(DateTime.now());
    final fireAt = soonest;
    // 既に到来済みなら即 flush。
    if (delay.isNegative || delay == Duration.zero) {
      unawaited(flush());
      return;
    }
    // 既存タイマがより早ければ据え置き。
    if (_retryTimer != null &&
        _retryTimerFireAt != null &&
        !fireAt.isBefore(_retryTimerFireAt!)) {
      return;
    }
    _retryTimer?.cancel();
    _retryTimerFireAt = fireAt;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      _retryTimerFireAt = null;
      unawaited(flush());
    });
  }

  // ---------------------------------------------------------------------------
  // recordingId 単位の直列化
  // ---------------------------------------------------------------------------

  Future<T> _synchronized<T>(String key, Future<T> Function() action) {
    final prev = _locks[key] ?? Future<void>.value();
    final completer = Completer<void>();
    _locks[key] = completer.future;
    Future<T> run() async {
      try {
        return await action();
      } finally {
        completer.complete();
        if (identical(_locks[key], completer.future)) {
          _locks.remove(key);
        }
      }
    }

    return prev.then((_) => run());
  }

  // ---------------------------------------------------------------------------
  // 破棄
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _connectivitySub?.cancel();
    if (!_needsReauthCtrl.isClosed) await _needsReauthCtrl.close();
  }
}
