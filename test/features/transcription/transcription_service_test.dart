import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/constants.dart';
import 'package:voicerecorder/core/database/app_database.dart';
import 'package:voicerecorder/core/database/tables.dart';
import 'package:voicerecorder/features/transcription/application/transcription_engine_registry.dart';
import 'package:voicerecorder/features/transcription/application/transcription_service.dart';
import 'package:voicerecorder/features/transcription/domain/transcription_engine.dart';

/// スクリプト化した [BatchTranscriptionEngine] の Fake。
/// watch() で `events` を順に emit する。各種モードで異常系を再現する。
class FakeBatchEngine implements BatchTranscriptionEngine {
  FakeBatchEngine({
    this.events = const [],
    this.available = true,
    this.maxFileSizeBytes = AppConstants.sttMaxFileSizeBytes,
    this.acceptedFormats = const {'m4a', 'opus'},
    this.throwOnWatch = false,
    this.engineIdValue = 'fake',
  });

  final List<TranscriptionEvent> events;
  final bool available;
  final int? maxFileSizeBytes;
  final Set<String> acceptedFormats;
  final bool throwOnWatch;
  final String engineIdValue;

  final List<String> submitted = [];
  final List<String> watched = [];

  @override
  String get id => engineIdValue;

  @override
  String get displayName => 'Fake';

  @override
  EngineCapability get capability => EngineCapability(
        audioInputMode: AudioInputMode.file,
        acceptedFormats: acceptedFormats,
        maxFileSizeBytes: maxFileSizeBytes,
        languageMode: LanguageMode.fixedList,
      );

  @override
  Future<EngineAvailability> checkAvailability({String? localeId}) async =>
      EngineAvailability(available, available ? null : 'offline');

  @override
  Future<List<String>> supportedLocales() async => const ['ja-JP', 'en-US'];

  @override
  Future<String> submit(File audio, {String? localeId}) async {
    submitted.add(audio.path);
    return '{"filePath":"${audio.path}","localeId":${localeId == null ? 'null' : '"$localeId"'}}';
  }

  @override
  Stream<TranscriptionEvent> watch(String jobHandle) async* {
    watched.add(jobHandle);
    if (throwOnWatch) {
      throw StateError('boom');
    }
    for (final e in events) {
      yield e;
    }
  }

  @override
  Future<void> cancel(String jobHandle) async {}
}

void main() {
  late AppDatabase db;
  late Directory tmpDir;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    tmpDir = await Directory.systemTemp.createTemp('vr_txt_test');
  });

  tearDown(() async {
    await db.close();
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  Future<String> seedRecording({int audioBytes = 1024}) async {
    final id = 'rec-1';
    final now = DateTime.now().toIso8601String();
    final audioFile = File('${tmpDir.path}/audio.m4a');
    await audioFile.writeAsBytes(List<int>.filled(audioBytes, 0));
    await db.recordingsDao.insertRecording(
      RecordingsCompanion.insert(
        id: id,
        startedAt: '2026-07-04T14:30:05+09:00',
        codec: Codec.aacM4a,
        createdAt: now,
        updatedAt: now,
        localPath: Value(audioFile.path),
      ),
    );
    return id;
  }

  TranscriptionService buildService(FakeBatchEngine engine) {
    final registry = TranscriptionEngineRegistry(
      {engine.id: engine},
      defaultEngineId: engine.id,
    );
    return TranscriptionService(
      db: db,
      registry: registry,
      transcriptDir: () async => tmpDir,
      clock: () => DateTime(2026, 7, 4, 14, 30, 5),
    );
  }

  test('Completed: done へ射影・txt 生成・transcript upload_job 投入', () async {
    final id = await seedRecording();
    final engine = FakeBatchEngine(
      events: const [
        TranscriptionProgress(null),
        TranscriptionCompleted('hello world'),
      ],
    );
    final service = buildService(engine);

    await service.transcribe(id, engineId: engine.id);

    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.done);
    expect(rec.transcriptLocalPath, isNotNull);
    expect(await File(rec.transcriptLocalPath!).readAsString(), 'hello world');

    final jobs = await db.transcriptionJobsDao.getByRecording(id);
    expect(jobs.single.state, TranscriptionJobState.done);
    expect(jobs.single.jobHandle, isNotNull);

    final upload =
        await db.uploadJobsDao.getByRecordingAndKind(id, UploadJobKind.transcript);
    expect(upload, isNotNull);
    expect(upload!.state, UploadJobState.pending);
  });

  test('Failed+partialText: partial へ射影・部分 txt 保存・upload 投入', () async {
    final id = await seedRecording();
    final engine = FakeBatchEngine(
      events: const [
        TranscriptionFailed('timeout',
            isRetryable: true, partialText: 'half text'),
      ],
    );
    final service = buildService(engine);

    await service.transcribe(id, engineId: engine.id);

    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.partial);
    expect(await File(rec.transcriptLocalPath!).readAsString(), 'half text');

    final job = (await db.transcriptionJobsDao.getByRecording(id)).single;
    expect(job.state, TranscriptionJobState.partial);
    expect(job.lastError, 'timeout');

    final upload =
        await db.uploadJobsDao.getByRecordingAndKind(id, UploadJobKind.transcript);
    expect(upload, isNotNull);
  });

  test('Failed(部分なし): failed へ射影・upload_job は作らない', () async {
    final id = await seedRecording();
    final engine = FakeBatchEngine(
      events: const [
        TranscriptionFailed('authFailed', isRetryable: false),
      ],
    );
    final service = buildService(engine);

    await service.transcribe(id, engineId: engine.id);

    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.failed);
    expect(rec.transcriptLocalPath, isNull);

    final job = (await db.transcriptionJobsDao.getByRecording(id)).single;
    expect(job.state, TranscriptionJobState.failed);

    final upload =
        await db.uploadJobsDao.getByRecordingAndKind(id, UploadJobKind.transcript);
    expect(upload, isNull);
  });

  test('capability: 最大サイズ超過は failed・ジョブを作らない', () async {
    final id = await seedRecording(audioBytes: 2048);
    final engine = FakeBatchEngine(
      // 実ファイル(2048B)より小さい上限で「超過」を再現。
      maxFileSizeBytes: 512,
      events: const [TranscriptionCompleted('should not run')],
    );
    final service = buildService(engine);

    await service.transcribe(id, engineId: engine.id);

    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.failed);
    expect(engine.submitted, isEmpty); // submit まで到達しない
    expect(await db.transcriptionJobsDao.getByRecording(id), isEmpty);
    expect(
      await db.uploadJobsDao.getByRecordingAndKind(id, UploadJobKind.transcript),
      isNull,
    );
  });

  test('capability: 非対応フォーマットは failed', () async {
    final id = await seedRecording();
    final engine = FakeBatchEngine(
      acceptedFormats: const {'wav'}, // m4a を受け付けない
      events: const [TranscriptionCompleted('x')],
    );
    final service = buildService(engine);

    await service.transcribe(id, engineId: engine.id);

    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.failed);
    expect(engine.submitted, isEmpty);
  });

  test('録音優先: watch が例外を投げても呼び出し元へ伝播しない', () async {
    final id = await seedRecording();
    final engine = FakeBatchEngine(throwOnWatch: true);
    final service = buildService(engine);

    // 例外が飛ばないこと（throwsA でなく正常完了）。
    await expectLater(
      service.transcribe(id, engineId: engine.id),
      completes,
    );

    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.failed);
  });

  test('engine 未解決（登録簿が空）でも例外を投げず failed 射影', () async {
    final id = await seedRecording();
    final registry = TranscriptionEngineRegistry(const {});
    final service = TranscriptionService(
      db: db,
      registry: registry,
      transcriptDir: () async => tmpDir,
    );

    await expectLater(
      service.transcribe(id, engineId: 'nope'),
      completes,
    );
    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.failed);
  });

  test('resumePendingJobs: submitted ジョブを再購読して完走させる', () async {
    final id = await seedRecording();
    final now = DateTime.now().toIso8601String();
    // submitted 状態のジョブを手で仕込む（前回起動で submit 済みの想定）。
    await db.transcriptionJobsDao.insertJob(
      TranscriptionJobsCompanion(
        id: const Value('job-1'),
        recordingId: Value(id),
        engineId: const Value('fake'),
        state: const Value(TranscriptionJobState.submitted),
        jobHandle: Value('{"filePath":"${tmpDir.path}/audio.m4a"}'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.recordingsDao
        .updateTranscriptState(id, TranscriptState.processing);

    final engine = FakeBatchEngine(
      events: const [TranscriptionCompleted('resumed text')],
    );
    final registry = TranscriptionEngineRegistry(
      {engine.id: engine},
      defaultEngineId: engine.id,
    );
    final service = TranscriptionService(
      db: db,
      registry: registry,
      transcriptDir: () async => tmpDir,
    );

    await service.resumePendingJobs();

    expect(engine.watched, isNotEmpty);
    final rec = await db.recordingsDao.getById(id);
    expect(rec!.transcriptState, TranscriptState.done);
    expect(await File(rec.transcriptLocalPath!).readAsString(), 'resumed text');
    final job = await db.transcriptionJobsDao.getById('job-1');
    expect(job!.state, TranscriptionJobState.done);
  });
}
