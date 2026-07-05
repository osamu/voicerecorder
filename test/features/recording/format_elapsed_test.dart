import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/core/background/foreground_task_handler.dart';

void main() {
  group('formatElapsed', () {
    test('1分未満は M:SS', () {
      expect(formatElapsed(const Duration(seconds: 5)), '0:05');
      expect(formatElapsed(const Duration(seconds: 59)), '0:59');
    });

    test('1時間未満は M:SS（分は0詰めしない）', () {
      expect(formatElapsed(const Duration(minutes: 3, seconds: 7)), '3:07');
      expect(formatElapsed(const Duration(minutes: 12, seconds: 0)), '12:00');
    });

    test('1時間以上は H:MM:SS', () {
      expect(
        formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 9)),
        '1:02:09',
      );
      expect(
        formatElapsed(const Duration(hours: 10, minutes: 0, seconds: 0)),
        '10:00:00',
      );
    });
  });
}
