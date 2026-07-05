/// アプリの認証状態（UI 表示・キュー制御用の投影）。
///
/// Riverpod 非依存のドメイン型。詳細なトークンは保持せず、UI に必要な最小情報
/// （サインイン有無・表示名・メール）のみを持つ（§9 のログ/機微情報ポリシー）。
sealed class AuthState {
  const AuthState();
}

/// 未サインイン。録音自体は可能だが Drive 連携は未設定（バッジ「Drive未設定」）。
class AuthSignedOut extends AuthState {
  const AuthSignedOut();

  @override
  String toString() => 'AuthSignedOut';
}

/// サインイン済み。Drive 連携が有効。
class AuthSignedIn extends AuthState {
  const AuthSignedIn({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// Google アカウントの安定 ID。
  final String userId;

  /// メールアドレス（UI 表示用）。
  final String email;

  /// 表示名（任意）。
  final String? displayName;

  /// アイコン URL（任意）。
  final String? photoUrl;

  @override
  String toString() => 'AuthSignedIn(email set)';
}
