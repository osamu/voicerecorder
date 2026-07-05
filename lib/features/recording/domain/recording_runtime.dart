/// 録音の実行状態（ドメイン層の真実。UI 層はこれを射影する）。
enum RecordingStatus {
  /// 非録音。
  idle,

  /// 録音中。
  recording,

  /// 割り込みで一時的に停止中（自動再開待ち）。
  interrupted,

  /// 停止処理・確定保存中。
  finalizing,
}

/// 録音中バー・ボタン等が購読する実行時スナップショット（§10.2）。
class RecordingRuntime {
  const RecordingRuntime({
    required this.status,
    this.recordingId,
    this.groupStartedAt,
    this.title = '',
    this.segmentIndex = 1,
    this.elapsed = Duration.zero,
    this.storageWarning = false,
  });

  final RecordingStatus status;

  /// 現在（または直近）のセグメントの recordings.id。
  final String? recordingId;

  /// グループ先頭セグメントの開始時刻（セグメント命名の基準）。
  final DateTime? groupStartedAt;

  final String title;

  /// 1 始まり。2 以降は割り込み再開後のセグメント。
  final int segmentIndex;

  /// 現在セグメントの経過時間。
  final Duration elapsed;

  /// 空き容量が警告閾値を割っているか（§6.2）。
  final bool storageWarning;

  bool get isActive =>
      status == RecordingStatus.recording ||
      status == RecordingStatus.interrupted;

  static const idle = RecordingRuntime(status: RecordingStatus.idle);

  RecordingRuntime copyWith({
    RecordingStatus? status,
    String? recordingId,
    DateTime? groupStartedAt,
    String? title,
    int? segmentIndex,
    Duration? elapsed,
    bool? storageWarning,
  }) {
    return RecordingRuntime(
      status: status ?? this.status,
      recordingId: recordingId ?? this.recordingId,
      groupStartedAt: groupStartedAt ?? this.groupStartedAt,
      title: title ?? this.title,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      elapsed: elapsed ?? this.elapsed,
      storageWarning: storageWarning ?? this.storageWarning,
    );
  }
}

/// [RecordingService.start] の結果。警告付き開始かどうかを呼び出し側へ伝える。
class RecordingStartResult {
  const RecordingStartResult({
    required this.recordingId,
    required this.lowStorageWarning,
  });

  final String recordingId;

  /// 空き容量が閾値未満のまま開始したか（UI で警告表示する）。
  final bool lowStorageWarning;
}

/// 録音開始が拒否された理由。
enum RecordingStartDenied {
  /// 既に別の録音が進行中（多重録音排他 §6.5）。
  alreadyRecording,

  /// マイク権限が無い。
  permissionDenied,

  /// 空き容量が枯渇寸前で開始不可。
  outOfStorage,
}

/// 録音開始が拒否されたときに投げる例外。
class RecordingStartException implements Exception {
  const RecordingStartException(this.reason);
  final RecordingStartDenied reason;

  @override
  String toString() => 'RecordingStartException($reason)';
}
