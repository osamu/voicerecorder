part of '../app_database.dart';

/// settings（key-value）テーブルの DAO。
/// OAuth トークンはここに置かず flutter_secure_storage を使う（§9）。
@DriftAccessor(tables: [SettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// 値を取得（未設定なら null）。
  Future<String?> getValue(String key) async {
    final row = await (select(settingsTable)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// 値の変更を watch。
  Stream<String?> watchValue(String key) {
    return (select(settingsTable)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  /// 値を設定（upsert）。
  Future<void> setValue(String key, String? value) {
    return into(settingsTable).insertOnConflictUpdate(
      SettingEntry(key: key, value: value),
    );
  }

  /// キーを削除。
  Future<int> removeValue(String key) =>
      (delete(settingsTable)..where((t) => t.key.equals(key))).go();
}

/// settings のキー定数（§5.4）。
abstract final class SettingsKeys {
  /// 自作 /VoiceRecorder/ ルートフォルダの Drive fileId。
  static const String driveRootFolderId = 'driveRootFolderId';

  /// 文字起こし ON/OFF（'true' / 'false'）。
  static const String transcriptionEnabled = 'transcriptionEnabled';

  /// 使用中の文字起こしエンジン id（例 'cloud_stt'）。
  static const String transcriptionEngineId = 'transcriptionEngineId';

  /// 文字起こし言語（例 'ja-JP'）。
  static const String transcriptionLocaleId = 'transcriptionLocaleId';
}
