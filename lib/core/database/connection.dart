import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// DB ファイル名（アプリ内部ストレージ限定・§9）。
const String kDatabaseFileName = 'voicerecorder.sqlite';

/// メイン isolate / BG isolate（workmanager・foreground_task）から
/// 同一の DB ファイルを開くための接続を生成する。
///
/// `NativeDatabase.createInBackground` により DB アクセスを専用 isolate に逃がし、
/// UI スレッドをブロックしない。WAL モードで複数コネクションからの読み書きに耐える。
/// 全 isolate が同一の絶対パスを使うことで single source of truth を共有する。
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$kDatabaseFileName');

    // sqlite3 v3.x 系ではネイティブライブラリがバンドルされるため、
    // 旧 sqlite3_flutter_libs の回避処理は不要。
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // 外部キー制約を有効化（FK による cascade 削除のため）。
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}
