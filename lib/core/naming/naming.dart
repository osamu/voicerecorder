import '../constants.dart';
import '../database/tables.dart';

/// ファイル名・Drive フォルダパスの命名規約（DESIGN.md §11）。
///
/// 基準時刻は「録音開始時点の端末ローカル時刻」。日時プレフィックスは不変で、
/// 改名で変更できるのはタイトル部のみ。音声と .txt はペアで同じベース名を使う。
abstract final class Naming {
  /// ファイル名に使えない文字（Windows/Drive 互換のため除去）。
  static final RegExp _forbidden = RegExp(r'[/\\:*?"<>|]');

  /// 制御文字（改行・タブ等）。
  static final RegExp _control = RegExp(r'[\x00-\x1F\x7F]');

  /// タイトルをサニタイズする。
  ///
  /// - 禁止文字 `/ \ : * ? " < > |` と制御文字を除去
  /// - 前後空白をトリム、連続空白を単一化
  /// - 最大 [AppConstants.maxTitleLength]（80）文字に切り詰め
  static String sanitizeTitle(String raw) {
    var s = raw.replaceAll(_forbidden, '').replaceAll(_control, '');
    // 連続する空白を単一スペースへ。
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > AppConstants.maxTitleLength) {
      s = s.substring(0, AppConstants.maxTitleLength).trim();
    }
    return s;
  }

  /// コーデックに対応する拡張子（ドット無し）。
  static String extensionForCodec(Codec codec) => switch (codec) {
        Codec.aacM4a => 'm4a',
        Codec.oggOpus => 'opus',
      };

  /// 日時プレフィックス `YYYY-MM-DD_HH-mm-ss`（ローカル時刻基準）。
  static String timestampPrefix(DateTime startedAt) {
    final y = startedAt.year.toString().padLeft(4, '0');
    final mo = startedAt.month.toString().padLeft(2, '0');
    final d = startedAt.day.toString().padLeft(2, '0');
    final h = startedAt.hour.toString().padLeft(2, '0');
    final mi = startedAt.minute.toString().padLeft(2, '0');
    final s = startedAt.second.toString().padLeft(2, '0');
    return '$y-$mo-${d}_$h-$mi-$s';
  }

  /// 拡張子を除いたベース名 `YYYY-MM-DD_HH-mm-ss[_タイトル]`。
  /// 音声・txt で共通のベース名を得るために使う。
  static String baseName(DateTime startedAt, {String title = ''}) {
    final clean = sanitizeTitle(title);
    final prefix = timestampPrefix(startedAt);
    return clean.isEmpty ? prefix : '${prefix}_$clean';
  }

  /// 音声ファイル名（例 `2026-07-04_14-30-05_経営会議.m4a`）。
  static String audioFileName(
    DateTime startedAt,
    Codec codec, {
    String title = '',
  }) {
    return '${baseName(startedAt, title: title)}.${extensionForCodec(codec)}';
  }

  /// 文字起こし .txt のファイル名（音声と同じベース名）。
  static String txtFileName(DateTime startedAt, {String title = ''}) {
    return '${baseName(startedAt, title: title)}.txt';
  }

  /// Drive の日付サブフォルダ階層（例 `['2026', '2026-07']`）。
  /// `/VoiceRecorder/<YYYY>/<YYYY-MM>/` の各セグメント。
  static List<String> driveFolderSegments(DateTime startedAt) {
    final y = startedAt.year.toString().padLeft(4, '0');
    final mo = startedAt.month.toString().padLeft(2, '0');
    return [y, '$y-$mo'];
  }

  /// フォルダ検索・appProperties 用のパスキー（例 `VoiceRecorder/2026/2026-07`）。
  static String driveFolderPathKey(DateTime startedAt) {
    return [AppConstants.driveRootFolderName, ...driveFolderSegments(startedAt)]
        .join('/');
  }
}
