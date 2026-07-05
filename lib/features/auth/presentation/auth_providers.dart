import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/drive/drive_client.dart';
import '../../../core/drive/google_drive_client.dart';
import '../../../core/security/secure_storage.dart';
import '../domain/auth_service.dart';
import '../domain/auth_state.dart';

part 'auth_providers.g.dart';

/// アプリのメイン drift データベース。
///
/// 実体はアプリ起動時（app 層の [ProviderScope.overrides]）で単一インスタンスに
/// 差し替える前提。BG isolate とは別インスタンスになるため keepAlive で共有する。
///
/// NOTE(統合): app / 他 feature が同名 provider を定義する場合は、そちらへ寄せて
/// 本 provider は削除すること（重複定義防止）。
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden at app bootstrap',
  );
}

/// flutter_secure_storage ラッパ（トークン保存）。
@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => SecureStore();

/// 認証サービス（google_sign_in v7 ＋ googleapis_auth）。
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = AuthService(
    secureStore: ref.watch(secureStoreProvider),
    uploadJobsDao: db.uploadJobsDao,
  );
  ref.onDispose(service.dispose);
  return service;
}

/// 認証状態のストリーム（UI・キュー制御が購読）。
@riverpod
Stream<AuthState> authState(Ref ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
}

/// サインイン済みか（UI 分岐用の簡易フラグ）。
@riverpod
bool isSignedIn(Ref ref) {
  final state = ref.watch(authStateProvider);
  return state.value is AuthSignedIn;
}

/// Drive クライアント（認証済みクライアントは [AuthService] から供給）。
///
/// 認証状態に依存させ、サインアウト/再サインイン時に作り直す。
@Riverpod(keepAlive: true)
DriveClient driveClient(Ref ref) {
  final auth = ref.watch(authServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return GoogleDriveClient(
    clientProvider: auth.authorizedClient,
    settingsDao: db.settingsDao,
  );
}

/// revoke 等に使う汎用 http クライアント（テスト差し替え用に分離）。
@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}
