import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';

/// 割り込みの種類（アプリ内部で扱う簡約版）。
enum RecordingInterruptionPhase {
  /// 割り込み開始（着信・Siri・音声フォーカス喪失）。録音を確定保存すべき。
  began,

  /// 割り込み終了。自動再開を試みるべき。
  ended,
}

/// 割り込みイベント（開始/終了 ＋ 恒久的中断か）。
class RecordingInterruption {
  const RecordingInterruption(this.phase, {this.shouldResume = true});

  final RecordingInterruptionPhase phase;

  /// 終了イベント時に自動再開を推奨するか（type=unknown の恒久中断では false）。
  final bool shouldResume;
}

/// iOS の録音セッション設定と割り込み購読を担う（§6.1 / §6.2）。
///
/// - iOS: `playAndRecord` カテゴリを設定し、`UIBackgroundModes=audio`（Info.plist
///   側で設定済み）と併せて BG 継続録音を可能にする。audio BG モードは録音中のみ
///   セッションを保持する（§6.4 審査・電池対策）ため、[activate]/[deactivate] を
///   録音の開始・停止に対応させる。
/// - Android: FGS 側（[flutter_foreground_task]）が継続を担うため、本マネージャは
///   主に割り込みイベントの購読口として機能する。
///
/// [audio_session] の interruption イベントを購読し、アプリ内部表現
/// [RecordingInterruption] のストリームに正規化して公開する。
class AudioSessionManager {
  AudioSessionManager({AudioSession? session}) : _injectedSession = session;

  final AudioSession? _injectedSession;
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  final _controller = StreamController<RecordingInterruption>.broadcast();

  /// 割り込みイベントストリーム。[RecordingService] が購読する。
  Stream<RecordingInterruption> get interruptions => _controller.stream;

  /// セッションを取得・設定する（冪等）。録音開始前に一度呼ぶ。
  Future<void> configure() async {
    _session ??= _injectedSession ?? await AudioSession.instance;
    final session = _session!;

    // 音声録音向けカテゴリ。iOS は playAndRecord、Android は speech 属性。
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ),
    );

    _interruptionSub ??=
        session.interruptionEventStream.listen(_onInterruptionEvent);
  }

  void _onInterruptionEvent(AudioInterruptionEvent event) {
    if (event.begin) {
      _controller.add(
        const RecordingInterruption(RecordingInterruptionPhase.began),
      );
    } else {
      // type=unknown は「無期限に一時停止」＝自動再開が保証されない恒久中断。
      final shouldResume = event.type != AudioInterruptionType.unknown;
      _controller.add(
        RecordingInterruption(
          RecordingInterruptionPhase.ended,
          shouldResume: shouldResume,
        ),
      );
    }
  }

  /// 録音開始時にセッションを有効化する（iOS で audio BG モードを保持）。
  Future<void> activate() async {
    await configure();
    await _session?.setActive(true);
  }

  /// 録音停止時にセッションを解放する（審査・電池対策で録音中のみ保持）。
  Future<void> deactivate() async {
    // iOS のみ意味を持つ。Android では no-op に近い。
    if (Platform.isIOS) {
      await _session?.setActive(false);
    }
  }

  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    await _controller.close();
  }
}
