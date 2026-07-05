import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/security/secure_storage.dart';

/// 設定画面の Provider。

/// SecureStore（API キー・トークン）。統合/テストで override 可能。
final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

/// STT API キーが設定済みかどうか。
final sttApiKeyPresentProvider = FutureProvider<bool>((ref) {
  return ref.watch(secureStoreProvider).contains(SecureKeys.sttApiKey);
});

/// ストレージ使用量サマリ。
final storageUsageProvider = FutureProvider((ref) {
  return ref.watch(uploadControllerProvider).storageUsage();
});

/// 選択中の文字起こしエンジン id（未設定なら cloud_stt）。
final transcriptionEngineIdProvider = Provider<String>((ref) {
  final v = ref.watch(settingValueProvider(SettingsKeys.transcriptionEngineId));
  return v.maybeWhen(data: (s) => s ?? 'cloud_stt', orElse: () => 'cloud_stt');
});

/// 選択中の言語（未設定なら ja-JP）。
final transcriptionLocaleIdProvider = Provider<String>((ref) {
  final v = ref.watch(settingValueProvider(SettingsKeys.transcriptionLocaleId));
  return v.maybeWhen(data: (s) => s ?? 'ja-JP', orElse: () => 'ja-JP');
});

/// 選択中エンジンの対応言語一覧。
final supportedLocalesProvider = FutureProvider<List<String>>((ref) {
  final engineId = ref.watch(transcriptionEngineIdProvider);
  return ref.watch(transcriptionControllerProvider).supportedLocales(engineId);
});
