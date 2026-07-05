import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/upload_ports.dart';

/// [StaleQueueNotifier] の flutter_local_notifications 実装（DESIGN.md §7.6）。
///
/// 24 時間以上滞留した未アップロード件数のみを通知する。
/// 通知本文にタイトル・文字起こし本文・トークンを含めない（§9）。
class LocalNotificationsStaleNotifier implements StaleQueueNotifier {
  LocalNotificationsStaleNotifier(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// 滞留通知に固定で使う通知 ID（上書き更新のため一定値）。
  static const int _staleNotificationId = 1001;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'upload_stale',
    'アップロード滞留',
    channelDescription: '未アップロードの録音が滞留していることを知らせます。',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails();

  @override
  Future<void> notifyStale(int outstandingCount) {
    // 件数のみ。ユーザー入力・本文は一切含めない。
    return _plugin.show(
      id: _staleNotificationId,
      title: '未アップロードの録音があります',
      body: '$outstandingCount 件がまだクラウドへ上がっていません。オンライン時に自動で再開します。',
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: _iosDetails,
      ),
    );
  }
}
