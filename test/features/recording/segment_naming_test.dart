import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/database/tables.dart';
import 'package:voicerecorder/features/recording/domain/segment_naming.dart';

void main() {
  final started = DateTime(2026, 7, 4, 14, 30, 5);

  group('SegmentNaming.segmentSuffix', () {
    test('最初のセグメントはサフィックス無し', () {
      expect(SegmentNaming.segmentSuffix(1), '');
    });

    test('2本目以降は _partN', () {
      expect(SegmentNaming.segmentSuffix(2), '_part2');
      expect(SegmentNaming.segmentSuffix(3), '_part3');
      expect(SegmentNaming.segmentSuffix(10), '_part10');
    });

    test('0 以下は ArgumentError', () {
      expect(() => SegmentNaming.segmentSuffix(0), throwsArgumentError);
      expect(() => SegmentNaming.segmentSuffix(-1), throwsArgumentError);
    });
  });

  group('SegmentNaming.segmentBaseName', () {
    test('タイトル付きの先頭セグメント', () {
      expect(
        SegmentNaming.segmentBaseName(started, title: '経営会議'),
        '2026-07-04_14-30-05_経営会議',
      );
    });

    test('2本目はグループ先頭時刻＋タイトル＋_part2', () {
      expect(
        SegmentNaming.segmentBaseName(started, title: '経営会議', segmentIndex: 2),
        '2026-07-04_14-30-05_経営会議_part2',
      );
    });

    test('タイトル空でも日時プレフィックスは維持', () {
      expect(
        SegmentNaming.segmentBaseName(started, segmentIndex: 3),
        '2026-07-04_14-30-05_part3',
      );
    });
  });

  group('SegmentNaming.segmentAudioFileName', () {
    test('iOS(m4a) の先頭セグメント', () {
      expect(
        SegmentNaming.segmentAudioFileName(started, Codec.aacM4a,
            title: '経営会議'),
        '2026-07-04_14-30-05_経営会議.m4a',
      );
    });

    test('Android(opus) の part2', () {
      expect(
        SegmentNaming.segmentAudioFileName(started, Codec.oggOpus,
            title: '経営会議', segmentIndex: 2),
        '2026-07-04_14-30-05_経営会議_part2.opus',
      );
    });
  });
}
