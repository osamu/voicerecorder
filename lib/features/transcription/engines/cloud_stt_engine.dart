import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/security/secure_storage.dart';
import '../domain/transcription_engine.dart';

/// MVP 既定エンジン: クラウド STT（OpenAI Whisper API 等）を HTTP 直叩きする
/// [BatchTranscriptionEngine] 実装（DESIGN.md §8.4）。
///
/// 設計上の要点:
/// - [submit] は HTTP 送信を行わず、再購読可能な jobHandle（JSON 文字列）を返すだけ。
///   実際の multipart 送信は [watch] が行う。これにより、アプリ再起動後に
///   [watch] を再購読すれば「未送信なら送信からやり直す」挙動になる
///   （バッチ API にはサーバ側ジョブ ID が無いため、watch は常に送信し直す）。
/// - API キーは flutter_secure_storage（[SecureKeys.sttApiKey]）から読む。
/// - capability: file 入力 / {m4a,opus} / 25MB / fixedList。
/// - エラー分類: ネットワーク / 5xx / 429 → isRetryable=true、401 / 413 / その他 4xx → false。
class CloudSttEngine implements BatchTranscriptionEngine {
  CloudSttEngine({
    SecureStore? secureStore,
    http.Client? httpClient,
    Future<bool> Function()? isOnline,
    String endpoint = 'https://api.openai.com/v1/audio/transcriptions',
    String model = 'whisper-1',
  })  : _secureStore = secureStore ?? SecureStore(),
        _client = httpClient ?? http.Client(),
        _isOnlineOverride = isOnline,
        _endpoint = endpoint,
        _model = model;

  /// Registry のキー（[TranscriptionJob.engineId] にも保存される）。
  static const String engineId = 'cloud_stt';

  final SecureStore _secureStore;
  final http.Client _client;
  final Future<bool> Function()? _isOnlineOverride;
  final String _endpoint;
  final String _model;

  @override
  String get id => engineId;

  @override
  String get displayName => 'Cloud STT (Whisper API)';

  @override
  EngineCapability get capability => EngineCapability(
        audioInputMode: AudioInputMode.file,
        acceptedFormats: const {'m4a', 'opus'},
        maxFileSizeBytes: AppConstants.sttMaxFileSizeBytes,
        languageMode: LanguageMode.fixedList,
      );

  @override
  Future<EngineAvailability> checkAvailability({String? localeId}) async {
    final key = await _secureStore.read(SecureKeys.sttApiKey);
    if (key == null || key.isEmpty) {
      return const EngineAvailability(false, 'apiKeyMissing');
    }
    if (localeId != null) {
      final locales = await supportedLocales();
      if (!locales.contains(localeId)) {
        return const EngineAvailability(false, 'localeUnsupported');
      }
    }
    if (!await _isOnline()) {
      return const EngineAvailability(false, 'offline');
    }
    return const EngineAvailability(true);
  }

  @override
  Future<List<String>> supportedLocales() async => const [
        'ja-JP',
        'en-US',
        'en-GB',
        'zh-CN',
        'ko-KR',
        'es-ES',
        'fr-FR',
        'de-DE',
        'it-IT',
        'pt-BR',
        'ru-RU',
        'id-ID',
        'th-TH',
        'vi-VN',
        'hi-IN',
        'ar-SA',
      ];

  @override
  Future<String> submit(File audio, {String? localeId}) async {
    // 送信はまだ行わない。再購読可能なハンドルを組むだけ。
    final handle = _CloudSttJobHandle(
      filePath: audio.path,
      localeId: localeId,
      model: _model,
    );
    return handle.encode();
  }

  @override
  Stream<TranscriptionEvent> watch(String jobHandle) async* {
    final _CloudSttJobHandle job;
    try {
      job = _CloudSttJobHandle.decode(jobHandle);
    } catch (_) {
      yield const TranscriptionFailed('badJobHandle', isRetryable: false);
      return;
    }

    final file = File(job.filePath);
    if (!await file.exists()) {
      yield const TranscriptionFailed('fileMissing', isRetryable: false);
      return;
    }

    final apiKey = await _secureStore.read(SecureKeys.sttApiKey);
    if (apiKey == null || apiKey.isEmpty) {
      yield const TranscriptionFailed('apiKeyMissing', isRetryable: false);
      return;
    }

    // バッチ API は途中経過を返さないため、開始マーカーとして不定進捗を1回出す。
    yield const TranscriptionProgress(null);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = job.model
        ..fields['response_format'] = 'text';
      final lang = _whisperLang(job.localeId);
      if (lang != null) {
        request.fields['language'] = lang;
      }
      request.files
          .add(await http.MultipartFile.fromPath('file', job.filePath));

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        yield TranscriptionCompleted(_extractText(response.body));
      } else {
        yield TranscriptionFailed(
          _reasonForStatus(response.statusCode),
          isRetryable: _isRetryableStatus(response.statusCode),
        );
      }
    } on SocketException {
      yield const TranscriptionFailed('network', isRetryable: true);
    } on HttpException {
      yield const TranscriptionFailed('network', isRetryable: true);
    } on http.ClientException {
      yield const TranscriptionFailed('network', isRetryable: true);
    } catch (_) {
      // 想定外は一時扱い（再試行余地を残す）。本文はログにもイベントにも出さない。
      yield const TranscriptionFailed('unknown', isRetryable: true);
    }
  }

  @override
  Future<void> cancel(String jobHandle) async {
    // バッチ HTTP の単発リクエストにはサーバ側キャンセル手段が無い。no-op。
    // 進行中の送信は呼び出し側がストリーム購読を解除することで放棄される。
  }

  Future<bool> _isOnline() async {
    final override = _isOnlineOverride;
    if (override != null) {
      return override();
    }
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// 'ja-JP' → 'ja'（ISO-639-1）。null や不正値は言語未指定（自動判定）扱いに落とす。
  static String? _whisperLang(String? localeId) {
    if (localeId == null || localeId.isEmpty) return null;
    final base = localeId.split('-').first.trim().toLowerCase();
    return base.isEmpty ? null : base;
  }

  /// response_format=text のときは本文がそのまま全文。JSON が返っても text を拾う。
  static String _extractText(String body) {
    final trimmed = body.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['text'] is String) {
          return (decoded['text'] as String).trim();
        }
      } catch (_) {
        // フォールスルーして生本文を返す。
      }
    }
    return trimmed;
  }

  static bool _isRetryableStatus(int status) =>
      status == 429 || (status >= 500 && status <= 599);

  static String _reasonForStatus(int status) {
    if (status == 401 || status == 403) return 'authFailed';
    if (status == 413) return 'fileTooLarge';
    if (status == 429) return 'rateLimited';
    if (status >= 500) return 'serverError';
    return 'requestFailed';
  }
}

/// [CloudSttEngine] の jobHandle。DB(`transcription_jobs.jobHandle`)へ JSON 永続化される。
///
/// 再起動後もこの内容だけで [CloudSttEngine.watch] が送信をやり直せる
/// （recordingId は `transcription_jobs.recordingId` 側に保持されるため handle には含めない）。
class _CloudSttJobHandle {
  const _CloudSttJobHandle({
    required this.filePath,
    required this.localeId,
    required this.model,
  });

  final String filePath;
  final String? localeId;
  final String model;

  String encode() => jsonEncode({
        'v': 1,
        'filePath': filePath,
        'localeId': localeId,
        'model': model,
      });

  static _CloudSttJobHandle decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return _CloudSttJobHandle(
      filePath: map['filePath'] as String,
      localeId: map['localeId'] as String?,
      model: (map['model'] as String?) ?? 'whisper-1',
    );
  }
}
