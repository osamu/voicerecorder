import 'package:workmanager/workmanager.dart';

import '../../features/upload/domain/upload_queue.dart';
import '../database/app_database.dart';
import '../drive/drive_client.dart';
import '../security/app_logger.dart';

/// WorkManager の BG タスク種別（enqueue 側と一致させる）。
abstract final class UploadBgTasks {
  /// pending キューを flush する定期/一発タスク。
  static const String flushQueue = 'vr.upload.flush';
}

/// BG isolate で [DriveClient] を組み立てるためのビルダ。
///
/// WorkManager の callbackDispatcher は **アプリの main() とは別 isolate** で走り、
/// main() で設定したグローバルや Riverpod プロバイダは見えない。したがって、認証
/// トークン（flutter_secure_storage）から DriveClient を再構築する具体ロジックは
/// core/drive 側（別担当）が提供し、その入口関数を本フックへ登録する必要がある。
///
/// 統合フェーズでの配線例:
/// ```dart
/// // callbackDispatcher の先頭、または core/drive の初期化で:
/// uploadBackgroundDriveClientBuilder = () => createBackgroundDriveClient();
/// ```
/// 未登録の場合、BG flush はスキップされ WorkManager が後で再試行する。
typedef UploadBackgroundDriveClientBuilder = Future<DriveClient> Function();

/// BG での DriveClient ビルダ登録先（core/drive 側が設定する）。
UploadBackgroundDriveClientBuilder? uploadBackgroundDriveClientBuilder;

/// WorkManager のトップレベル・エントリポイント（BG isolate）。
///
/// 設計原則2 に従い、BG からは **ドメイン層（[UploadQueue]）＋ DB を直接使用** し、
/// Riverpod / Flutter UI には一切依存しない。
///
/// `main.dart` で `Workmanager().initialize(callbackDispatcher)` として登録する。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    const log = AppLogger('upload.bg');
    final builder = uploadBackgroundDriveClientBuilder;
    if (builder == null) {
      log.warning('drive client builder not registered; skipping bg flush');
      // false を返すと WorkManager が再試行する。
      return false;
    }

    AppDatabase? db;
    UploadQueue? queue;
    try {
      db = AppDatabase();
      final drive = await builder();
      queue = UploadQueue(db: db, drive: drive, logger: log);

      // 起動時リカバリ相当（uploading→pending 戻し＋nextRetryAt 経過分再開）。
      await queue.recoverOnStartup();
      // 24h 以上滞留していれば通知（notifier 未配線なら no-op）。
      await queue.checkStaleQueue();
      return true;
    } catch (e) {
      log.error('bgFlush', error: e);
      // 一時的な失敗として WorkManager に再試行させる。
      return false;
    } finally {
      await queue?.dispose();
      await db?.close();
    }
  });
}
