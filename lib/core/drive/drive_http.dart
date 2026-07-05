import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'drive_client.dart';

/// Drive REST / resumable upload のエンドポイントとエラー分類ユーティリティ。
///
/// [GoogleDriveClient] から使う。HTTP ステータス→[DriveException] の写像を
/// 一箇所に集約し、ユニットテスト可能にする（§7.5 の状態遷移に対応）。
abstract final class DriveEndpoints {
  /// メタデータ操作（list / create / get / patch / delete）のベース URL。
  static const String files = 'https://www.googleapis.com/drive/v3/files';

  /// メディアアップロード（resumable / media）のベース URL。
  static const String upload =
      'https://www.googleapis.com/upload/drive/v3/files';

  /// トークン revoke エンドポイント（§9・サインアウト時）。
  static const String revoke = 'https://oauth2.googleapis.com/revoke';

  /// `drive.file` スコープ（アプリが作成したファイル/フォルダのみ）。
  static const String driveFileScope =
      'https://www.googleapis.com/auth/drive.file';

  /// フォルダの MIME タイプ。
  static const String folderMimeType = 'application/vnd.google-apps.folder';
}

/// 認証済み HTTP クライアントを供給するファクトリ。
///
/// 本番では [AuthService.authorizedClient] を渡す（googleapis_auth の
/// AuthClient）。テストでは `MockClient` を返すクロージャを渡す。
typedef DriveClientProvider = Future<http.Client> Function();

/// HTTP ステータスコードを [DriveException] に写像する（§7.5）。
///
/// - 401 → [DriveAuthException]（恒久・再サインイン誘導）
/// - 403（quota / storage） → [DriveQuotaException]（恒久）
/// - 403（rateLimit） → [DriveTransientException]（再試行）
/// - 404 → [DriveFolderMissingException]（恒久・フォルダ再作成導線）
/// - 429 / 5xx → [DriveTransientException]（バックオフ再試行）
/// - その他 4xx → [DriveTransientException]（安全側。ログで種別を追う）
DriveException classifyDriveStatus(int status, {String? body}) {
  if (status == 401) {
    return const DriveAuthException();
  }
  if (status == 403) {
    final reason = _extractReason(body);
    if (reason != null &&
        (reason.contains('rateLimit') || reason.contains('userRateLimit'))) {
      return const DriveTransientException('rate limited', 403);
    }
    // storageQuotaExceeded / quotaExceeded / その他の 403 は恒久扱い。
    return const DriveQuotaException();
  }
  if (status == 404) {
    return const DriveFolderMissingException();
  }
  if (status == 429) {
    return const DriveTransientException('rate limited', 429);
  }
  if (status >= 500) {
    return DriveTransientException('server error', status);
  }
  return DriveTransientException('unexpected drive status', status);
}

/// ネットワーク由来の例外なら [DriveTransientException] を返す。
/// Drive の HTTP 応答由来でない例外（プログラムエラー等）は null を返し、
/// 呼び出し側で rethrow させる。
DriveException? tryClassifyNetworkError(Object error) {
  if (error is SocketException ||
      error is HttpException ||
      error is http.ClientException ||
      error is TimeoutException) {
    return const DriveTransientException('network error');
  }
  return null;
}

/// Drive のエラー JSON 本文から `error.errors[].reason` を抽出する。
String? _extractReason(String? body) {
  if (body == null || body.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final errors = error['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map<String, dynamic>) {
            final reason = first['reason'];
            if (reason is String) {
              return reason;
            }
          }
        }
        // v3 は status/message のみのことがある。
        final statusStr = error['status'];
        if (statusStr is String) {
          return statusStr;
        }
      }
    }
  } catch (_) {
    // 解析不能な本文は理由不明として扱う。
  }
  return null;
}

/// Drive クエリ値（`q` パラメータ内の文字列リテラル）をエスケープする。
///
/// `\` と `'` をエスケープし、インジェクションを防ぐ。
String escapeDriveQueryValue(String raw) {
  return raw.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
}
