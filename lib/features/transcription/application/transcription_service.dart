import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/naming/naming.dart';
import '../../../core/security/app_logger.dart';
import '../domain/transcription_engine.dart';
import '../engines/cloud_stt_engine.dart';
import 'transcription_engine_registry.dart';

/// 録音単位の（再）文字起こしを司るドメインサービス（DESIGN.md §8.3）。
///
/// Riverpod 非依存。BG isolate（workmanager / foreground_task）からも直接使用できる。
///
/// 不変条件（CLAUDE.md 原則 6「録音優先／文字起こしベストエフォート」）:
/// - 文字起こしの失敗・例外は決して呼び出し元（録音停止処理）へ伝播させない。
///   全経路を内部で捕捉し、状態は DB（single source of truth）へ射影するだけ。
class TranscriptionService {
  TranscriptionService({
    required AppDatabase db,
    required TranscriptionEngineRegistry registry,
    Future<Directory> Function()? transcriptDir,
    Uuid? uuid,
    DateTime Function()? clock,
    AppLogger? logger,
  })  : _db = db,
        _registry = registry,
        _transcriptDir = transcriptDir ?? getApplicationSupportDirectory,
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now,
        _log = logger ?? const AppLogger('transcription');

  final AppDatabase _db;
  final TranscriptionEngineRegistry _registry;
  final Future<Directory> Function() _transcriptDir;
  final Uuid _uuid;
  final DateTime Function() _clock;
  final AppLogger _log;

  /// 新規 / 失敗後リトライ / エンジン切替後の再実行、いずれもこの 1 本で扱う。
  ///
  /// 例外は内部で握りつぶす（録音優先）。状態は DB へ射影する。
  Future<void> transcribe(String recordingId, {String? engineId}) async {
    try {
      await _run(recordingId, engineId: engineId);
    } catch (e) {
      // ここへ来ても呼び出し元へは伝播させない。失敗として射影だけ残す。
      _log.error('transcribe', recordingId: recordingId, error: e);
      await _safeMarkFailed(recordingId);
    }
  }

  /// 起動時: submitted / running のジョブを列挙し [BatchTranscriptionEngine.watch]
  /// で再購読する（DESIGN.md §5.3 / §12）。
  Future<void> resumePendingJobs() async {
    try {
      final jobs = await _db.transcriptionJobsDao.getResumable();
      for (final job in jobs) {
        try {
          final handle = job.jobHandle;
          if (handle == null || handle.isEmpty) continue;
          final engine = _registry.engine(job.engineId);
          if (engine is! BatchTranscriptionEngine) continue;
          final recording = await _db.recordingsDao.getById(job.recordingId);
          if (recording == null) continue;
          await _consume(job.id, recording, engine, handle);
        } catch (e) {
          _log.error('resumeJob', recordingId: job.recordingId, error: e);
        }
      }
    } catch (e) {
      _log.error('resumePendingJobs', error: e);
    }
  }

  // -------------------------------------------------------------------------
  // 内部実装
  // -------------------------------------------------------------------------

  Future<void> _run(String recordingId, {String? engineId}) async {
    final recording = await _db.recordingsDao.getById(recordingId);
    if (recording == null) {
      _log.warning('transcribe: recording not found');
      return;
    }

    // 1) Registry でエンジン解決。
    final resolvedId = engineId ??
        await _db.settingsDao.getValue(SettingsKeys.transcriptionEngineId) ??
        CloudSttEngine.engineId;
    final engine = _registry.resolve(resolvedId);
    if (engine is! BatchTranscriptionEngine) {
      _log.error('engineUnavailable', recordingId: recordingId);
      await _markFailed(recordingId);
      return;
    }

    final localeId =
        await _db.settingsDao.getValue(SettingsKeys.transcriptionLocaleId);

    // 2) checkAvailability()（ネット / API キー / 言語対応）。
    final availability = await engine.checkAvailability(localeId: localeId);
    if (!availability.available) {
      _log.warning('transcribe: engine unavailable');
      await _markFailed(recordingId);
      return;
    }

    // 3) capability 検証（フォーマット・サイズ）。超過は failed。
    final localPath = recording.localPath;
    if (localPath == null) {
      // ローカル実体が無い（逼迫時削除済み等）。文字起こし不能。
      await _markFailed(recordingId);
      return;
    }
    final audio = File(localPath);
    final capability = engine.capability;

    final ext = Naming.extensionForCodec(recording.codec);
    if (capability.audioInputMode == AudioInputMode.file &&
        capability.acceptedFormats.isNotEmpty &&
        !capability.acceptedFormats.contains(ext)) {
      _log.warning('transcribe: unsupported format');
      await _markFailed(recordingId);
      return;
    }

    final maxBytes = capability.maxFileSizeBytes;
    if (maxBytes != null) {
      final length = await audio.exists() ? await audio.length() : 0;
      if (length == 0) {
        await _markFailed(recordingId);
        return;
      }
      if (length > maxBytes) {
        _log.warning('transcribe: file too large');
        await _markFailed(recordingId);
        return;
      }
    }

    // 4) transcription_jobs INSERT(queued)＋ recordings.transcriptState=processing。
    final jobId = _uuid.v4();
    final now = _clock().toIso8601String();
    await _db.transaction(() async {
      await _db.transcriptionJobsDao.insertJob(
        TranscriptionJobsCompanion(
          id: Value(jobId),
          recordingId: Value(recordingId),
          engineId: Value(engine.id),
          state: const Value(TranscriptionJobState.queued),
          localeId: Value(localeId),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _db.recordingsDao
          .updateTranscriptState(recordingId, TranscriptState.processing);
    });

    // 5) submit() → jobHandle 永続化(submitted)。
    final handle = await engine.submit(audio, localeId: localeId);
    await _db.transcriptionJobsDao.markSubmitted(jobId, handle);

    // 6) watch() 購読 → イベントを DB へ反映。
    await _consume(jobId, recording, engine, handle);
  }

  /// [BatchTranscriptionEngine.watch] を購読し、各イベントを DB へ射影する。
  /// transcribe（新規）と resumePendingJobs（再購読）の共通経路。
  Future<void> _consume(
    String jobId,
    Recording recording,
    BatchTranscriptionEngine engine,
    String handle,
  ) async {
    final startedAt = DateTime.parse(recording.startedAt);
    var movedToRunning = false;

    await for (final event in engine.watch(handle)) {
      if (event is TranscriptionCompleted) {
        await _persistText(
          jobId: jobId,
          recording: recording,
          startedAt: startedAt,
          text: event.fullText,
          transcriptState: TranscriptState.done,
          jobState: TranscriptionJobState.done,
        );
        return;
      }

      if (event is TranscriptionFailed) {
        final partial = event.partialText;
        if (partial != null && partial.isNotEmpty) {
          // 部分成功: 得られた分を txt 保存・アップし「一部のみ」へ。
          await _persistText(
            jobId: jobId,
            recording: recording,
            startedAt: startedAt,
            text: partial,
            transcriptState: TranscriptState.partial,
            jobState: TranscriptionJobState.partial,
            lastError: event.reason,
          );
        } else {
          await _persistFailure(jobId, recording.id, event.reason);
        }
        return;
      }

      // TranscriptionProgress / TranscriptionPartial(暫定) → running へ一度だけ遷移。
      if (!movedToRunning) {
        movedToRunning = true;
        await _db.transaction(() async {
          await _db.transcriptionJobsDao
              .updateState(jobId, TranscriptionJobState.running);
          await _db.recordingsDao
              .updateTranscriptState(recording.id, TranscriptState.processing);
        });
      }
    }
    // ストリームが terminal イベント無しで閉じた場合は何も射影しない
    // （queued/submitted/running のまま。起動時 resume の対象として残る）。
  }

  /// Completed / 部分成功で txt をローカル生成し、job・recording・upload_job を
  /// 同一トランザクションで射影する。
  Future<void> _persistText({
    required String jobId,
    required Recording recording,
    required DateTime startedAt,
    required String text,
    required TranscriptState transcriptState,
    required TranscriptionJobState jobState,
    String? lastError,
  }) async {
    // ファイル生成（IO）はトランザクション外で先に行う。
    final dir = await _transcriptDir();
    final fileName = Naming.txtFileName(startedAt, title: recording.title);
    final txtPath = '${dir.path}${Platform.pathSeparator}$fileName';
    await File(txtPath).writeAsString(text);

    final now = _clock().toIso8601String();
    // txtDriveFileId が既にある場合、upload 側は fileId 維持で updateFileContent
    // する想定。ここでは kind=transcript の upsert（UNIQUE(recordingId,kind)）で
    // 同一の 1 ジョブへ集約し、recording.txtDriveFileId を判断材料として残す。
    await _db.transaction(() async {
      await _db.transcriptionJobsDao.updateJob(
        jobId,
        TranscriptionJobsCompanion(
          state: Value(jobState),
          lastError: Value(lastError),
        ),
      );
      await _db.recordingsDao.updateRecording(
        recording.id,
        RecordingsCompanion(
          transcriptLocalPath: Value(txtPath),
          transcriptState: Value(transcriptState),
        ),
      );
      await _db.uploadJobsDao.upsertJob(
        UploadJobsCompanion(
          id: Value(_uuid.v4()),
          recordingId: Value(recording.id),
          kind: const Value(UploadJobKind.transcript),
          state: const Value(UploadJobState.pending),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// 完全失敗の射影（部分成功分なし）。
  Future<void> _persistFailure(
    String jobId,
    String recordingId,
    String reason,
  ) async {
    await _db.transaction(() async {
      await _db.transcriptionJobsDao.updateJob(
        jobId,
        TranscriptionJobsCompanion(
          state: const Value(TranscriptionJobState.failed),
          lastError: Value(reason),
        ),
      );
      await _db.recordingsDao
          .updateTranscriptState(recordingId, TranscriptState.failed);
    });
  }

  Future<void> _markFailed(String recordingId) =>
      _db.recordingsDao.updateTranscriptState(recordingId, TranscriptState.failed);

  Future<void> _safeMarkFailed(String recordingId) async {
    try {
      await _markFailed(recordingId);
    } catch (e) {
      _log.error('markFailed', recordingId: recordingId, error: e);
    }
  }
}
