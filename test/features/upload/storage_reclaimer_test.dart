import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/database/app_database.dart';
import 'package:voicerecorder/core/database/tables.dart';
import 'package:voicerecorder/features/upload/domain/storage_reclaimer.dart';
import 'package:voicerecorder/features/upload/domain/upload_ports.dart';

class _FakeProbe implements DeviceStorageProbe {
  _FakeProbe(this.free);
  int free;
  @override
  Future<int> freeBytes() async => free;
}

const int _mb = 1024 * 1024;

void main() {
  late AppDatabase db;
  late Directory tmp;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    tmp = await Directory.systemTemp.createTemp('vr_reclaim_test');
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<String> makeFile(String name) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes(List<int>.filled(16, 0));
    return f.path;
  }

  Future<void> insertReclaimable(
    String id, {
    required String startedAt,
    required UploadState uploadState,
    String? localPath,
    int sizeBytes = 200 * _mb,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.recordingsDao.insertRecording(
      RecordingsCompanion.insert(
        id: id,
        startedAt: startedAt,
        codec: Codec.aacM4a,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.recordingsDao.updateRecording(
      id,
      RecordingsCompanion(
        uploadState: Value(uploadState),
        localPath: Value(localPath),
        sizeBytes: Value(sizeBytes),
      ),
    );
  }

  test('空き十分なら何もしない', () async {
    await insertReclaimable('r1',
        startedAt: '2026-07-01T10:00:00+09:00',
        uploadState: UploadState.done,
        localPath: await makeFile('r1.m4a'));
    final reclaimer = StorageReclaimer(
      db: db,
      storage: _FakeProbe(1000 * _mb), // 閾値 500MB 以上
    );
    expect(await reclaimer.reclaimIfNeeded(), 0);
    final row = await db.recordingsDao.getById('r1');
    expect(row!.localPath, isNotNull);
  });

  test('逼迫時: アップ済み・古い順のみ削除し localPath を NULL 化。未アップは絶対に消さない',
      () async {
    // アップ済み・ローカルあり（対象・古い順に old1<old2<old3）。各 200MB。
    final old1 = await makeFile('old1.m4a');
    final old2 = await makeFile('old2.m4a');
    final old3 = await makeFile('old3.m4a');
    await insertReclaimable('old1',
        startedAt: '2026-07-01T10:00:00+09:00',
        uploadState: UploadState.done,
        localPath: old1);
    await insertReclaimable('old2',
        startedAt: '2026-07-02T10:00:00+09:00',
        uploadState: UploadState.done,
        localPath: old2);
    await insertReclaimable('old3',
        startedAt: '2026-07-03T10:00:00+09:00',
        uploadState: UploadState.done,
        localPath: old3);
    // 未アップ（pending）・ローカルあり → 絶対に削除しない。
    final pendingPath = await makeFile('pending.m4a');
    await insertReclaimable('pend',
        startedAt: '2026-06-01T10:00:00+09:00', // 最古だが未アップ
        uploadState: UploadState.pending,
        localPath: pendingPath);

    // 空き 100MB。閾値 500MB。200MB を 2 件回収すれば 500MB に到達し停止。
    final reclaimer = StorageReclaimer(db: db, storage: _FakeProbe(100 * _mb));
    final count = await reclaimer.reclaimIfNeeded();

    expect(count, 2);
    // old1 / old2 は削除され localPath=NULL、ファイル実体も消える。
    expect((await db.recordingsDao.getById('old1'))!.localPath, isNull);
    expect((await db.recordingsDao.getById('old2'))!.localPath, isNull);
    expect(File(old1).existsSync(), isFalse);
    expect(File(old2).existsSync(), isFalse);
    // old3 は閾値到達で対象外。localPath 維持・実体維持。
    expect((await db.recordingsDao.getById('old3'))!.localPath, isNotNull);
    expect(File(old3).existsSync(), isTrue);
    // 未アップは最古でも絶対に削除しない。
    expect((await db.recordingsDao.getById('pend'))!.localPath, isNotNull);
    expect(File(pendingPath).existsSync(), isTrue);
  });

  test('削除に失敗しても他候補の処理を続ける', () async {
    // 実体の無いパスを持たせて delete を失敗させる（default delete は exists 判定で
    // スキップされるため、ここでは常に投げる deleteFile を注入する）。
    await insertReclaimable('bad',
        startedAt: '2026-07-01T10:00:00+09:00',
        uploadState: UploadState.done,
        localPath: '/nonexistent/bad.m4a',
        sizeBytes: 10 * _mb);
    final okPath = await makeFile('ok.m4a');
    await insertReclaimable('ok',
        startedAt: '2026-07-02T10:00:00+09:00',
        uploadState: UploadState.done,
        localPath: okPath,
        sizeBytes: 10 * _mb);

    var calls = 0;
    final reclaimer = StorageReclaimer(
      db: db,
      storage: _FakeProbe(0),
      deleteFile: (path) async {
        calls++;
        if (path.contains('bad')) throw const FileSystemException('boom');
      },
    );
    final count = await reclaimer.reclaimIfNeeded();
    // bad は失敗しスキップ、ok は成功。両方試行される。
    expect(calls, 2);
    expect(count, 1);
    expect((await db.recordingsDao.getById('bad'))!.localPath, isNotNull);
    expect((await db.recordingsDao.getById('ok'))!.localPath, isNull);
  });
}
