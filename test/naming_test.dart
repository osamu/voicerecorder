import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/database/tables.dart';
import 'package:voicerecorder/core/naming/naming.dart';

void main() {
  group('sanitizeTitle', () {
    test('禁止文字を除去する', () {
      expect(Naming.sanitizeTitle(r'a/b\c:d*e?f"g<h>i|j'), 'abcdefghij');
    });

    test('連続空白を単一化する', () {
      expect(Naming.sanitizeTitle('経営  会議  速報'), '経営 会議 速報');
    });

    test('制御文字を除去する（スペース化しない・仕様どおり）', () {
      expect(Naming.sanitizeTitle('行1\n\t行2'), '行1行2');
    });

    test('前後の空白をトリムする', () {
      expect(Naming.sanitizeTitle('  会議  '), '会議');
    });

    test('80文字上限で切り詰める', () {
      final long = 'あ' * 100;
      expect(Naming.sanitizeTitle(long).length, 80);
    });

    test('空文字はそのまま空', () {
      expect(Naming.sanitizeTitle('   '), '');
    });
  });

  group('extensionForCodec', () {
    test('iOS は m4a', () {
      expect(Naming.extensionForCodec(Codec.aacM4a), 'm4a');
    });
    test('Android は opus', () {
      expect(Naming.extensionForCodec(Codec.oggOpus), 'opus');
    });
  });

  group('timestampPrefix / fileName', () {
    final started = DateTime(2026, 7, 4, 14, 30, 5);

    test('日時プレフィックスは秒まで含む', () {
      expect(Naming.timestampPrefix(started), '2026-07-04_14-30-05');
    });

    test('タイトル付き音声ファイル名', () {
      expect(
        Naming.audioFileName(started, Codec.aacM4a, title: '経営会議'),
        '2026-07-04_14-30-05_経営会議.m4a',
      );
    });

    test('タイトル無しは日時のみ', () {
      expect(
        Naming.audioFileName(started, Codec.oggOpus),
        '2026-07-04_14-30-05.opus',
      );
    });

    test('txt は音声と同じベース名', () {
      expect(
        Naming.txtFileName(started, title: '経営会議'),
        '2026-07-04_14-30-05_経営会議.txt',
      );
    });

    test('禁止文字を含むタイトルもサニタイズされる', () {
      expect(
        Naming.audioFileName(started, Codec.aacM4a, title: 'a/b:c'),
        '2026-07-04_14-30-05_abc.m4a',
      );
    });
  });

  group('Drive フォルダパス', () {
    final started = DateTime(2026, 7, 4, 14, 30, 5);

    test('年 / 年-月 のセグメント', () {
      expect(Naming.driveFolderSegments(started), ['2026', '2026-07']);
    });

    test('パスキーは CloudRecorder 起点', () {
      expect(Naming.driveFolderPathKey(started), 'CloudRecorder/2026/2026-07');
    });
  });
}
