import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/audio_session/audio_session_manager.dart';
import '../../../core/background/foreground_task_handler.dart';
import '../../../core/database/app_database.dart';
import '../domain/foreground_controller.dart';
import '../domain/local_notifier.dart';
import '../domain/recorder_backend.dart';
import '../domain/recording_paths.dart';
import '../domain/recording_runtime.dart';
import '../domain/recording_service.dart';

part 'recording_providers.g.dart';

/// アプリ共通の drift データベース。
///
/// ASSUMPTION: 統合フェーズでは app/core 側の集約 provider に置き換える想定。
/// 単一インスタンスを保つため keepAlive。テストでは override する。
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// セグメント確定フック（既定は未接続＝null）。
///
/// 統合層（app 配線）が「即時アップロード＋文字起こし投入」を override で注入する。
/// 手書き provider（関数型は codegen 対象外のため）。
final recordingSegmentFinalizedHookProvider =
    Provider<void Function(String recordingId)?>((ref) => null);

/// iOS 録音セッション＋割り込み購読マネージャ（keepAlive）。
@Riverpod(keepAlive: true)
AudioSessionManager audioSessionManager(Ref ref) {
  final manager = AudioSessionManager();
  ref.onDispose(manager.dispose);
  return manager;
}

/// 録音サービス本体（keepAlive）。組み立て＋初期化まで行う。
///
/// 録音は FG 起点のみ・単一インスタンスであるべきなので keepAlive。
@Riverpod(keepAlive: true)
Future<RecordingService> recordingService(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final session = ref.watch(audioSessionManagerProvider);
  final paths = await RecordingPaths.create();

  final ForegroundController foreground =
      Platform.isAndroid ? FlutterForegroundController() : const NoopForegroundController();
  final LocalNotifier notifier = FlutterLocalNotifier();

  final service = RecordingService(
    db: db,
    recorder: RecordRecorderBackend(),
    paths: paths,
    foreground: foreground,
    notifier: notifier,
    interruptionEvents: session.interruptions,
    activateSession: session.activate,
    deactivateSession: session.deactivate,
  );
  // 統合層のフック（即時アップロード＋文字起こし投入）を接続。
  service.onSegmentFinalized =
      ref.watch(recordingSegmentFinalizedHookProvider);
  await service.initialize();
  ref.onDispose(service.dispose);
  return service;
}

/// 録音の実行時スナップショットを購読するストリーム（§10.2）。
///
/// 全画面共通の「録音中バー」・録音ボタンはこれを watch する。
@riverpod
Stream<RecordingRuntime> recordingRuntime(Ref ref) async* {
  final service = await ref.watch(recordingServiceProvider.future);
  yield service.runtime;
  yield* service.runtimeStream;
}

/// 録音中バー用に射影した最小状態。
class RecordingBarState {
  const RecordingBarState({
    required this.visible,
    required this.elapsed,
    required this.title,
    required this.storageWarning,
  });

  /// バーを表示すべきか（録音中 or 割り込み中）。
  final bool visible;
  final Duration elapsed;
  final String title;
  final bool storageWarning;

  static const hidden = RecordingBarState(
    visible: false,
    elapsed: Duration.zero,
    title: '',
    storageWarning: false,
  );
}

/// 全画面共通「録音中バー」用の状態 provider。
@riverpod
RecordingBarState recordingBar(Ref ref) {
  final async = ref.watch(recordingRuntimeProvider);
  final runtime = async.value;
  if (runtime == null || !runtime.isActive) {
    return RecordingBarState.hidden;
  }
  return RecordingBarState(
    visible: true,
    elapsed: runtime.elapsed,
    title: runtime.title,
    storageWarning: runtime.storageWarning,
  );
}
