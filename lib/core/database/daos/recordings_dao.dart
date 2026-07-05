part of '../app_database.dart';

/// recordings テーブルの DAO。一覧 UI はここの watch* を購読する。
@DriftAccessor(tables: [Recordings])
class RecordingsDao extends DatabaseAccessor<AppDatabase>
    with _$RecordingsDaoMixin {
  RecordingsDao(super.db);

  String get _nowIso => DateTime.now().toIso8601String();

  /// 録音行を挿入する（録音開始時）。
  Future<void> insertRecording(RecordingsCompanion entry) =>
      into(recordings).insert(entry);

  /// 挿入または置換（リカバリ・再投入用）。
  Future<void> upsertRecording(RecordingsCompanion entry) =>
      into(recordings).insertOnConflictUpdate(entry);

  /// id で 1 件取得。
  Future<Recording?> getById(String id) =>
      (select(recordings)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// 一覧用: 全件を録音開始時刻の新しい順で watch。
  Stream<List<Recording>> watchAll() {
    return (select(recordings)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  /// 1 件の変更を watch（詳細・再生画面用）。
  Stream<Recording?> watchById(String id) =>
      (select(recordings)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  /// 任意カラムを更新（updatedAt は自動更新）。
  Future<void> updateRecording(String id, RecordingsCompanion entry) {
    return (update(recordings)..where((t) => t.id.equals(id)))
        .write(entry.copyWith(updatedAt: Value(_nowIso)));
  }

  /// アップロード状態バッジ（射影値）を更新。
  Future<void> updateUploadState(String id, UploadState state) {
    return updateRecording(id, RecordingsCompanion(uploadState: Value(state)));
  }

  /// 文字起こし状態バッジ（射影値）を更新。
  Future<void> updateTranscriptState(String id, TranscriptState state) {
    return updateRecording(
        id, RecordingsCompanion(transcriptState: Value(state)));
  }

  /// ローカルファイルパスを設定（逼迫時削除で NULL にする等）。
  Future<void> setLocalPath(String id, String? path) {
    return updateRecording(id, RecordingsCompanion(localPath: Value(path)));
  }

  /// 録音行を削除（FK cascade で関連ジョブも削除される）。
  Future<int> deleteRecording(String id) =>
      (delete(recordings)..where((t) => t.id.equals(id))).go();

  /// 逼迫時自動削除の候補: アップロード完了済み・ローカル実体あり・古い順（§7.7）。
  /// 未アップロード録音は決して含めない。
  Future<List<Recording>> getReclaimableOldestFirst() {
    return (select(recordings)
          ..where((t) =>
              t.uploadState.equalsValue(UploadState.done) &
              t.localPath.isNotNull())
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
  }
}
