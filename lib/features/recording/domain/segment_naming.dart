import '../../../core/database/tables.dart';
import '../../../core/naming/naming.dart';

/// 割り込み再開で生じる「セグメント」のファイル命名（§6.2）。
///
/// 1本の論理的な録音が着信・Siri などで中断され、再開されると、再開分は
/// **別セグメント**として保存される。セグメントは「グループの開始時刻」
/// （= 最初のセグメントの [DateTime]）を共有ベース名に使い、2本目以降へ
/// `_part2`, `_part3`… のサフィックスを付ける。
///
/// これにより Drive / 一覧上で同一会議のセグメント群が名前順で隣接し、
/// タイトルも継承される。`recordings` 行はセグメントごとに別レコードだが、
/// ファイル名の日時プレフィックスとタイトルはグループ先頭に揃える。
///
/// 純粋関数のみ（副作用なし）。単体テスト対象。
abstract final class SegmentNaming {
  /// セグメント番号は 1 始まり（1 = 最初の録音、サフィックス無し）。
  static const int firstSegment = 1;

  /// セグメント番号からファイル名サフィックスを返す。
  ///
  /// - 1 → `''`（サフィックス無し）
  /// - 2 → `'_part2'`
  /// - 3 → `'_part3'` …
  ///
  /// [segmentIndex] が 1 未満なら [ArgumentError]。
  static String segmentSuffix(int segmentIndex) {
    if (segmentIndex < firstSegment) {
      throw ArgumentError.value(
        segmentIndex,
        'segmentIndex',
        'must be >= $firstSegment',
      );
    }
    return segmentIndex <= firstSegment ? '' : '_part$segmentIndex';
  }

  /// グループ先頭時刻・タイトル・セグメント番号から拡張子無しベース名を返す。
  ///
  /// 例: `2026-07-04_14-30-05_経営会議_part2`
  static String segmentBaseName(
    DateTime groupStartedAt, {
    String title = '',
    int segmentIndex = firstSegment,
  }) {
    final base = Naming.baseName(groupStartedAt, title: title);
    return '$base${segmentSuffix(segmentIndex)}';
  }

  /// セグメントの音声ファイル名（拡張子付き）。
  ///
  /// 例: `2026-07-04_14-30-05_経営会議_part2.opus`
  static String segmentAudioFileName(
    DateTime groupStartedAt,
    Codec codec, {
    String title = '',
    int segmentIndex = firstSegment,
  }) {
    final ext = Naming.extensionForCodec(codec);
    return '${segmentBaseName(groupStartedAt, title: title, segmentIndex: segmentIndex)}.$ext';
  }
}
