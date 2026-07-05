/// フォアグラウンドサービス（Android FGS）制御の抽象（§6.1 / §6.3）。
///
/// ドメイン層（[RecordingService]）を `flutter_foreground_task` 依存から切り離す
/// ためのインタフェース。実装は `lib/core/background/foreground_task_handler.dart`
/// の `FlutterForegroundController`。iOS・テストでは [NoopForegroundController]。
abstract interface class ForegroundController {
  /// 録音開始時に microphone 型 FGS を起動し、常駐通知を表示する。
  Future<void> startRecordingNotification({required String title});

  /// 常駐通知の経過時間表示を更新する（§6.3）。
  Future<void> updateElapsed(Duration elapsed, {String? title});

  /// FGS を停止し常駐通知を消す。
  Future<void> stopRecordingNotification();

  /// 通知権限（Android 13+）を要求する。拒否でも録音は可能（FGS 通知が出ないだけ）。
  Future<bool> requestNotificationPermission();

  /// バッテリ最適化除外状態か。
  Future<bool> isIgnoringBatteryOptimizations();

  /// バッテリ最適化除外を要求する（初回録音時の誘導 §6.2）。
  Future<bool> requestIgnoreBatteryOptimization();
}

/// iOS / テスト用の何もしない実装。
///
/// iOS では FGS 概念が無く、経過時間の常駐通知も存在しない（§6.3）。
class NoopForegroundController implements ForegroundController {
  const NoopForegroundController();

  @override
  Future<void> startRecordingNotification({required String title}) async {}

  @override
  Future<void> updateElapsed(Duration elapsed, {String? title}) async {}

  @override
  Future<void> stopRecordingNotification() async {}

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<bool> requestIgnoreBatteryOptimization() async => true;
}
