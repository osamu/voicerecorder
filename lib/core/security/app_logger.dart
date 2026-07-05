import 'dart:developer' as developer;

/// ログレベル。
enum LogLevel { debug, info, warning, error }

/// ログポリシーを内包したアプリ共通ロガー（§9）。
///
/// 絶対にログへ出さないもの:
/// - OAuth トークン・API キー等の機微情報
/// - 録音タイトル（ユーザー入力）
/// - 文字起こし本文
///
/// エラーは「種別（category）＋ recordingId（UUID）」までに限定する。
/// 例外オブジェクトは runtimeType のみを記録し、message は出さない
/// （message に機微情報が混入しうるため）。
class AppLogger {
  const AppLogger(this.tag);

  /// サブシステム名（例 'upload', 'recording', 'transcription'）。
  final String tag;

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warning(String message) => _log(LogLevel.warning, message);

  /// エラーを記録する。
  ///
  /// [category] はエラー種別の短い識別子（例 'driveAuth', 'networkTransient'）。
  /// [recordingId] は対象録音の UUID（任意）。
  /// [error] は runtimeType のみ記録され、内容（message）は出力しない。
  void error(
    String category, {
    String? recordingId,
    Object? error,
  }) {
    final buffer = StringBuffer('error=$category');
    if (recordingId != null) {
      buffer.write(' recordingId=$recordingId');
    }
    if (error != null) {
      // 例外の型のみ。message は機微情報混入の恐れがあるため出さない。
      buffer.write(' type=${error.runtimeType}');
    }
    _log(LogLevel.error, buffer.toString());
  }

  void _log(LogLevel level, String message) {
    // 実装は dart:developer.log に集約。将来クラッシュレポート等へ差し替え可能。
    developer.log(
      message,
      name: '${_levelLabel(level)}/$tag',
      level: _levelValue(level),
    );
  }

  static String _levelLabel(LogLevel level) => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warning => 'WARN',
        LogLevel.error => 'ERROR',
      };

  static int _levelValue(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}
