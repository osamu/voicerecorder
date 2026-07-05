import 'dart:io';

import 'package:record/record.dart';

import '../../../core/database/tables.dart';

/// 録音エンジンの抽象（`record` パッケージのラッパ）。
///
/// [RecordingService] をプラットフォーム非依存かつ単体テスト可能にするため、
/// `record` の [AudioRecorder] への依存をこのインタフェース越しにする。
/// ドメイン層は Riverpod にも Flutter にも依存しないため、ここも同様。
abstract interface class RecorderBackend {
  /// マイク権限を確認（[request]=true なら未許可時に要求）。
  Future<bool> hasPermission({bool request = true});

  /// [path] へ [codec] で録音を開始する。
  Future<void> start({required String path, required Codec codec});

  /// 録音を停止し、書き出されたファイルパスを返す（実装が返せる場合）。
  Future<String?> stop();

  /// 現在録音中か。
  Future<bool> isRecording();

  /// 録音状態の変化ストリーム（開始/停止検知用）。
  Stream<RecordState> onStateChanged();

  /// リソース解放。
  Future<void> dispose();
}

/// `record` パッケージによる本番実装。
///
/// - iOS: AAC(.m4a) モノラル 32kbps
/// - Android: Ogg Opus モノラル 32kbps（`minSdkVersion 29`）
///
/// フォーマット非統一は許容（CLAUDE.md 設計原則5）。ffmpeg 変換はしない。
class RecordRecorderBackend implements RecorderBackend {
  RecordRecorderBackend([AudioRecorder? recorder])
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  /// モノラル 32kbps（DESIGN §6.1）。
  static const int _bitRate = 32000;
  static const int _sampleRate = 16000;
  static const int _numChannels = 1;

  static RecordConfig configFor(Codec codec) {
    switch (codec) {
      case Codec.aacM4a:
        return const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: _bitRate,
          sampleRate: _sampleRate,
          numChannels: _numChannels,
          // 割り込みは audio_session 側で明示ハンドリングするため pause 指定。
          audioInterruption: AudioInterruptionMode.pause,
        );
      case Codec.oggOpus:
        return const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: _bitRate,
          sampleRate: _sampleRate,
          numChannels: _numChannels,
          audioInterruption: AudioInterruptionMode.pause,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.mic,
          ),
        );
    }
  }

  @override
  Future<bool> hasPermission({bool request = true}) =>
      _recorder.hasPermission(request: request);

  @override
  Future<void> start({required String path, required Codec codec}) async {
    // iOS ではセッション管理を audio_session 側に委ね、record 側では管理しない
    // （二重管理による競合を避ける §6.1）。
    if (Platform.isIOS) {
      await _recorder.ios?.manageAudioSession(false);
    }
    await _recorder.start(configFor(codec), path: path);
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<bool> isRecording() => _recorder.isRecording();

  @override
  Stream<RecordState> onStateChanged() => _recorder.onStateChanged();

  @override
  Future<void> dispose() => _recorder.dispose();
}

/// ファイルサイズ・空き容量の問い合わせ抽象（テスト時に差し替え可能）。
abstract interface class FileProbe {
  /// [path] のファイルが存在するか。
  Future<bool> exists(String path);

  /// [path] のファイルサイズ（bytes）。存在しなければ 0。
  Future<int> sizeOf(String path);

  /// [dirPath] を含むボリュームの空き容量（bytes）。取得不能なら null。
  Future<int?> freeSpaceBytes(String dirPath);
}

/// dart:io による本番 [FileProbe] 実装。
///
/// 空き容量は `df -k` を用いて取得する（Flutter 標準 API に無いため）。
/// 取得失敗時は null を返し、呼び出し側は「不明」として安全側に倒す。
class IoFileProbe implements FileProbe {
  const IoFileProbe();

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<int> sizeOf(String path) async {
    final f = File(path);
    if (!await f.exists()) return 0;
    return f.length();
  }

  @override
  Future<int?> freeSpaceBytes(String dirPath) async {
    try {
      final result = await Process.run('df', ['-k', dirPath]);
      if (result.exitCode != 0) return null;
      final lines = (result.stdout as String).trim().split('\n');
      if (lines.length < 2) return null;
      // 末尾行の "Available"(4列目, KB) を採用。ヘッダ揺れに強いよう後方から探す。
      final cols = lines.last.trim().split(RegExp(r'\s+'));
      if (cols.length < 4) return null;
      final availKb = int.tryParse(cols[3]);
      if (availKb == null) return null;
      return availKb * 1024;
    } catch (_) {
      return null;
    }
  }
}
