import 'dart:collection';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/database/app_database.dart';
import 'package:voicerecorder/core/database/tables.dart';
import 'package:voicerecorder/core/drive/drive_client.dart';
import 'package:voicerecorder/features/upload/domain/upload_queue.dart';

/// 設定可能な DriveClient のフェイク。
///
/// - [existing] に (vrId/vrKind→fileId) を仕込むと findByVrId が回収する。
/// - [uploadOutcomes] に例外 or fileId(String) を積むと uploadResumable が順に消費。
///   尽きたら 'drive_N' を生成して成功扱い。
class FakeDriveClient implements DriveClient {
  final Map<String, String> existing = {};
  final Queue<Object> uploadOutcomes = Queue<Object>();
  Object? ensureDateFolderBehavior; // DriveException を入れると throw
  String folderId = 'folder_2026_07';

  int findCalls = 0;
  int startSessionCalls = 0;
  int uploadCalls = 0;
  int ensureFolderCalls = 0;
  final List<String> startedSessionUris = [];
  final List<(String, String)> renames = [];
  final List<String> deletes = [];

  @override
  Future<String> ensureRootFolder() async => 'root';

  @override
  Future<String> ensureDateFolder(DateTime startedAt) async {
    ensureFolderCalls++;
    final b = ensureDateFolderBehavior;
    if (b is DriveException) throw b;
    return folderId;
  }

  @override
  Future<String> startResumableSession({
    required String parentFolderId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String vrId,
    required String vrKind,
  }) async {
    startSessionCalls++;
    final uri = 'session://$vrKind/$startSessionCalls';
    startedSessionUris.add(uri);
    return uri;
  }

  @override
  Future<DriveFile> uploadResumable({
    required String sessionUri,
    required File file,
    required String mimeType,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    uploadCalls++;
    final outcome =
        uploadOutcomes.isNotEmpty ? uploadOutcomes.removeFirst() : 'drive_$uploadCalls';
    if (outcome is DriveException) throw outcome;
    return DriveFile(id: outcome as String, name: 'f');
  }

  @override
  Future<String?> findByVrId(String vrId, String vrKind) async {
    findCalls++;
    return existing['$vrId/$vrKind'];
  }

  @override
  Future<void> renameFile(String fileId, String newName) async =>
      renames.add((fileId, newName));

  @override
  Future<void> deleteFile(String fileId) async => deletes.add(fileId);

  @override
  Future<void> downloadFile(String fileId, String localPath) async {}

  @override
  Future<DriveFile> updateFileContent(String fileId,
          {required File content, required String mimeType}) async =>
      DriveFile(id: fileId, name: 'f');
}

void main() {
  late AppDatabase db;
  late FakeDriveClient drive;
  late UploadQueue queue;
  late Directory tmp;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    drive = FakeDriveClient();
    queue = UploadQueue(db: db, drive: drive);
    tmp = await Directory.systemTemp.createTemp('vr_upload_test');
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<String> makeAudio(String id) async {
    final f = File('${tmp.path}/$id.m4a');
    await f.writeAsBytes(List<int>.filled(64, 1));
    return f.path;
  }

  Future<void> insertRecording(String id, {String? localPath}) async {
    final now = DateTime.now().toIso8601String();
    await db.recordingsDao.insertRecording(
      RecordingsCompanion.insert(
        id: id,
        startedAt: '2026-07-04T14:30:05+09:00',
        codec: Codec.aacM4a,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (localPath != null) {
      await db.recordingsDao.setLocalPath(id, localPath);
    }
  }

  Future<UploadJob?> audioJob(String recordingId) =>
      db.uploadJobsDao.getByRecordingAndKind(recordingId, UploadJobKind.audio);

  group('冪等・二重ジョブ防止', () {
    test('enqueue を二度呼んでもジョブは 1 つ', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      await queue.enqueueAudio('r1');
      await queue.enqueueAudio('r1');
      final jobs = await db.uploadJobsDao.getByRecording('r1');
      expect(jobs.length, 1);
    });

    test('done 済みジョブは enqueue で復活しない', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      await queue.enqueueAudio('r1');
      final j = await audioJob('r1');
      await db.uploadJobsDao.updateState(j!.id, UploadJobState.done);
      await queue.enqueueAudio('r1');
      final jobs = await db.uploadJobsDao.getByRecording('r1');
      expect(jobs.length, 1);
      expect(jobs.single.state, UploadJobState.done);
    });

    test('findByVrId で既存回収 → uploadResumable を呼ばず done', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      drive.existing['r1/audio'] = 'already_on_drive';
      await queue.uploadNow('r1');

      final j = await audioJob('r1');
      expect(j!.state, UploadJobState.done);
      expect(drive.uploadCalls, 0);
      expect(drive.startSessionCalls, 0);
      final rec = await db.recordingsDao.getById('r1');
      expect(rec!.driveFileId, 'already_on_drive');
      expect(rec.uploadState, UploadState.done);
    });
  });

  group('状態機械', () {
    test('正常系: pending→uploading→done、fileId 保存＆射影 done', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      drive.uploadOutcomes.add('drive_r1');
      await queue.uploadNow('r1');

      final j = await audioJob('r1');
      expect(j!.state, UploadJobState.done);
      final rec = await db.recordingsDao.getById('r1');
      expect(rec!.driveFileId, 'drive_r1');
      expect(rec.uploadState, UploadState.done);
      expect(drive.startSessionCalls, 1);
      expect(drive.uploadCalls, 1);
    });

    test('一時エラー→バックオフ→再試行で成功（resumable セッション再利用）', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      // 1 回目 transient、2 回目成功。
      drive.uploadOutcomes.add(const DriveTransientException('5xx', 503));
      drive.uploadOutcomes.add('drive_r1');
      await queue.uploadNow('r1');

      var j = await audioJob('r1');
      expect(j!.state, UploadJobState.retryableFailed);
      expect(j.retryCount, 1);
      expect(j.nextRetryAt, isNotNull);
      expect(j.resumableUri, isNotNull); // セッションは永続化済み
      expect((await db.recordingsDao.getById('r1'))!.uploadState,
          UploadState.pending);

      // 手動再試行（バックオフ経過相当）→ 成功。
      await queue.retry('r1');
      j = await audioJob('r1');
      expect(j!.state, UploadJobState.done);
      expect((await db.recordingsDao.getById('r1'))!.driveFileId, 'drive_r1');
      // セッションは 1 回だけ開始され、2 回目の upload で再利用された。
      expect(drive.startSessionCalls, 1);
      expect(drive.uploadCalls, 2);
    });

    test('恒久エラー（Quota）→ permanentFailed／射影 actionRequired', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      drive.uploadOutcomes.add(const DriveQuotaException());
      await queue.uploadNow('r1');

      final j = await audioJob('r1');
      expect(j!.state, UploadJobState.permanentFailed);
      expect(j.lastError, 'driveQuota');
      expect((await db.recordingsDao.getById('r1'))!.uploadState,
          UploadState.actionRequired);
    });

    test('フォルダ削除（FolderMissing）→ permanentFailed', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      drive.ensureDateFolderBehavior = const DriveFolderMissingException();
      await queue.uploadNow('r1');

      final j = await audioJob('r1');
      expect(j!.state, UploadJobState.permanentFailed);
      expect(j.lastError, 'driveFolderMissing');
      expect((await db.recordingsDao.getById('r1'))!.uploadState,
          UploadState.actionRequired);
    });

    test('ローカルファイル欠落かつ Drive 未存在 → permanentFailed', () async {
      await insertRecording('r1', localPath: '/nonexistent/gone.m4a');
      await queue.uploadNow('r1');
      final j = await audioJob('r1');
      expect(j!.state, UploadJobState.permanentFailed);
      expect(j.lastError, 'localFileMissing');
      expect(drive.uploadCalls, 0);
    });
  });

  group('認証エラーによる一時停止と再開', () {
    test('auth エラーでキュー一時停止・ジョブは pending 保持・再開で成功', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      drive.uploadOutcomes.add(const DriveAuthException());
      drive.uploadOutcomes.add('drive_r1'); // 再開後の成功

      await queue.uploadNow('r1');

      expect(queue.needsReauth, isTrue);
      var j = await audioJob('r1');
      // ジョブは pending へ戻して保持（permanentFailed にしない）。
      expect(j!.state, UploadJobState.pending);
      expect((await db.recordingsDao.getById('r1'))!.uploadState,
          UploadState.pending);

      // 一時停止中は flush が何もしない。
      await queue.flush();
      expect(drive.uploadCalls, 1);

      // 再サインイン成功 → 自動再開。
      await queue.resumeAfterSignIn();
      expect(queue.needsReauth, isFalse);
      j = await audioJob('r1');
      expect(j!.state, UploadJobState.done);
      expect((await db.recordingsDao.getById('r1'))!.driveFileId, 'drive_r1');
    });
  });

  group('優先度・複数ジョブ', () {
    test('audio が transcript より先に処理される', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      final txtPath = File('${tmp.path}/r1.txt');
      await txtPath.writeAsString('hello');
      await db.recordingsDao.updateRecording(
        'r1',
        RecordingsCompanion(transcriptLocalPath: Value(txtPath.path)),
      );
      await queue.enqueueTranscript('r1');
      await queue.enqueueAudio('r1');
      await queue.flush();

      final audio = await audioJob('r1');
      final txt = await db.uploadJobsDao
          .getByRecordingAndKind('r1', UploadJobKind.transcript);
      expect(audio!.state, UploadJobState.done);
      expect(txt!.state, UploadJobState.done);
      final rec = await db.recordingsDao.getById('r1');
      // 射影は音声ジョブ主導。両方 done。
      expect(rec!.uploadState, UploadState.done);
      expect(rec.driveFileId, isNotNull);
      expect(rec.txtDriveFileId, isNotNull);
    });
  });

  group('起動時リカバリ', () {
    test('uploading 中断分を pending に戻して再開する', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      final now = DateTime.now().toIso8601String();
      await db.uploadJobsDao.upsertJob(UploadJobsCompanion.insert(
        id: 'j1',
        recordingId: 'r1',
        kind: UploadJobKind.audio,
        state: const Value(UploadJobState.uploading),
        createdAt: now,
        updatedAt: now,
      ));
      drive.uploadOutcomes.add('drive_r1');

      await queue.recoverOnStartup();

      final j = await audioJob('r1');
      expect(j!.state, UploadJobState.done);
      expect((await db.recordingsDao.getById('r1'))!.uploadState,
          UploadState.done);
    });
  });

  group('fileId 基準の改名・削除の Drive 反映', () {
    test('renameRecording は音声と txt をペアで改名しタイトルを更新', () async {
      await insertRecording('r1', localPath: await makeAudio('r1'));
      await db.recordingsDao.updateRecording(
        'r1',
        const RecordingsCompanion(
          driveFileId: Value('audio_fid'),
          txtDriveFileId: Value('txt_fid'),
        ),
      );
      await queue.renameRecording('r1', '経営会議 Q3');

      expect(drive.renames.length, 2);
      expect(drive.renames[0].$1, 'audio_fid');
      expect(drive.renames[0].$2, endsWith('_経営会議 Q3.m4a'));
      expect(drive.renames[1].$1, 'txt_fid');
      expect(drive.renames[1].$2, endsWith('_経営会議 Q3.txt'));
      expect((await db.recordingsDao.getById('r1'))!.title, '経営会議 Q3');
    });

    test('deleteRecording(deleteFromDrive:true) は Drive の音声・txt を削除し行も消す',
        () async {
      final path = await makeAudio('r1');
      await insertRecording('r1', localPath: path);
      await db.recordingsDao.updateRecording(
        'r1',
        const RecordingsCompanion(
          driveFileId: Value('audio_fid'),
          txtDriveFileId: Value('txt_fid'),
        ),
      );
      await queue.deleteRecording('r1', deleteFromDrive: true);

      expect(drive.deletes, containsAll(['audio_fid', 'txt_fid']));
      expect(File(path).existsSync(), isFalse);
      expect(await db.recordingsDao.getById('r1'), isNull);
    });

    test('deleteRecording(deleteFromDrive:false) は Drive を触らない', () async {
      final path = await makeAudio('r1');
      await insertRecording('r1', localPath: path);
      await db.recordingsDao.updateRecording(
        'r1',
        const RecordingsCompanion(driveFileId: Value('audio_fid')),
      );
      await queue.deleteRecording('r1', deleteFromDrive: false);
      expect(drive.deletes, isEmpty);
      expect(await db.recordingsDao.getById('r1'), isNull);
    });
  });
}
