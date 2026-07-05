import 'dart:io';

/// 文字起こしサブシステムの抽象化（DESIGN.md §8.2）。
///
/// 出力は [TranscriptionEvent] ストリームで全エンジン共通に統一し、
/// 入力は [StreamingTranscriptionEngine] / [BatchTranscriptionEngine] に分離する
/// （単一ファットインターフェースへは統合しない）。
/// ジョブは DB に永続化し、起動時に [BatchTranscriptionEngine.watch] で再購読する。

// ---------------------------------------------------------------------------
// 出力イベント — 全エンジン共通。UI/永続化はこのストリームだけを見る。
// ---------------------------------------------------------------------------

/// 文字起こしの出力イベント基底。
sealed class TranscriptionEvent {
  const TranscriptionEvent();
}

/// 暫定テキスト（Streaming 用 / Batch の途中結果）。
class TranscriptionPartial extends TranscriptionEvent {
  final String text;
  final bool isFinalSegment;
  const TranscriptionPartial(this.text, {this.isFinalSegment = false});
}

/// 進捗（0.0-1.0。不明なら null）。
class TranscriptionProgress extends TranscriptionEvent {
  final double? ratio;
  const TranscriptionProgress(this.ratio);
}

/// 確定全文（.txt の内容）。
class TranscriptionCompleted extends TranscriptionEvent {
  final String fullText;
  const TranscriptionCompleted(this.fullText);
}

/// 失敗。部分成功分があれば [partialText] に入れて「一部のみ」状態にする。
class TranscriptionFailed extends TranscriptionEvent {
  final String reason;
  final bool isRetryable;
  final String? partialText;
  const TranscriptionFailed(this.reason,
      {required this.isRetryable, this.partialText});
}

// ---------------------------------------------------------------------------
// capability（静的宣言）と availability（動的照会）の 2 層公開。
// ---------------------------------------------------------------------------

/// エンジンの音声入力モード。
enum AudioInputMode { feedsPcm, ownsMic, file }

/// 言語モード。
enum LanguageMode { fixedList, autoDetect }

/// エンジンの静的 capability 宣言。
class EngineCapability {
  final AudioInputMode audioInputMode;
  final Set<String> acceptedFormats; // 例 {'m4a', 'opus'}（file モードのみ意味を持つ）
  final int? maxFileSizeBytes; // 例 Whisper API: 25MB。null=無制限
  final LanguageMode languageMode;
  const EngineCapability({
    required this.audioInputMode,
    required this.acceptedFormats,
    required this.maxFileSizeBytes,
    required this.languageMode,
  });
}

/// 実行時の可用性。
class EngineAvailability {
  final bool available;
  final String? unavailableReason; // 'offline' | 'permissionDenied' | 'localeUnsupported' ...
  const EngineAvailability(this.available, [this.unavailableReason]);
}

// ---------------------------------------------------------------------------
// エンジン インターフェース群。
// ---------------------------------------------------------------------------

/// 全エンジン共通の基底。
abstract interface class TranscriptionEngine {
  String get id; // 'cloud_stt' | 'os_native' | 'whisper_cpp' ...
  String get displayName;
  EngineCapability get capability;

  /// 実行時の動的照会（ネット接続・OS権限・言語対応・モデルDL済み等）。
  Future<EngineAvailability> checkAvailability({String? localeId});

  /// 選択中エンジンが対応する言語一覧（設定画面の言語リスト用）。
  Future<List<String>> supportedLocales();
}

/// 入力IF その1: ストリーミング型（将来のリアルタイム用。MVP では実装しない）。
abstract interface class StreamingTranscriptionEngine
    implements TranscriptionEngine {
  Stream<TranscriptionEvent> start({required String localeId});
  Future<void> stop();
}

/// 入力IF その2: バッチ型（MVP の既定。録音ファイルを渡して後で結果受領）。
abstract interface class BatchTranscriptionEngine
    implements TranscriptionEngine {
  /// 投入。戻り値はシリアライズ可能な jobHandle（JSON文字列）— DB に永続化する。
  Future<String> submit(File audio, {String? localeId});

  /// jobHandle からイベントストリームを（再）購読。アプリ再起動後もこれで復帰する。
  Stream<TranscriptionEvent> watch(String jobHandle);

  Future<void> cancel(String jobHandle);
}
