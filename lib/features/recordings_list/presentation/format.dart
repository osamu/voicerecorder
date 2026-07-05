import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';

/// 一覧・再生画面の表示整形ヘルパ。
abstract final class RecordingFormat {
  // 数値のみのパターンのためロケール非依存（DateSymbols 初期化不要）。
  static final DateFormat _dateTime = DateFormat('yyyy/MM/dd HH:mm');

  /// 行タイトル。タイトルが空なら日時を代わりに表示する。
  static String title(Recording r) {
    final t = r.title.trim();
    if (t.isNotEmpty) return t;
    return dateTime(r);
  }

  /// 録音日時（表示用）。startedAt は ISO8601+TZ。
  static String dateTime(Recording r) {
    final dt = DateTime.tryParse(r.startedAt);
    if (dt == null) return r.startedAt;
    return _dateTime.format(dt.toLocal());
  }

  /// 録音時間（H:MM:SS もしくは M:SS）。
  static String duration(int millis) {
    final d = Duration(milliseconds: millis);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$m:$ss';
  }

  /// ファイルサイズ（B / KB / MB / GB）。
  static String size(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final str = unit == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$str ${units[unit]}';
  }

  /// 位置/長さの mm:ss 表記（再生シークバー用）。
  static String clock(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
