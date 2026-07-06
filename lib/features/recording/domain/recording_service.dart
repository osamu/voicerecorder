import 'dart:async';
import 'dart:io' show Platform;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/audio_session/audio_session_manager.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/naming/naming.dart';
import '../../../core/security/app_logger.dart';
import 'foreground_controller.dart';
import 'local_notifier.dart';
import 'recorder_backend.dart';
import 'recording_paths.dart';
import 'recording_runtime.dart';
import 'recovery.dart';
import 'segment_naming.dart';
import 'storage_check.dart';

/// 録音＋データ保全のドメインサービス（DESIGN §6 / TODO Phase 2）。
///
/// 設計原則:
/// - Riverpod 非依存の plain Dart。BG isolate からも直接利用可能。
/// - 状態の single source of truth は DB（drift）。本サービスはメモリ状態を
///   「実行時スナップショット」として公開するのみで、永続状態はジョブ／録音行が正。
/// - 録音優先／文字起こしはベストエフォート。録音自体はサインイン不要。
///
/// 依存はすべてインタフェース越しに注入し、単体テスト可能にする。
class RecordingService {
  RecordingService({
    required AppDatabase db,
    required RecorderBackend recorder,
    required RecordingPaths paths,
    required ForegroundController foreground,
    required LocalNotifier notifier,
    required Stream<RecordingInterruption> interruptionEvents,
    FileProbe fileProbe = const IoFileProbe(),
    Future<void> Function()? activateSession,
    Future<void> Function()? deactivateSession,
    DateTime Function()? clock,
    Uuid? uuid,
    Codec? codecOverride,
  })  : _db = db,
        _recorder = recorder,
        _paths = paths,
        _foreground = foreground,
        _notifier = notifier,
        _interruptionEvents = interruptionEvents,
        _fileProbe = fileProbe,
        _activateSession = activateSession,
        _deactivateSession = deactivateSession,
        _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid(),
        _codec = codecOverride ?? _platformCodec();

  final AppDatabase _db;
  final RecorderBackend _recorder;
  final RecordingPaths _paths;
  final ForegroundController _foreground;
  final LocalNotifier _notifier;
  final Stream<RecordingInterruption> _interruptionEvents;
  final FileProbe _fileProbe;
  final Future<void> Function()? _activateSession;
  final Future<void> Function()? _deactivateSession;
  final DateTime Function() _clock;
  final Uuid _uuid;
  final Codec _codec;

  final _log = const AppLogger('recording');

  /// セグメント確定（正常停止・割り込み確定）直後に呼ばれるフック。
  ///
  /// 統合層（app 配線）が「即時アップロード（UploadQueue.uploadNow）＋
  /// 文字起こし投入（TranscriptionService.transcribe）」を注入する。
  /// plain Dart のコールバックであり、ドメイン層の Riverpod 非依存を保つ。
  /// フックの失敗は録音の確定保存に影響しない（録音優先）。
  void Function(String recordingId)? onSegmentFinalized;

  /// 経過時間・容量チェックの tick 間隔。
  static const Duration _tick = Duration(seconds: 1);

  /// 容量チェックの間隔（tick 何回ごとか）。
  static const int _storageCheckEveryTicks = 5;

  StreamSubscription<RecordingInterruption>? _interruptionSub;
  Timer? _ticker;
  int _tickCount = 0;

  // ---- 実行時状態（メモリ。永続状態は DB が正） ----
  RecordingRuntime _runtime = RecordingRuntime.idle;
  final _runtimeController = StreamController<RecordingRuntime>.broadcast();

  // 現在のセグメント情報。
  String? _currentRecordingId;
  String? _currentPath;
  DateTime? _segmentStartedAt; // 現在セグメント開始時刻
  DateTime? _groupStartedAt; // グループ先頭時刻（命名基準）
  String _currentTitle = '';
  int _segmentIndex = SegmentNaming.firstSegment;

  /// 実行時スナップショットのストリーム（UI が購読）。
  Stream<RecordingRuntime> get runtimeStream => _runtimeController.stream;

  /// 現在の実行時スナップショット。
  RecordingRuntime get runtime => _runtime;

  bool get isRecording => _runtime.isActive;

  static Codec _platformCodec() =>
      Platform.isIOS ? Codec.aacM4a : Codec.oggOpus;

  String get _nowIso => _clock().toIso8601String();

  // -------------------------------------------------------------------------
  // 初期化
  // -------------------------------------------------------------------------

  /// 割り込み購読を開始する。アプリ起動時に一度呼ぶ。
  Future<void> initialize() async {
    await _notifier.initialize();
    _interruptionSub ??= _interruptionEvents.listen(_onInterruption);
  }

  // -------------------------------------------------------------------------
  // 録音開始（FG 起点のみ）
  // -------------------------------------------------------------------------

  /// 録音を開始する。**必ずフォアグラウンド（画面表示中）から呼ぶこと**（§6.1）。
  ///
  /// 多重録音は排他（§6.5）。権限・空き容量を確認し、`recordings` 行を INSERT して
  /// から録音を開始する。空き容量が警告閾値未満でも開始は許可し、枯渇寸前のみ拒否。
  ///
  /// 拒否時は [RecordingStartException] を投げる。
  Future<RecordingStartResult> start({String title = ''}) async {
    if (_runtime.isActive) {
      throw const RecordingStartException(RecordingStartDenied.alreadyRecording);
    }

    if (!await _recorder.hasPermission()) {
      throw const RecordingStartException(RecordingStartDenied.permissionDenied);
    }

    await _paths.ensureDir();

    // 空き容量チェック（§6.2）。枯渇寸前なら開始拒否。
    var lowStorage = false;
    final free = await _fileProbe.freeSpaceBytes(_paths.dirPath);
    if (free != null) {
      final runtimeAction = StorageCheck.assessRuntime(free);
      if (runtimeAction == StorageRuntimeAction.safeClose) {
        throw const RecordingStartException(RecordingStartDenied.outOfStorage);
      }
      lowStorage = StorageCheck.assessStart(free) == StorageStartDecision.warn;
    }

    final cleanTitle = Naming.sanitizeTitle(title);
    final startedAt = _clock();
    _groupStartedAt = startedAt;
    _segmentIndex = SegmentNaming.firstSegment;
    _currentTitle = cleanTitle;

    final recordingId = await _insertSegmentRow(
      startedAt: startedAt,
      title: cleanTitle,
      segmentIndex: _segmentIndex,
    );

    await _beginRecorder(startedAt: startedAt);

    await _foreground.startRecordingNotification(
      title: cleanTitle.isEmpty ? 'CloudRecorder' : cleanTitle,
    );

    _updateRuntime(
      _runtime.copyWith(
        status: RecordingStatus.recording,
        recordingId: recordingId,
        groupStartedAt: startedAt,
        title: cleanTitle,
        segmentIndex: _segmentIndex,
        elapsed: Duration.zero,
        storageWarning: lowStorage,
      ),
    );

    _startTicker();

    return RecordingStartResult(
      recordingId: recordingId,
      lowStorageWarning: lowStorage,
    );
  }

  /// 録音行を INSERT し、ファイルパスを確定する。生成した recordingId を返す。
  Future<String> _insertSegmentRow({
    required DateTime startedAt,
    required String title,
    required int segmentIndex,
  }) async {
    final id = _uuid.v4();
    final fileName = SegmentNaming.segmentAudioFileName(
      _groupStartedAt ?? startedAt,
      _codec,
      title: title,
      segmentIndex: segmentIndex,
    );
    final path = _paths.pathFor(fileName);
    _currentRecordingId = id;
    _currentPath = path;

    await _db.recordingsDao.insertRecording(
      RecordingsCompanion(
        id: Value(id),
        startedAt: Value(startedAt.toIso8601String()),
        durationMs: const Value(0), // 停止まで 0（未クローズマーカー §6.2）
        localPath: Value(path),
        title: Value(title),
        codec: Value(_codec),
        uploadState: const Value(UploadState.pending),
        transcriptState: const Value(TranscriptState.off),
        createdAt: Value(_nowIso),
        updatedAt: Value(_nowIso),
      ),
    );
    return id;
  }

  Future<void> _beginRecorder({required DateTime startedAt}) async {
    if (_activateSession != null) {
      await _activateSession();
    }
    _segmentStartedAt = startedAt;
    await _recorder.start(path: _currentPath!, codec: _codec);
  }

  // -------------------------------------------------------------------------
  // 録音停止
  // -------------------------------------------------------------------------

  /// 現在の録音を停止し、確定保存＋キュー投入する。
  Future<void> stop() async {
    if (!_runtime.isActive) return;
    _stopTicker();
    _updateRuntime(_runtime.copyWith(status: RecordingStatus.finalizing));

    await _finalizeCurrentSegment();

    await _foreground.stopRecordingNotification();
    if (_deactivateSession != null) {
      await _deactivateSession();
    }

    _clearCurrent();
    _updateRuntime(RecordingRuntime.idle);
  }

  /// 現在セグメントを正常クローズし、duration/size を確定、upload/transcription
  /// ジョブを投入する。割り込み時にも呼ばれる（その時点までを確定保存）。
  Future<void> _finalizeCurrentSegment() async {
    final id = _currentRecordingId;
    final path = _currentPath;
    final segStart = _segmentStartedAt;
    if (id == null || path == null || segStart == null) return;

    try {
      await _recorder.stop();
    } catch (e) {
      _log.error('recorderStop', recordingId: id, error: e);
    }

    final durationMs = _clock().difference(segStart).inMilliseconds;
    final sizeBytes = await _fileProbe.sizeOf(path);

    await _db.recordingsDao.updateRecording(
      id,
      RecordingsCompanion(
        durationMs: Value(durationMs <= 0 ? 1 : durationMs),
        sizeBytes: Value(sizeBytes),
      ),
    );

    await _enqueueJobsFor(id);

    // 統合層のフック（即時アップロード＋文字起こし投入）。失敗しても録音の
    // 確定保存には影響させない（録音優先・DB のジョブは既に投入済み）。
    try {
      onSegmentFinalized?.call(id);
    } catch (e) {
      _log.error('onSegmentFinalized', recordingId: id, error: e);
    }
  }

  /// 確定済み録音に対しアップロード（audio）ジョブを投入する。
  ///
  /// 冪等: upsertJob により (recordingId, audio) は重複投入されない。
  /// 文字起こしジョブの投入は [onSegmentFinalized] フック経由で
  /// TranscriptionService.transcribe に一本化する（二重投入防止）。
  Future<void> _enqueueJobsFor(String recordingId) async {
    // 音声アップロードジョブ（必須。録音優先）。
    await _db.uploadJobsDao.upsertJob(
      UploadJobsCompanion(
        id: Value(_uuid.v4()),
        recordingId: Value(recordingId),
        kind: const Value(UploadJobKind.audio),
        state: const Value(UploadJobState.pending),
        createdAt: Value(_nowIso),
        updatedAt: Value(_nowIso),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 割り込み処理（§6.2）
  // -------------------------------------------------------------------------

  Future<void> _onInterruption(RecordingInterruption event) async {
    switch (event.phase) {
      case RecordingInterruptionPhase.began:
        await _handleInterruptionBegan();
      case RecordingInterruptionPhase.ended:
        await _handleInterruptionEnded(shouldResume: event.shouldResume);
    }
  }

  /// 割り込み開始: その時点までを確定保存し、interrupted 状態へ。
  Future<void> _handleInterruptionBegan() async {
    if (_runtime.status != RecordingStatus.recording) return;
    _stopTicker();
    await _finalizeCurrentSegment();
    _updateRuntime(_runtime.copyWith(status: RecordingStatus.interrupted));
  }

  /// 割り込み終了: 自動再開を試みる。再開分は次セグメント（_partN）。
  /// 再開不可なら即ローカル通知し、idle へ戻す。
  Future<void> _handleInterruptionEnded({required bool shouldResume}) async {
    if (_runtime.status != RecordingStatus.interrupted) return;

    if (!shouldResume) {
      await _failResume();
      return;
    }

    try {
      // 空き容量が枯渇していれば再開しない。
      final free = await _fileProbe.freeSpaceBytes(_paths.dirPath);
      if (free != null &&
          StorageCheck.assessRuntime(free) ==
              StorageRuntimeAction.safeClose) {
        await _failResume();
        return;
      }

      final resumedAt = _clock();
      _segmentIndex += 1;
      final newId = await _insertSegmentRow(
        startedAt: resumedAt,
        title: _currentTitle,
        segmentIndex: _segmentIndex,
      );
      await _beginRecorder(startedAt: resumedAt);

      await _foreground.startRecordingNotification(
        title: _currentTitle.isEmpty ? 'CloudRecorder' : _currentTitle,
      );

      _updateRuntime(
        _runtime.copyWith(
          status: RecordingStatus.recording,
          recordingId: newId,
          segmentIndex: _segmentIndex,
          elapsed: Duration.zero,
        ),
      );
      _startTicker();
    } catch (e) {
      _log.error('resumeFailed', recordingId: _currentRecordingId, error: e);
      await _failResume();
    }
  }

  Future<void> _failResume() async {
    await _foreground.stopRecordingNotification();
    if (_deactivateSession != null) {
      await _deactivateSession();
    }
    await _notifier.notifyRecordingInterrupted();
    _clearCurrent();
    _updateRuntime(RecordingRuntime.idle);
  }

  // -------------------------------------------------------------------------
  // 定期 tick（経過時間更新＋容量チェック）
  // -------------------------------------------------------------------------

  void _startTicker() {
    _tickCount = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (_) => _onTick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _onTick() async {
    final segStart = _segmentStartedAt;
    if (segStart == null || _runtime.status != RecordingStatus.recording) {
      return;
    }
    _tickCount++;
    final elapsed = _clock().difference(segStart);
    _updateRuntime(_runtime.copyWith(elapsed: elapsed));
    unawaited(_foreground.updateElapsed(elapsed, title: _currentTitle));

    if (_tickCount % _storageCheckEveryTicks == 0) {
      await _checkStorageDuringRecording();
    }
  }

  Future<void> _checkStorageDuringRecording() async {
    final free = await _fileProbe.freeSpaceBytes(_paths.dirPath);
    if (free == null) return;
    switch (StorageCheck.assessRuntime(free)) {
      case StorageRuntimeAction.keepGoing:
        if (_runtime.storageWarning) {
          _updateRuntime(_runtime.copyWith(storageWarning: false));
        }
      case StorageRuntimeAction.warn:
        if (!_runtime.storageWarning) {
          _updateRuntime(_runtime.copyWith(storageWarning: true));
        }
      case StorageRuntimeAction.safeClose:
        _log.warning('storage exhausted; safe-closing recording');
        await stop();
    }
  }

  // -------------------------------------------------------------------------
  // 起動時リカバリ（§6.2 / §12）
  // -------------------------------------------------------------------------

  /// 未クローズ録音を検出し、可能な範囲で確定してキュー投入する。
  ///
  /// アプリ起動シーケンス（§12 手順2）から呼ばれる想定。処理した件数を返す。
  Future<int> recoverInterruptedRecordings() async {
    final all = await _db.recordingsDao.watchAll().first;
    var recovered = 0;

    for (final rec in all) {
      if (!Recovery.isUnclosed(rec)) continue;

      final path = rec.localPath;
      final exists = path != null && await _fileProbe.exists(path);
      final size = exists ? await _fileProbe.sizeOf(path) : 0;
      final assessment =
          Recovery.assess(rec, fileExists: exists, fileSizeBytes: size);

      switch (assessment.action) {
        case RecoveryAction.none:
          break;
        case RecoveryAction.finalizeFromFile:
          await _finalizeRecovered(rec, assessment);
          recovered++;
        case RecoveryAction.markMissing:
          // 実体消失。failed 扱いにはしない（§6.2）。localPath を NULL 化。
          await _db.recordingsDao.setLocalPath(rec.id, null);
      }
    }
    _log.info('recovery complete: $recovered recording(s) restored');
    return recovered;
  }

  Future<void> _finalizeRecovered(
    Recording rec,
    RecoveryAssessment assessment,
  ) async {
    final title = rec.title.isEmpty ? kRecoveredTitle : rec.title;
    await _db.recordingsDao.updateRecording(
      rec.id,
      RecordingsCompanion(
        durationMs: Value(
          assessment.estimatedDurationMs <= 0
              ? 1
              : assessment.estimatedDurationMs,
        ),
        sizeBytes: Value(assessment.sizeBytes),
        title: Value(title),
        uploadState: const Value(UploadState.pending),
      ),
    );
    // 冪等にアップロード（audio）ジョブを投入。
    await _db.uploadJobsDao.upsertJob(
      UploadJobsCompanion(
        id: Value(_uuid.v4()),
        recordingId: Value(rec.id),
        kind: const Value(UploadJobKind.audio),
        state: const Value(UploadJobState.pending),
        createdAt: Value(_nowIso),
        updatedAt: Value(_nowIso),
      ),
    );
  }

  /// リカバリで復元した録音のタイトル既定値。
  static const String kRecoveredTitle = '中断された録音を復元しました';

  // -------------------------------------------------------------------------
  // 後始末
  // -------------------------------------------------------------------------

  void _clearCurrent() {
    _currentRecordingId = null;
    _currentPath = null;
    _segmentStartedAt = null;
    _groupStartedAt = null;
    _currentTitle = '';
    _segmentIndex = SegmentNaming.firstSegment;
  }

  void _updateRuntime(RecordingRuntime next) {
    _runtime = next;
    if (!_runtimeController.isClosed) {
      _runtimeController.add(next);
    }
  }

  Future<void> dispose() async {
    _stopTicker();
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    await _recorder.dispose();
    await _runtimeController.close();
  }
}
