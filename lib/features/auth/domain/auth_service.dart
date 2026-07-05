import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/database/app_database.dart';
import '../../../core/drive/drive_client.dart';
import '../../../core/drive/drive_http.dart';
import '../../../core/security/app_logger.dart';
import '../../../core/security/secure_storage.dart';
import 'auth_state.dart';

/// google_sign_in v7 ＋ googleapis_auth を用いた認証サービス（DESIGN.md §9）。
///
/// 責務:
/// - `drive.file` スコープのみでのサインイン / サインアウト / silent restore。
/// - アクセストークンを [SecureStore]（flutter_secure_storage）へ保存し、
///   サインアウト時に Google の revoke エンドポイントを呼ぶ。
/// - 認証状態の [Stream] を公開（UI・キュー制御が購読）。
/// - サインアウト時に未アップ N 件を数えて返す（キューは破棄しない・§7.5）。
/// - Drive クライアント向けに認証済み [http.Client] を供給する。
///
/// Riverpod 非依存。BG isolate からドメイン層として直接利用できる
/// （ただし google_sign_in のプラットフォーム呼び出しは前景を想定）。
class AuthService {
  AuthService({
    required SecureStore secureStore,
    required UploadJobsDao uploadJobsDao,
    http.Client? revokeClient,
    GoogleSignIn? googleSignIn,
    AppLogger? logger,
  })  : _secureStore = secureStore,
        _uploadJobsDao = uploadJobsDao,
        _revokeClient = revokeClient ?? http.Client(),
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _logger = logger ?? const AppLogger('auth');

  final SecureStore _secureStore;
  final UploadJobsDao _uploadJobsDao;
  final http.Client _revokeClient;
  final GoogleSignIn _googleSignIn;
  final AppLogger _logger;

  static const List<String> _scopes = [DriveEndpoints.driveFileScope];

  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  GoogleSignInAccount? _currentAccount;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventSub;

  /// 認証済み http クライアントのキャッシュ（トークンごとに 1 つ）。
  http.Client? _cachedAuthClient;
  String? _cachedAuthToken;

  bool _initialized = false;

  /// 認証状態の変化を購読する（初期値は現在状態）。
  Stream<AuthState> get authStateChanges async* {
    yield _snapshot();
    yield* _stateController.stream;
  }

  /// 現在の認証状態（同期スナップショット）。
  AuthState get currentState => _snapshot();

  /// サインイン済みか。
  bool get isSignedIn => _currentAccount != null;

  /// google_sign_in の初期化とイベント購読。アプリ起動時に一度だけ呼ぶ。
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_initialized) {
      return;
    }
    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _eventSub = _googleSignIn.authenticationEvents.listen(
      _onAuthEvent,
      onError: (Object e) => _logger.error('authEvent', error: e),
    );
    _initialized = true;
  }

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _currentAccount = event.user;
        _emit();
      case GoogleSignInAuthenticationEventSignOut():
        _currentAccount = null;
        _invalidateAuthClient();
        _emit();
    }
  }

  /// 対話的サインイン。`drive.file` スコープを要求しトークンを保存する。
  ///
  /// 認可（authorization）まで完了させ、以降 [authorizedClient] が silent に
  /// トークンを取得できる状態にする。
  Future<AuthState> signIn() async {
    if (!_googleSignIn.supportsAuthenticate()) {
      throw StateError('authenticate() not supported on this platform');
    }
    final account = await _googleSignIn.authenticate(scopeHint: _scopes);
    _currentAccount = account;
    // 認可を対話的に取得（スコープ未許可なら同意画面）。
    final authz = await account.authorizationClient.authorizeScopes(_scopes);
    await _persistAccessToken(authz.accessToken);
    _emit();
    return _snapshot();
  }

  /// silent restore（最小 UI）。前回サインインを復元できれば状態を更新する。
  ///
  /// 復元できなかった場合は [AuthSignedOut] を返す（例外は投げない）。
  Future<AuthState> restoreSession() async {
    try {
      final future = _googleSignIn.attemptLightweightAuthentication();
      final account = future == null ? null : await future;
      if (account != null) {
        _currentAccount = account;
        // silent に認可トークンを取得できれば保存（取れなければ後続で対話要求）。
        final authz =
            await account.authorizationClient.authorizationForScopes(_scopes);
        if (authz != null) {
          await _persistAccessToken(authz.accessToken);
        }
        _emit();
      }
    } catch (e) {
      _logger.error('restoreSession', error: e);
    }
    return _snapshot();
  }

  /// サインアウト。未アップ N 件を数えて返す（キューは破棄しない・§7.5）。
  ///
  /// 手順: (1) 未アップ件数集計 → (2) revoke エンドポイント呼び出し →
  /// (3) SDK disconnect（SDK 側の認可失効＋サインアウト）→ (4) トークン破棄。
  Future<int> signOut() async {
    final outstanding = await unuploadedCount();
    final token = await _secureStore.read(SecureKeys.googleAccessToken);
    if (token != null && token.isNotEmpty) {
      await revokeToken(token);
    }
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // revoke 済みなら SDK disconnect 失敗は致命的でない。
      _logger.error('signOutDisconnect', error: e);
    }
    await _clearTokens();
    _currentAccount = null;
    _invalidateAuthClient();
    _emit();
    return outstanding;
  }

  /// pending / retryableFailed（＝未アップ）ジョブ件数（§7.5「未アップ N 件」）。
  Future<int> unuploadedCount() async {
    final jobs = await _uploadJobsDao.watchOutstanding().first;
    return jobs.length;
  }

  /// Drive 用の認証済み http クライアントを返す。
  ///
  /// silent に `drive.file` の認可トークンを取得し、googleapis_auth の
  /// AuthClient を生成する。認可が得られない場合は [DriveAuthException]
  /// （再サインイン誘導）を投げる。トークン単位でクライアントをキャッシュする。
  Future<http.Client> authorizedClient() async {
    final account = _currentAccount;
    if (account == null) {
      throw const DriveAuthException('not signed in');
    }
    final authz =
        await account.authorizationClient.authorizationForScopes(_scopes);
    if (authz == null) {
      throw const DriveAuthException('drive authorization required');
    }
    await _persistAccessToken(authz.accessToken);
    if (_cachedAuthClient != null && _cachedAuthToken == authz.accessToken) {
      return _cachedAuthClient!;
    }
    _invalidateAuthClient();
    final client = authz.authClient(scopes: _scopes);
    _cachedAuthClient = client;
    _cachedAuthToken = authz.accessToken;
    return client;
  }

  /// Google の revoke エンドポイントを呼ぶ（§9）。失敗しても致命的ではない。
  /// （[signOut] から利用。ユニットテストからも直接呼べるよう公開している。）
  Future<void> revokeToken(String token) async {
    try {
      final resp = await _revokeClient.post(
        Uri.parse(DriveEndpoints.revoke),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'token': token},
      );
      if (resp.statusCode != 200) {
        _logger.warning('revoke returned ${resp.statusCode}');
      }
    } catch (e) {
      _logger.error('revokeToken', error: e);
    }
  }

  Future<void> _persistAccessToken(String token) async {
    await _secureStore.write(SecureKeys.googleAccessToken, token);
    // v7 は期限を返さないため保守的な推定値を保存（滞留判定の目安）。
    final estimated = DateTime.now().toUtc().add(const Duration(minutes: 50));
    await _secureStore.write(
        SecureKeys.googleTokenExpiry, estimated.toIso8601String());
  }

  Future<void> _clearTokens() async {
    await _secureStore.delete(SecureKeys.googleAccessToken);
    await _secureStore.delete(SecureKeys.googleRefreshToken);
    await _secureStore.delete(SecureKeys.googleTokenExpiry);
  }

  void _invalidateAuthClient() {
    _cachedAuthClient?.close();
    _cachedAuthClient = null;
    _cachedAuthToken = null;
  }

  AuthState _snapshot() {
    final account = _currentAccount;
    if (account == null) {
      return const AuthSignedOut();
    }
    return AuthSignedIn(
      userId: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  void _emit() {
    if (!_stateController.isClosed) {
      _stateController.add(_snapshot());
    }
  }

  /// リソース解放（provider dispose 時）。
  Future<void> dispose() async {
    await _eventSub?.cancel();
    _invalidateAuthClient();
    _revokeClient.close();
    await _stateController.close();
  }
}
