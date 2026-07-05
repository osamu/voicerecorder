import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voicerecorder/core/database/app_database.dart';
import 'package:voicerecorder/core/database/tables.dart';
import 'package:voicerecorder/core/security/secure_storage.dart';
import 'package:voicerecorder/features/auth/domain/auth_service.dart';

/// メモリ上の [SecureStore] スタブ（flutter_secure_storage を使わない）。
class _InMemorySecureStore implements SecureStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<bool> contains(String key) async => _data.containsKey(key);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedRecordingWithJob(String id, UploadJobState state) async {
    final now = DateTime.now().toIso8601String();
    await db.recordingsDao.insertRecording(RecordingsCompanion.insert(
      id: id,
      startedAt: '2026-07-04T14:30:05+09:00',
      codec: Codec.aacM4a,
      createdAt: now,
      updatedAt: now,
    ));
    await db.uploadJobsDao.upsertJob(UploadJobsCompanion.insert(
      id: 'job-$id',
      recordingId: id,
      kind: UploadJobKind.audio,
      createdAt: now,
      updatedAt: now,
      state: Value(state),
    ));
  }

  test('unuploadedCount は pending/retryableFailed を数える', () async {
    await seedRecordingWithJob('r1', UploadJobState.pending);
    await seedRecordingWithJob('r2', UploadJobState.retryableFailed);
    await seedRecordingWithJob('r3', UploadJobState.done); // 除外

    final service = AuthService(
      secureStore: _InMemorySecureStore(),
      uploadJobsDao: db.uploadJobsDao,
    );
    addTearDown(service.dispose);

    expect(await service.unuploadedCount(), 2);
  });

  test('revokeToken は revoke エンドポイントへトークンを送る', () async {
    http.Request? captured;
    final revokeClient = MockClient((request) async {
      captured = request;
      return http.Response('', 200);
    });

    final service = AuthService(
      secureStore: _InMemorySecureStore(),
      uploadJobsDao: db.uploadJobsDao,
      revokeClient: revokeClient,
    );
    addTearDown(service.dispose);

    await service.revokeToken('access-token-123');

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.host, 'oauth2.googleapis.com');
    expect(captured!.url.path, '/revoke');
    // application/x-www-form-urlencoded の body にトークンが含まれる。
    expect(captured!.bodyFields['token'], 'access-token-123');
  });

  test('revoke が失敗しても例外を投げない（ベストエフォート）', () async {
    final revokeClient = MockClient((request) async {
      return http.Response('error', 500);
    });
    final service = AuthService(
      secureStore: _InMemorySecureStore(),
      uploadJobsDao: db.uploadJobsDao,
      revokeClient: revokeClient,
    );
    addTearDown(service.dispose);

    // 例外を投げずに完了すること。
    await service.revokeToken('t');
  });
}
