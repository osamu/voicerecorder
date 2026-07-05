import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';

/// 一覧・バッジ駆動のためのフィーチャ Provider。
///
/// 状態の single source of truth は drift。ここでは DAO の watch を
/// StreamProvider として公開し、UI がリアクティブに購読する。

/// 録音一覧（startedAt DESC）。ホーム画面が購読する。
final recordingsListProvider = StreamProvider<List<Recording>>((ref) {
  return ref.watch(recordingsDaoProvider).watchAll();
});

/// 単一録音（再生・詳細・改名・削除・txt 閲覧が購読）。
final recordingByIdProvider =
    StreamProvider.family<Recording?, String>((ref, id) {
  return ref.watch(recordingsDaoProvider).watchById(id);
});

/// 未アップロード（pending / retryableFailed）ジョブ件数。オフラインバナー用。
final outstandingUploadCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(uploadJobsDaoProvider)
      .watchOutstanding()
      .map((jobs) => jobs.length);
});
