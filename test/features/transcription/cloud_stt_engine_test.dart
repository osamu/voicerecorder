import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voicerecorder/core/security/secure_storage.dart';
import 'package:voicerecorder/features/transcription/domain/transcription_engine.dart';
import 'package:voicerecorder/features/transcription/engines/cloud_stt_engine.dart';

/// read だけ差し替える SecureStore（プラグイン非依存）。
class _FakeSecureStore extends SecureStore {
  _FakeSecureStore(this._data) : super();
  final Map<String, String?> _data;
  @override
  Future<String?> read(String key) async => _data[key];
}

void main() {
  late Directory tmpDir;
  late File audio;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('vr_cloud_stt');
    audio = File('${tmpDir.path}/a.m4a');
    await audio.writeAsBytes(List<int>.filled(64, 1));
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  CloudSttEngine engineWith(
    MockClient client, {
    Map<String, String?> secrets = const {SecureKeys.sttApiKey: 'sk-test'},
  }) {
    return CloudSttEngine(
      secureStore: _FakeSecureStore(secrets),
      httpClient: client,
      isOnline: () async => true,
    );
  }

  Future<List<TranscriptionEvent>> runWatch(CloudSttEngine engine) async {
    final handle = await engine.submit(audio, localeId: 'ja-JP');
    return engine.watch(handle).toList();
  }

  test('capability は file / {m4a,opus} / 25MB / fixedList', () {
    final cap = CloudSttEngine().capability;
    expect(cap.audioInputMode, AudioInputMode.file);
    expect(cap.acceptedFormats, {'m4a', 'opus'});
    expect(cap.maxFileSizeBytes, 25 * 1024 * 1024);
    expect(cap.languageMode, LanguageMode.fixedList);
  });

  test('200: Completed に全文が入る', () async {
    final engine = engineWith(
      MockClient((_) async => http.Response('transcribed text', 200)),
    );
    final events = await runWatch(engine);
    expect(events.last, isA<TranscriptionCompleted>());
    expect((events.last as TranscriptionCompleted).fullText, 'transcribed text');
  });

  test('401: 恒久失敗（isRetryable=false）', () async {
    final engine = engineWith(MockClient((_) async => http.Response('no', 401)));
    final events = await runWatch(engine);
    final failed = events.last as TranscriptionFailed;
    expect(failed.isRetryable, isFalse);
    expect(failed.reason, 'authFailed');
  });

  test('413: 恒久失敗（サイズ超過）', () async {
    final engine = engineWith(MockClient((_) async => http.Response('big', 413)));
    final failed = (await runWatch(engine)).last as TranscriptionFailed;
    expect(failed.isRetryable, isFalse);
    expect(failed.reason, 'fileTooLarge');
  });

  test('429: 一時失敗（isRetryable=true）', () async {
    final engine = engineWith(MockClient((_) async => http.Response('slow', 429)));
    final failed = (await runWatch(engine)).last as TranscriptionFailed;
    expect(failed.isRetryable, isTrue);
  });

  test('500: 一時失敗（isRetryable=true）', () async {
    final engine = engineWith(MockClient((_) async => http.Response('err', 500)));
    final failed = (await runWatch(engine)).last as TranscriptionFailed;
    expect(failed.isRetryable, isTrue);
    expect(failed.reason, 'serverError');
  });

  test('ネットワーク例外: 一時失敗', () async {
    final engine = engineWith(
      MockClient((_) async => throw const SocketException('down')),
    );
    final failed = (await runWatch(engine)).last as TranscriptionFailed;
    expect(failed.isRetryable, isTrue);
    expect(failed.reason, 'network');
  });

  test('API キー未設定: 恒久失敗 apiKeyMissing', () async {
    final engine = engineWith(
      MockClient((_) async => http.Response('x', 200)),
      secrets: const {},
    );
    final failed = (await runWatch(engine)).last as TranscriptionFailed;
    expect(failed.isRetryable, isFalse);
    expect(failed.reason, 'apiKeyMissing');
  });

  test('checkAvailability: キー無し→false, キー有り→true', () async {
    final noKey = engineWith(
      MockClient((_) async => http.Response('x', 200)),
      secrets: const {},
    );
    expect((await noKey.checkAvailability()).available, isFalse);

    final withKey = engineWith(MockClient((_) async => http.Response('x', 200)));
    expect((await withKey.checkAvailability()).available, isTrue);
  });

  test('checkAvailability: 非対応 locale → localeUnsupported', () async {
    final engine = engineWith(MockClient((_) async => http.Response('x', 200)));
    final avail = await engine.checkAvailability(localeId: 'xx-XX');
    expect(avail.available, isFalse);
    expect(avail.unavailableReason, 'localeUnsupported');
  });
}
