// drift の isNull/isNotNull は matcher と名前衝突するため隠す（テストでは matcher 側を使う）。
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/database/app_database.dart';
import 'package:voicerecorder/core/database/tables.dart';

/// テスト用の録音行を組み立てる。
RecordingsCompanion _recording(String id, {String startedAt = '2026-07-04T14:30:05+09:00'}) {
  final now = DateTime.now().toIso8601String();
  return RecordingsCompanion.insert(
    id: id,
    startedAt: startedAt,
    codec: Codec.aacM4a,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('RecordingsDao CRUD', () {
    test('挿入・取得できる', () async {
      await db.recordingsDao.insertRecording(_recording('r1'));
      final row = await db.recordingsDao.getById('r1');
      expect(row, isNotNull);
      expect(row!.uploadState, UploadState.pending);
      expect(row.transcriptState, TranscriptState.off);
      expect(row.codec, Codec.aacM4a);
    });

    test('状態バッジを更新できる', () async {
      await db.recordingsDao.insertRecording(_recording('r1'));
      await db.recordingsDao.updateUploadState('r1', UploadState.done);
      await db.recordingsDao.updateTranscriptState('r1', TranscriptState.done);
      final row = await db.recordingsDao.getById('r1');
      expect(row!.uploadState, UploadState.done);
      expect(row.transcriptState, TranscriptState.done);
    });

    test('削除できる', () async {
      await db.recordingsDao.insertRecording(_recording('r1'));
      await db.recordingsDao.deleteRecording('r1');
      expect(await db.recordingsDao.getById('r1'), isNull);
    });

    test('逼迫時削除候補はアップ済み・ローカルあり・古い順のみ', () async {
      // 未アップ（除外）
      await db.recordingsDao.insertRecording(_recording('r_pending', startedAt: '2026-07-01T10:00:00+09:00'));
      await db.recordingsDao.updateRecording('r_pending',
          const RecordingsCompanion(localPath: Value('/tmp/a.m4a')));
      // アップ済み・ローカルあり（対象・古い）
      await db.recordingsDao.insertRecording(_recording('r_old', startedAt: '2026-07-02T10:00:00+09:00'));
      await db.recordingsDao.updateRecording('r_old',
          const RecordingsCompanion(
              uploadState: Value(UploadState.done), localPath: Value('/tmp/b.m4a')));
      // アップ済み・ローカルあり（対象・新しい）
      await db.recordingsDao.insertRecording(_recording('r_new', startedAt: '2026-07-03T10:00:00+09:00'));
      await db.recordingsDao.updateRecording('r_new',
          const RecordingsCompanion(
              uploadState: Value(UploadState.done), localPath: Value('/tmp/c.m4a')));
      // アップ済みだがローカル削除済み（除外）
      await db.recordingsDao.insertRecording(_recording('r_gone', startedAt: '2026-07-04T10:00:00+09:00'));
      await db.recordingsDao.updateRecording('r_gone',
          const RecordingsCompanion(uploadState: Value(UploadState.done)));

      final reclaimable = await db.recordingsDao.getReclaimableOldestFirst();
      expect(reclaimable.map((e) => e.id).toList(), ['r_old', 'r_new']);
    });

    test('watchAll は挿入・更新に追従する', () async {
      final stream = db.recordingsDao.watchAll();
      final emissions = <List<Recording>>[];
      final sub = stream.listen(emissions.add);

      await db.recordingsDao.insertRecording(_recording('r1'));
      await db.recordingsDao.insertRecording(_recording('r2', startedAt: '2026-07-05T09:00:00+09:00'));
      // ストリームが反映されるまで待つ。
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final last = emissions.last;
      expect(last.length, 2);
      // 新しい順（r2 が先）。
      expect(last.first.id, 'r2');
    });
  });

  group('UploadJobsDao', () {
    setUp(() async {
      await db.recordingsDao.insertRecording(_recording('r1'));
    });

    UploadJobsCompanion job(String id, UploadJobKind kind, {UploadJobState state = UploadJobState.pending}) {
      final now = DateTime.now().toIso8601String();
      return UploadJobsCompanion.insert(
        id: id,
        recordingId: 'r1',
        kind: kind,
        state: Value(state),
        createdAt: now,
        updatedAt: now,
      );
    }

    test('UNIQUE(recordingId, kind) で upsert される', () async {
      await db.uploadJobsDao.upsertJob(job('j1', UploadJobKind.audio));
      // 同一 (r1, audio) を再投入 → 既存を更新（新規行は作らない）。
      await db.uploadJobsDao.upsertJob(job('j1', UploadJobKind.audio, state: UploadJobState.uploading));
      final all = await db.uploadJobsDao.getByRecording('r1');
      expect(all.length, 1);
      expect(all.single.state, UploadJobState.uploading);
    });

    test('watchRunnable は audio を transcript より優先', () async {
      await db.uploadJobsDao.upsertJob(job('j_txt', UploadJobKind.transcript));
      await db.uploadJobsDao.upsertJob(job('j_audio', UploadJobKind.audio));
      final runnable = await db.uploadJobsDao.watchRunnable().first;
      expect(runnable.first.kind, UploadJobKind.audio);
    });

    test('resetStuckUploading は uploading を pending に戻す', () async {
      await db.uploadJobsDao.upsertJob(job('j1', UploadJobKind.audio, state: UploadJobState.uploading));
      final count = await db.uploadJobsDao.resetStuckUploading();
      expect(count, 1);
      final j = await db.uploadJobsDao.getByRecordingAndKind('r1', UploadJobKind.audio);
      expect(j!.state, UploadJobState.pending);
    });

    test('FK cascade: 録音削除でジョブも消える', () async {
      await db.uploadJobsDao.upsertJob(job('j1', UploadJobKind.audio));
      await db.recordingsDao.deleteRecording('r1');
      expect(await db.uploadJobsDao.getByRecording('r1'), isEmpty);
    });
  });

  group('TranscriptionJobsDao', () {
    setUp(() async {
      await db.recordingsDao.insertRecording(_recording('r1'));
    });

    test('getResumable は submitted/running のみ返す', () async {
      final now = DateTime.now().toIso8601String();
      await db.transcriptionJobsDao.insertJob(TranscriptionJobsCompanion.insert(
        id: 't_queued', recordingId: 'r1', engineId: 'cloud_stt',
        state: const Value(TranscriptionJobState.queued), createdAt: now, updatedAt: now,
      ));
      await db.transcriptionJobsDao.insertJob(TranscriptionJobsCompanion.insert(
        id: 't_sub', recordingId: 'r1', engineId: 'cloud_stt',
        state: const Value(TranscriptionJobState.submitted), createdAt: now, updatedAt: now,
      ));
      final resumable = await db.transcriptionJobsDao.getResumable();
      expect(resumable.map((e) => e.id), ['t_sub']);
    });

    test('markSubmitted で jobHandle 保存＋submitted 遷移', () async {
      final now = DateTime.now().toIso8601String();
      await db.transcriptionJobsDao.insertJob(TranscriptionJobsCompanion.insert(
        id: 't1', recordingId: 'r1', engineId: 'cloud_stt', createdAt: now, updatedAt: now,
      ));
      await db.transcriptionJobsDao.markSubmitted('t1', '{"remoteId":"abc"}');
      final j = await db.transcriptionJobsDao.getById('t1');
      expect(j!.state, TranscriptionJobState.submitted);
      expect(j.jobHandle, '{"remoteId":"abc"}');
    });
  });

  group('SettingsDao', () {
    test('set/get/watch/remove', () async {
      expect(await db.settingsDao.getValue('k'), isNull);
      await db.settingsDao.setValue('k', 'v1');
      expect(await db.settingsDao.getValue('k'), 'v1');
      await db.settingsDao.setValue('k', 'v2');
      expect(await db.settingsDao.getValue('k'), 'v2');
      await db.settingsDao.removeValue('k');
      expect(await db.settingsDao.getValue('k'), isNull);
    });
  });
}
