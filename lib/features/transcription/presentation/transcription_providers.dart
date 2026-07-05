import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../application/transcription_engine_registry.dart';
import '../application/transcription_service.dart';
import '../engines/cloud_stt_engine.dart';

part 'transcription_providers.g.dart';

/// アプリの drift データベース。
///
/// NOTE(integration): まだ core 側に正式な appDatabaseProvider が存在しないため、
/// ここで override 前提の shim を置く。アプリルートの ProviderScope で
/// `appDatabaseProvider.overrideWithValue(db)` する想定。統合フェーズで
/// core 側の正式 provider が生えたら本 shim を差し替える。
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider must be overridden at the app root',
  ),
);

/// 文字起こしエンジン登録簿。差し替え（テスト・エンジン追加）はこの provider を override。
///
/// MVP は [CloudSttEngine] 一択（API キーは secure_storage から読む）。
@riverpod
TranscriptionEngineRegistry transcriptionEngineRegistry(Ref ref) {
  final cloud = CloudSttEngine();
  return TranscriptionEngineRegistry(
    {cloud.id: cloud},
    defaultEngineId: CloudSttEngine.engineId,
  );
}

/// ドメインサービス（Riverpod 非依存の実体を DI で組む）。
@riverpod
TranscriptionService transcriptionService(Ref ref) {
  return TranscriptionService(
    db: ref.watch(appDatabaseProvider),
    registry: ref.watch(transcriptionEngineRegistryProvider),
  );
}

/// 一覧メニューの「再文字起こし」アクション。
///
/// バッジ状態自体は recordings テーブルの watch で足りるため、状態を持つ provider は
/// これ（アクション）だけを公開する（DESIGN.md §8.6）。
@riverpod
class RetranscribeController extends _$RetranscribeController {
  @override
  Future<void> build() async {}

  /// 指定録音を（再）文字起こしする。失敗はサービス内部で握られ例外は飛ばない。
  Future<void> retranscribe(String recordingId, {String? engineId}) async {
    state = const AsyncLoading();
    final service = ref.read(transcriptionServiceProvider);
    await service.transcribe(recordingId, engineId: engineId);
    state = const AsyncData(null);
  }
}
