// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリのメイン drift データベース。
///
/// 実体はアプリ起動時（app 層の [ProviderScope.overrides]）で単一インスタンスに
/// 差し替える前提。BG isolate とは別インスタンスになるため keepAlive で共有する。
///
/// NOTE(統合): app / 他 feature が同名 provider を定義する場合は、そちらへ寄せて
/// 本 provider は削除すること（重複定義防止）。

@ProviderFor(appDatabase)
const appDatabaseProvider = AppDatabaseProvider._();

/// アプリのメイン drift データベース。
///
/// 実体はアプリ起動時（app 層の [ProviderScope.overrides]）で単一インスタンスに
/// 差し替える前提。BG isolate とは別インスタンスになるため keepAlive で共有する。
///
/// NOTE(統合): app / 他 feature が同名 provider を定義する場合は、そちらへ寄せて
/// 本 provider は削除すること（重複定義防止）。

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// アプリのメイン drift データベース。
  ///
  /// 実体はアプリ起動時（app 層の [ProviderScope.overrides]）で単一インスタンスに
  /// 差し替える前提。BG isolate とは別インスタンスになるため keepAlive で共有する。
  ///
  /// NOTE(統合): app / 他 feature が同名 provider を定義する場合は、そちらへ寄せて
  /// 本 provider は削除すること（重複定義防止）。
  const AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'0a35e7a526195b5b3ce85d964afcdfc44a708096';

/// flutter_secure_storage ラッパ（トークン保存）。

@ProviderFor(secureStore)
const secureStoreProvider = SecureStoreProvider._();

/// flutter_secure_storage ラッパ（トークン保存）。

final class SecureStoreProvider
    extends $FunctionalProvider<SecureStore, SecureStore, SecureStore>
    with $Provider<SecureStore> {
  /// flutter_secure_storage ラッパ（トークン保存）。
  const SecureStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStoreHash();

  @$internal
  @override
  $ProviderElement<SecureStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SecureStore create(Ref ref) {
    return secureStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureStore>(value),
    );
  }
}

String _$secureStoreHash() => r'4152faa8e5b4f3e77b4fbdc5fc1bb48f80b1a2d0';

/// 認証サービス（google_sign_in v7 ＋ googleapis_auth）。

@ProviderFor(authService)
const authServiceProvider = AuthServiceProvider._();

/// 認証サービス（google_sign_in v7 ＋ googleapis_auth）。

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// 認証サービス（google_sign_in v7 ＋ googleapis_auth）。
  const AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'2c2384b33976b9970b62d80e22cbf239fbcfc0f4';

/// 認証状態のストリーム（UI・キュー制御が購読）。

@ProviderFor(authState)
const authStateProvider = AuthStateProvider._();

/// 認証状態のストリーム（UI・キュー制御が購読）。

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// 認証状態のストリーム（UI・キュー制御が購読）。
  const AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'512a6986e42aaaed4be9559e5a2033f9dc7e2e89';

/// サインイン済みか（UI 分岐用の簡易フラグ）。

@ProviderFor(isSignedIn)
const isSignedInProvider = IsSignedInProvider._();

/// サインイン済みか（UI 分岐用の簡易フラグ）。

final class IsSignedInProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// サインイン済みか（UI 分岐用の簡易フラグ）。
  const IsSignedInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isSignedInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isSignedInHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isSignedIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isSignedInHash() => r'782bf81329cf6fc70ed797b7bb8526216b5eb1f4';

/// Drive クライアント（認証済みクライアントは [AuthService] から供給）。
///
/// 認証状態に依存させ、サインアウト/再サインイン時に作り直す。

@ProviderFor(driveClient)
const driveClientProvider = DriveClientProvider._();

/// Drive クライアント（認証済みクライアントは [AuthService] から供給）。
///
/// 認証状態に依存させ、サインアウト/再サインイン時に作り直す。

final class DriveClientProvider
    extends $FunctionalProvider<DriveClient, DriveClient, DriveClient>
    with $Provider<DriveClient> {
  /// Drive クライアント（認証済みクライアントは [AuthService] から供給）。
  ///
  /// 認証状態に依存させ、サインアウト/再サインイン時に作り直す。
  const DriveClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driveClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driveClientHash();

  @$internal
  @override
  $ProviderElement<DriveClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DriveClient create(Ref ref) {
    return driveClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriveClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriveClient>(value),
    );
  }
}

String _$driveClientHash() => r'e3d820633d31adb224e4ec8b64fb546f09be8766';

/// revoke 等に使う汎用 http クライアント（テスト差し替え用に分離）。

@ProviderFor(httpClient)
const httpClientProvider = HttpClientProvider._();

/// revoke 等に使う汎用 http クライアント（テスト差し替え用に分離）。

final class HttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// revoke 等に使う汎用 http クライアント（テスト差し替え用に分離）。
  const HttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return httpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$httpClientHash() => r'7ec49beae0f15115de79f9aa98dbd250130e26d8';
