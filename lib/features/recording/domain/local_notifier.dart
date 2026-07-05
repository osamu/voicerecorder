import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 割り込み後に自動再開できなかった等、ユーザーへ即時に知らせる必要がある事象の
/// ローカル通知（§6.2）。
///
/// ドメイン層を具体プラグインから切り離すためのインタフェース。テストでは
/// [NoopLocalNotifier]。
abstract interface class LocalNotifier {
  /// 初期化（チャンネル登録など）。冪等。
  Future<void> initialize();

  /// 「録音が中断され再開できませんでした」相当の通知を出す。
  ///
  /// 本文にタイトル等の機微情報は含めない（§9 ログ・通知ポリシー準拠）。
  Future<void> notifyRecordingInterrupted();
}

/// テスト・非対応環境用の何もしない実装。
class NoopLocalNotifier implements LocalNotifier {
  const NoopLocalNotifier();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> notifyRecordingInterrupted() async {}
}

/// `flutter_local_notifications` による本番実装。
class FlutterLocalNotifier implements LocalNotifier {
  FlutterLocalNotifier([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'recording_alerts';
  static const int _interruptedNotificationId = 1001;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  @override
  Future<void> notifyRecordingInterrupted() async {
    await initialize();
    await _plugin.show(
      id: _interruptedNotificationId,
      title: '録音が中断されました',
      body: '録音を自動で再開できませんでした。アプリを開いて続きを録音してください。',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '録音アラート',
          channelDescription: '録音の中断・再開失敗などの通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
