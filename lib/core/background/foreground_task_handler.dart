import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../features/recording/domain/foreground_controller.dart';

/// Android microphone FGS の常駐通知チャンネル ID。
const String kRecordingChannelId = 'recording_fgs';

/// 経過時間を `H:MM:SS` / `M:SS` 形式に整形する（常駐通知本文用）。純粋関数。
String formatElapsed(Duration elapsed) {
  final totalSeconds = elapsed.inSeconds;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
}

/// `flutter_foreground_task` を用いた [ForegroundController] の本番実装（§6.1/§6.3）。
///
/// microphone 型 FGS を起動し、常駐通知に録音経過時間を表示する。partial wakelock は
/// [ForegroundTaskOptions.allowWakeLock]（既定 true）で有効化する。
///
/// 注意: `startService` は**フォアグラウンド（画面表示中）からのみ**呼ぶこと。
/// Android 11+ は BG からの microphone FGS 起動を許可しない（§6.1 / #11）。
class FlutterForegroundController implements ForegroundController {
  FlutterForegroundController();

  bool _initialized = false;

  void _ensureInit() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: kRecordingChannelId,
        channelName: '録音中',
        channelDescription: '録音の継続とバックグラウンド動作のための通知です。',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // 経過時間更新はメイン isolate 側の updateService で行うため、
        // isolate 側の繰り返しイベントは使わない。
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true, // partial wakelock（§6.2）
        allowWifiLock: false,
        autoRunOnBoot: false,
        allowAutoRestart: true,
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> startRecordingNotification({required String title}) async {
    if (!Platform.isAndroid) return;
    _ensureInit();
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.microphone],
      notificationTitle: title,
      notificationText: '録音中 0:00',
      callback: recordingForegroundCallback,
    );
  }

  @override
  Future<void> updateElapsed(Duration elapsed, {String? title}) async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: '録音中 ${formatElapsed(elapsed)}',
    );
  }

  @override
  Future<void> stopRecordingNotification() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    _ensureInit();
    final status = await FlutterForegroundTask.requestNotificationPermission();
    return status == NotificationPermission.granted;
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() {
    if (!Platform.isAndroid) return Future.value(true);
    return FlutterForegroundTask.isIgnoringBatteryOptimizations;
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() {
    if (!Platform.isAndroid) return Future.value(true);
    return FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}

/// FGS isolate のエントリポイント。`startService(callback:)` から参照される。
///
/// 録音そのものはメイン isolate（FG 起点）で行い、本 isolate は常駐通知の維持と
/// wakelock 保持のみを担う。よって [RecordingTaskHandler] は最小構成。
@pragma('vm:entry-point')
void recordingForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
}

/// FGS 常駐用の最小 [TaskHandler]。
///
/// 経過時間の通知更新はメイン isolate の [FlutterForegroundController.updateElapsed]
/// が担当するため、ここでは繰り返し処理を持たない。
class RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
