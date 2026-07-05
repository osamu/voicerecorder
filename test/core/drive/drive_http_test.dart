import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:voicerecorder/core/drive/drive_client.dart';
import 'package:voicerecorder/core/drive/drive_http.dart';

void main() {
  group('classifyDriveStatus', () {
    test('401 は恒久 DriveAuthException', () {
      final e = classifyDriveStatus(401);
      expect(e, isA<DriveAuthException>());
      expect(e.isRetryable, isFalse);
    });

    test('403 quota は恒久 DriveQuotaException', () {
      final e = classifyDriveStatus(
        403,
        body: '{"error":{"errors":[{"reason":"storageQuotaExceeded"}]}}',
      );
      expect(e, isA<DriveQuotaException>());
      expect(e.isRetryable, isFalse);
    });

    test('403 rateLimit は再試行可 DriveTransientException', () {
      final e = classifyDriveStatus(
        403,
        body: '{"error":{"errors":[{"reason":"userRateLimitExceeded"}]}}',
      );
      expect(e, isA<DriveTransientException>());
      expect(e.isRetryable, isTrue);
    });

    test('404 は DriveFolderMissingException', () {
      expect(classifyDriveStatus(404), isA<DriveFolderMissingException>());
    });

    test('429 は再試行可 DriveTransientException', () {
      final e = classifyDriveStatus(429);
      expect(e, isA<DriveTransientException>());
      expect((e as DriveTransientException).statusCode, 429);
    });

    test('5xx は再試行可 DriveTransientException', () {
      final e = classifyDriveStatus(503);
      expect(e, isA<DriveTransientException>());
      expect(e.isRetryable, isTrue);
    });
  });

  group('tryClassifyNetworkError', () {
    test('SocketException は Transient', () {
      final e = tryClassifyNetworkError(const SocketException('down'));
      expect(e, isA<DriveTransientException>());
    });

    test('http.ClientException は Transient', () {
      final e = tryClassifyNetworkError(http.ClientException('boom'));
      expect(e, isA<DriveTransientException>());
    });

    test('TimeoutException は Transient', () {
      final e = tryClassifyNetworkError(TimeoutException('slow'));
      expect(e, isA<DriveTransientException>());
    });

    test('プログラムエラーは分類しない（null）', () {
      expect(tryClassifyNetworkError(ArgumentError('bug')), isNull);
    });
  });

  group('escapeDriveQueryValue', () {
    test('シングルクォートとバックスラッシュをエスケープ', () {
      expect(escapeDriveQueryValue("a'b"), r"a\'b");
      expect(escapeDriveQueryValue(r'a\b'), r'a\\b');
    });
  });
}
