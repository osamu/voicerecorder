import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/security/app_logger.dart';
import '../features/auth/presentation/auth_providers.dart' as auth;
import 'providers.dart';
import 'wiring.dart';

/// 起動シーケンス（DESIGN §12）。
///
/// 1. drift DB オープン
/// 2. 未クローズ録音のリカバリ（録音 feature）
/// 3. upload_jobs の uploading(中断) を pending へ戻す＋キュー再開
/// 4. transcription_jobs の submitted/running を resumePendingJobs で再購読
/// 5. connectivity 監視は UI（connectivityProvider）が購読時に開始
/// 6. UI 起動（呼び出し側で runApp）
///
/// 戻り値の [ProviderContainer] を UncontrolledProviderScope に渡して runApp する。
/// DB は本メソッドで開いて Provider に override 注入し、feature の実体は
/// [buildAppOverrides]（wiring.dart）で契約プロバイダへ結線する。
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  const log = AppLogger('bootstrap');

  // 1. DB オープン（本番接続）＋統合配線。
  final db = AppDatabase();

  final container = createAppContainer(db);

  // 起動時リカバリ・再購読は「録音・アップロードを妨げない」ベストエフォート。
  // 各ステップは独立して try/catch し、1 つの失敗が他や UI 起動を止めないようにする。

  // 3a. 中断アップロード（uploading のまま）の pending 戻し。DB レベルで安全に実施。
  try {
    final reset = await db.uploadJobsDao.resetStuckUploading();
    if (reset > 0) {
      log.info('recovered stuck uploads count=$reset');
    }
  } catch (e) {
    log.error('recoverStuckUploads', error: e);
  }

  // 2. 未クローズ録音のリカバリ（録音 feature）。
  try {
    await container.read(recordingControllerProvider).recoverInterrupted();
  } catch (e) {
    log.error('recoverInterruptedRecordings', error: e);
  }

  // 2b. サインイン状態の silent 復元（キュー再開の前提。失敗しても録音は可能）。
  try {
    final authService = container.read(auth.authServiceProvider);
    await authService.initialize();
    await authService.restoreSession();
  } catch (e) {
    log.error('restoreAuthSession', error: e);
  }

  // 3b. アップロードキュー再開（upload feature）。flush はアップロード完了まで
  //     待ち得るため UI 起動をブロックしない（fire-and-forget）。
  unawaited(Future(() async {
    try {
      await container.read(uploadControllerProvider).resumeQueue();
    } catch (e) {
      log.error('resumeUploadQueue', error: e);
    }
  }));

  // 4. 文字起こしジョブの再購読（transcription feature）。結果受領まで待ち得る
  //    ため UI 起動をブロックしない（fire-and-forget）。
  unawaited(Future(() async {
    try {
      await container.read(transcriptionControllerProvider).resumePendingJobs();
    } catch (e) {
      log.error('resumeTranscriptionJobs', error: e);
    }
  }));

  // 5. connectivity 監視は connectivityProvider が最初に watch された時点で開始する
  //    （lazy）。ここでは明示起動しない。

  return container;
}
