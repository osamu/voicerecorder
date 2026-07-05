part of '../app_database.dart';

/// transcription_jobs テーブルの DAO。起動時に active ジョブを再購読する。
@DriftAccessor(tables: [TranscriptionJobs])
class TranscriptionJobsDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptionJobsDaoMixin {
  TranscriptionJobsDao(super.db);

  String get _nowIso => DateTime.now().toIso8601String();

  /// ジョブを挿入する（transcribe 開始時）。
  Future<void> insertJob(TranscriptionJobsCompanion entry) =>
      into(transcriptionJobs).insert(entry);

  /// id で 1 件取得。
  Future<TranscriptionJob?> getById(String id) =>
      (select(transcriptionJobs)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// 対象録音のジョブ一覧（新しい順）。
  Future<List<TranscriptionJob>> getByRecording(String recordingId) {
    return (select(transcriptionJobs)
          ..where((t) => t.recordingId.equals(recordingId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 起動時再購読の対象: submitted / running のジョブ（§5.3 / §12）。
  /// これらは jobHandle を持ち、watch(jobHandle) で結果受領を再開する。
  Future<List<TranscriptionJob>> getResumable() {
    return (select(transcriptionJobs)
          ..where((t) =>
              t.state.equalsValue(TranscriptionJobState.submitted) |
              t.state.equalsValue(TranscriptionJobState.running)))
        .get();
  }

  /// 処理中ジョブを watch（バッジ用）。
  Stream<List<TranscriptionJob>> watchActive() {
    return (select(transcriptionJobs)
          ..where((t) =>
              t.state.equalsValue(TranscriptionJobState.queued) |
              t.state.equalsValue(TranscriptionJobState.submitted) |
              t.state.equalsValue(TranscriptionJobState.running)))
        .watch();
  }

  /// ジョブを更新（updatedAt 自動更新）。
  Future<void> updateJob(String id, TranscriptionJobsCompanion entry) {
    return (update(transcriptionJobs)..where((t) => t.id.equals(id)))
        .write(entry.copyWith(updatedAt: Value(_nowIso)));
  }

  /// 状態のみ更新。
  Future<void> updateState(String id, TranscriptionJobState state) =>
      updateJob(id, TranscriptionJobsCompanion(state: Value(state)));

  /// jobHandle を保存して submitted に遷移（エンジン投入直後）。
  Future<void> markSubmitted(String id, String jobHandle) {
    return updateJob(
      id,
      TranscriptionJobsCompanion(
        jobHandle: Value(jobHandle),
        state: const Value(TranscriptionJobState.submitted),
      ),
    );
  }

  /// ジョブ削除。
  Future<int> deleteJob(String id) =>
      (delete(transcriptionJobs)..where((t) => t.id.equals(id))).go();
}
