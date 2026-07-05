import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voicerecorder/core/database/app_database.dart';
import 'package:voicerecorder/core/drive/drive_client.dart';
import 'package:voicerecorder/core/drive/google_drive_client.dart';

/// 1 リクエストの記録（アサーション用）。
class _Call {
  _Call(this.method, this.request);
  final String method;
  final http.Request request;
  String get path => request.url.path;
  String? get q => request.url.queryParameters['q'];
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// [handler] で応答を組み立てつつ、全リクエストを [calls] に記録する
  /// [GoogleDriveClient] を作る。
  GoogleDriveClient buildClient(
    List<_Call> calls,
    Future<http.Response> Function(_Call call) handler,
  ) {
    final mock = MockClient((request) async {
      final call = _Call(request.method, request);
      calls.add(call);
      return handler(call);
    });
    return GoogleDriveClient(
      clientProvider: () async => mock,
      settingsDao: db.settingsDao,
    );
  }

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'});

  group('ensureRootFolder', () {
    test('既存フォルダを検索でヒットしたら作成せず fileId を返す', () async {
      final calls = <_Call>[];
      final client = buildClient(calls, (call) async {
        if (call.method == 'GET') {
          return json({
            'files': [
              {'id': 'root-1', 'name': 'VoiceRecorder'}
            ]
          });
        }
        return http.Response('unexpected', 500);
      });

      final id = await client.ensureRootFolder();

      expect(id, 'root-1');
      // POST（create）が発生していないこと。
      expect(calls.where((c) => c.method == 'POST'), isEmpty);
      // settings に保存されること。
      expect(await db.settingsDao.getValue(SettingsKeys.driveRootFolderId),
          'root-1');
    });

    test('未存在なら作成し、2 回目は重複作成しない（冪等）', () async {
      final calls = <_Call>[];
      var created = false;
      final client = buildClient(calls, (call) async {
        // キャッシュ済み id のメタデータ取得（GET /files/root-new）。
        if (call.method == 'GET' && call.path.endsWith('/root-new')) {
          return json({'id': 'root-new', 'trashed': false});
        }
        // フォルダ検索（GET /files?q=...）。
        if (call.method == 'GET') {
          return json({'files': <Object>[]});
        }
        // 作成。
        if (call.method == 'POST') {
          created = true;
          return json({'id': 'root-new'});
        }
        return http.Response('unexpected', 500);
      });

      final first = await client.ensureRootFolder();
      expect(first, 'root-new');
      expect(created, isTrue);

      // 2 回目: settings にキャッシュがあるのでメタデータ確認のみ、作成しない。
      final createsAfter = calls.where((c) => c.method == 'POST').length;
      final second = await client.ensureRootFolder();
      expect(second, 'root-new');
      expect(calls.where((c) => c.method == 'POST').length, createsAfter,
          reason: '2 回目は作成 POST を発行しない');
    });

    test('キャッシュ済みルートが trashed なら DriveFolderMissingException', () async {
      await db.settingsDao
          .setValue(SettingsKeys.driveRootFolderId, 'root-trashed');
      final client = buildClient(<_Call>[], (call) async {
        if (call.method == 'GET' && call.path.endsWith('/root-trashed')) {
          return json({'id': 'root-trashed', 'trashed': true});
        }
        return http.Response('unexpected', 500);
      });

      await expectLater(
        client.ensureRootFolder(),
        throwsA(isA<DriveFolderMissingException>()),
      );
    });
  });

  group('ensureDateFolder', () {
    test('年・月フォルダを get-or-create し月フォルダ id を返す', () async {
      await db.settingsDao.setValue(SettingsKeys.driveRootFolderId, 'root-1');
      final calls = <_Call>[];
      final client = buildClient(calls, (call) async {
        if (call.method == 'GET' && call.path.endsWith('/root-1')) {
          return json({'id': 'root-1', 'trashed': false});
        }
        if (call.method == 'GET') {
          // 年・月とも未存在。
          return json({'files': <Object>[]});
        }
        if (call.method == 'POST') {
          final body =
              jsonDecode(call.request.body) as Map<String, dynamic>;
          final props = body['appProperties'] as Map<String, dynamic>;
          final pathKey = props['vrFolderPath'] as String;
          // パスキーで年/月を判定して別 id を返す。
          final id = pathKey.endsWith('2026-07') ? 'month-1' : 'year-1';
          return json({'id': id});
        }
        return http.Response('unexpected', 500);
      });

      final startedAt = DateTime(2026, 7, 4, 14, 30, 5);
      final id = await client.ensureDateFolder(startedAt);

      expect(id, 'month-1');
      // 2 つのフォルダが作成される（年・月）。
      final creates = calls.where((c) => c.method == 'POST').toList();
      expect(creates.length, 2);
      // 月フォルダの親は年フォルダ。
      final monthBody =
          jsonDecode(creates.last.request.body) as Map<String, dynamic>;
      expect((monthBody['parents'] as List).first, 'year-1');
      expect((monthBody['appProperties'] as Map)['vrFolderPath'],
          'VoiceRecorder/2026/2026-07');
    });
  });

  group('エラー分類', () {
    test('401 → DriveAuthException', () async {
      final client = buildClient(<_Call>[],
          (call) async => http.Response('{"error":{}}', 401));
      await expectLater(
        client.ensureRootFolder(),
        throwsA(isA<DriveAuthException>()),
      );
    });

    test('403 quota → DriveQuotaException', () async {
      final client = buildClient(<_Call>[], (call) async {
        return http.Response(
          '{"error":{"errors":[{"reason":"storageQuotaExceeded"}]}}',
          403,
        );
      });
      await expectLater(
        client.findByVrId('uuid-1', 'audio'),
        throwsA(isA<DriveQuotaException>()),
      );
    });

    test('500 → DriveTransientException（isRetryable）', () async {
      final client = buildClient(
          <_Call>[], (call) async => http.Response('boom', 500));
      await expectLater(
        client.findByVrId('uuid-1', 'audio'),
        throwsA(isA<DriveTransientException>()
            .having((e) => e.isRetryable, 'isRetryable', isTrue)),
      );
    });
  });

  group('findByVrId', () {
    test('appProperties クエリで fileId を返す', () async {
      final calls = <_Call>[];
      final client = buildClient(calls, (call) async {
        return json({
          'files': [
            {'id': 'file-9'}
          ]
        });
      });
      final id = await client.findByVrId('uuid-1', 'audio');
      expect(id, 'file-9');
      expect(calls.single.q, contains("value='uuid-1'"));
      expect(calls.single.q, contains("value='audio'"));
    });

    test('未ヒットは null', () async {
      final client =
          buildClient(<_Call>[], (call) async => json({'files': <Object>[]}));
      expect(await client.findByVrId('uuid-x', 'audio'), isNull);
    });
  });

  group('deleteFile', () {
    test('404（既に削除済み）は冪等に成功扱い', () async {
      final client = buildClient(
          <_Call>[], (call) async => http.Response('', 404));
      await client.deleteFile('gone'); // 例外を投げない。
    });
  });

  group('resumable upload', () {
    test('セッション開始→チャンク送信で完了メタデータを返す', () async {
      final tmp = await File(
              '${Directory.systemTemp.path}/vr_upload_${DateTime.now().microsecondsSinceEpoch}.bin')
          .create();
      await tmp.writeAsBytes(List<int>.generate(5, (i) => i));
      addTearDown(() async {
        if (tmp.existsSync()) await tmp.delete();
      });

      final calls = <_Call>[];
      final client = buildClient(calls, (call) async {
        // セッション開始（POST uploadType=resumable）。
        if (call.method == 'POST') {
          return http.Response('', 200,
              headers: {'location': 'https://upload.example/session-1'});
        }
        // resumable PUT。
        if (call.method == 'PUT') {
          final range = call.request.headers['content-range'] ?? '';
          if (range.contains('*/')) {
            // オフセット問い合わせ: 未受信 → 308（range ヘッダ無し）。
            return http.Response('', 308);
          }
          // チャンク受信 → 完了メタデータ。
          return json({'id': 'up-1', 'name': 'a.m4a', 'size': '5'});
        }
        return http.Response('unexpected', 500);
      });

      final session = await client.startResumableSession(
        parentFolderId: 'month-1',
        fileName: 'a.m4a',
        mimeType: 'audio/mp4',
        sizeBytes: 5,
        vrId: 'uuid-1',
        vrKind: 'audio',
      );
      expect(session, 'https://upload.example/session-1');

      final progress = <int>[];
      final result = await client.uploadResumable(
        sessionUri: session,
        file: tmp,
        mimeType: 'audio/mp4',
        onProgress: (sent, total) => progress.add(sent),
      );

      expect(result.id, 'up-1');
      expect(result.sizeBytes, 5);
      expect(progress.last, 5);
    });
  });
}
