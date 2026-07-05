import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

part 'app_database.g.dart';
part 'daos/recordings_dao.dart';
part 'daos/upload_jobs_dao.dart';
part 'daos/transcription_jobs_dao.dart';
part 'daos/settings_dao.dart';

/// アプリのメイン drift データベース。状態の single source of truth。
///
/// UI 層は各 DAO の watch* を StreamProvider で購読する。
/// BG isolate はドメイン層経由で本 DB を直接使用する（Riverpod 非依存）。
@DriftDatabase(
  tables: [Recordings, UploadJobs, TranscriptionJobs, SettingsTable],
  daos: [RecordingsDao, UploadJobsDao, TranscriptionJobsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  /// 本番用。アプリ内部ストレージの単一ファイルを開く。
  AppDatabase() : super(openConnection());

  /// テスト用など、任意の実行環境を注入するためのコンストラクタ。
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // 外部キー制約を有効化（テスト用 memory 接続でも確実に有効にする）。
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
