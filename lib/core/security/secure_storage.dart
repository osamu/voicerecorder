import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 機微情報（OAuth トークン・STT API キー）の保存キー定数。
/// shared_preferences や drift settings には絶対に置かない（§9）。
abstract final class SecureKeys {
  /// Google OAuth アクセストークン。
  static const String googleAccessToken = 'google_access_token';

  /// Google OAuth リフレッシュトークン（取得できる場合）。
  static const String googleRefreshToken = 'google_refresh_token';

  /// アクセストークンの有効期限（ISO8601）。
  static const String googleTokenExpiry = 'google_token_expiry';

  /// クラウド STT の API キー。
  static const String sttApiKey = 'stt_api_key';
}

/// flutter_secure_storage の薄いラッパ。
///
/// iOS Keychain は firstUnlock（this-device-only）、Android は EncryptedSharedPreferences
/// を用い、BG 録音・アップロードと両立しつつ端末外複製を防ぐ（§9）。
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  /// 値を読み出す（未設定なら null）。
  Future<String?> read(String key) => _storage.read(key: key);

  /// 値を書き込む。null を渡した場合は削除する。
  Future<void> write(String key, String? value) {
    if (value == null) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }

  /// 値を削除する。
  Future<void> delete(String key) => _storage.delete(key: key);

  /// 全消去（サインアウト時などに使用）。
  Future<void> deleteAll() => _storage.deleteAll();

  /// キーの存在確認。
  Future<bool> contains(String key) => _storage.containsKey(key: key);
}
