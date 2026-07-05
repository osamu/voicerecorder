part of '../app_database.dart';

/// upload_jobs テーブルの DAO。UNIQUE(recordingId, kind) で冪等化する。
@DriftAccessor(tables: [UploadJobs])
class UploadJobsDao extends DatabaseAccessor<AppDatabase>
    with _$UploadJobsDaoMixin {
  UploadJobsDao(super.db);

  String get _nowIso => DateTime.now().toIso8601String();

  /// ジョブを投入する。同一 (recordingId, kind) が既にあれば内容を更新（冪等）。
  Future<void> upsertJob(UploadJobsCompanion entry) {
    return into(uploadJobs).insert(
      entry,
      onConflict: DoUpdate(
        (_) => entry.copyWith(updatedAt: Value(_nowIso)),
        target: [uploadJobs.recordingId, uploadJobs.kind],
      ),
    );
  }

  /// (recordingId, kind) で 1 件取得。
  Future<UploadJob?> getByRecordingAndKind(
      String recordingId, UploadJobKind kind) {
    return (select(uploadJobs)
          ..where((t) =>
              t.recordingId.equals(recordingId) & t.kind.equalsValue(kind)))
        .getSingleOrNull();
  }

  /// 対象録音のジョブ一覧。
  Future<List<UploadJob>> getByRecording(String recordingId) {
    return (select(uploadJobs)
          ..where((t) => t.recordingId.equals(recordingId)))
        .get();
  }

  /// 実行可能な pending ジョブを watch（audio を transcript より優先、古い順）。
  /// nextRetryAt 未設定、または現在時刻を過ぎたもののみ。
  Stream<List<UploadJob>> watchRunnable() {
    final nowIso = DateTime.now().toIso8601String();
    return (select(uploadJobs)
          ..where((t) =>
              t.state.equalsValue(UploadJobState.pending) &
              (t.nextRetryAt.isNull() |
                  t.nextRetryAt.isSmallerOrEqualValue(nowIso)))
          ..orderBy([
            (t) => OrderingTerm.asc(t.kind), // audio が transcript より前
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  /// pending / retryableFailed のジョブを watch（バッジ・件数用）。
  Stream<List<UploadJob>> watchOutstanding() {
    return (select(uploadJobs)
          ..where((t) =>
              t.state.equalsValue(UploadJobState.pending) |
              t.state.equalsValue(UploadJobState.retryableFailed)))
        .watch();
  }

  /// 恒久失敗ジョブを watch（要対応バッジ用）。
  Stream<List<UploadJob>> watchPermanentFailed() {
    return (select(uploadJobs)
          ..where((t) => t.state.equalsValue(UploadJobState.permanentFailed)))
        .watch();
  }

  /// ジョブを更新（updatedAt 自動更新）。
  Future<void> updateJob(String id, UploadJobsCompanion entry) {
    return (update(uploadJobs)..where((t) => t.id.equals(id)))
        .write(entry.copyWith(updatedAt: Value(_nowIso)));
  }

  /// 状態のみ更新。
  Future<void> updateState(String id, UploadJobState state) =>
      updateJob(id, UploadJobsCompanion(state: Value(state)));

  /// 中断（uploading のまま残った）ジョブを pending に戻す（起動時リカバリ §12）。
  Future<int> resetStuckUploading() {
    return (update(uploadJobs)
          ..where((t) => t.state.equalsValue(UploadJobState.uploading)))
        .write(UploadJobsCompanion(
      state: const Value(UploadJobState.pending),
      updatedAt: Value(_nowIso),
    ));
  }

  /// ジョブ削除（録音の未アップ削除時など）。
  Future<int> deleteJob(String id) =>
      (delete(uploadJobs)..where((t) => t.id.equals(id))).go();
}
