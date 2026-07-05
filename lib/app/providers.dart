import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import 'contracts.dart';
import 'stubs.dart';

/// アプリ全体の Provider 定義（UI 層の配線）。
///
/// - DB / DAO は Foundation 契約に直接依存する堅い配線。
/// - 各 feature コントローラは [contracts.dart] の抽象に依存し、既定は
///   [stubs.dart] のスタブ。統合フェーズで `overrideWithValue` により差し替える。
///
/// 手書き Provider（riverpod_generator 非使用）で構成し、コード生成なしで
/// 解析・テストが通るようにしている。

// ---------------------------------------------------------------------------
// データベース / DAO
// ---------------------------------------------------------------------------

/// AppDatabase 本体。bootstrap で開いたインスタンスを override して注入する。
/// テストでは `AppDatabase.forExecutor(NativeDatabase.memory())` を override。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError(
    'appDatabaseProvider は bootstrap もしくはテストで override されている必要があります',
  );
});

final recordingsDaoProvider = Provider<RecordingsDao>(
  (ref) => ref.watch(appDatabaseProvider).recordingsDao,
);

final uploadJobsDaoProvider = Provider<UploadJobsDao>(
  (ref) => ref.watch(appDatabaseProvider).uploadJobsDao,
);

final transcriptionJobsDaoProvider = Provider<TranscriptionJobsDao>(
  (ref) => ref.watch(appDatabaseProvider).transcriptionJobsDao,
);

final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao,
);

// ---------------------------------------------------------------------------
// feature コントローラ（既定はスタブ。統合で override）
// ---------------------------------------------------------------------------

final authControllerProvider = Provider<AuthController>(
  (ref) => StubAuthController(),
);

final recordingControllerProvider = Provider<RecordingController>(
  (ref) => StubRecordingController(),
);

final uploadControllerProvider = Provider<UploadController>(
  (ref) => StubUploadController(),
);

final transcriptionControllerProvider = Provider<TranscriptionController>(
  (ref) => StubTranscriptionController(),
);

final permissionControllerProvider = Provider<PermissionController>(
  (ref) => StubPermissionController(),
);

// ---------------------------------------------------------------------------
// 認証状態（バッジ・設定・サインイン誘導）
// ---------------------------------------------------------------------------

/// 認証状態のストリーム。初期値は同期取得した現在値。
final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.watch();
});

/// サインイン済みかの簡易フラグ（未解決時は false 扱い）。
final isSignedInProvider = Provider<bool>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.maybeWhen(
    data: (s) => s.isSignedIn,
    orElse: () => ref.watch(authControllerProvider).current.isSignedIn,
  );
});

// ---------------------------------------------------------------------------
// 進行中録音（全画面共通の録音中バー）
// ---------------------------------------------------------------------------

final activeRecordingProvider = StreamProvider<ActiveRecording?>((ref) {
  final rec = ref.watch(recordingControllerProvider);
  return rec.watchActive();
});

/// 録音中かどうか（新規録音・改名・削除の抑止に使用）。
final isRecordingProvider = Provider<bool>((ref) {
  final active = ref.watch(activeRecordingProvider);
  return active.maybeWhen(
    data: (s) => s != null,
    orElse: () => ref.watch(recordingControllerProvider).active != null,
  );
});

// ---------------------------------------------------------------------------
// オンライン / オフライン（オフラインバナー）
// ---------------------------------------------------------------------------

/// オンライン状態のストリーム。true=オンライン。
///
/// 既定は「常にオンライン」を1度だけ流すだけの安全なスタブ。実際の
/// connectivity_plus 監視は統合フェーズで override する（プラットフォーム
/// チャネル依存のためテストでも override 可能なようにここで分離している）。
final connectivityProvider = StreamProvider<bool>((ref) {
  return Stream<bool>.value(true);
});

// ---------------------------------------------------------------------------
// 設定値（drift settings の watch）
// ---------------------------------------------------------------------------

/// 任意の設定キーの値を watch する family。
final settingValueProvider =
    StreamProvider.family<String?, String>((ref, key) {
  return ref.watch(settingsDaoProvider).watchValue(key);
});

/// 文字起こし ON/OFF。
final transcriptionEnabledProvider = Provider<bool>((ref) {
  final v = ref.watch(settingValueProvider(SettingsKeys.transcriptionEnabled));
  return v.maybeWhen(data: (s) => s == 'true', orElse: () => false);
});

/// オンボーディング完了フラグ（マイク権限フローを通過済みか）。
const String kOnboardingCompleteKey = 'onboardingComplete';

final onboardingCompleteProvider = Provider<bool>((ref) {
  final v = ref.watch(settingValueProvider(kOnboardingCompleteKey));
  return v.maybeWhen(data: (s) => s == 'true', orElse: () => false);
});
