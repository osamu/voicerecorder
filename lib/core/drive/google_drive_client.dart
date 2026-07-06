import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../database/app_database.dart';
import '../naming/naming.dart';
import '../security/app_logger.dart';
import 'drive_client.dart';
import 'drive_http.dart';

/// [DriveClient] の googleapis Drive v3（REST 直叩き）実装。
///
/// 設計上の不変条件（DESIGN.md §7）:
/// - スコープは `drive.file` のみ。アプリ自作 `/CloudRecorder/` 配下のみ扱う。
/// - フォルダ/ファイルは常に fileId 基準で操作し、冪等化は appProperties
///   （`vrId` / `vrKind` / `vrFolderPath`）で行う。
/// - resumable upload はセッション URI を再利用し、中断後は現在オフセットを
///   問い合わせて続きから送る。
///
/// 認証は [DriveClientProvider]（googleapis_auth の AuthClient を返す）に委譲し、
/// 本クラスは HTTP と Drive セマンティクスのみに責務を限定する。
class GoogleDriveClient implements DriveClient {
  GoogleDriveClient({
    required DriveClientProvider clientProvider,
    required SettingsDao settingsDao,
    AppLogger? logger,
    int chunkSizeBytes = _defaultChunkSize,
  })  : _clientProvider = clientProvider,
        _settingsDao = settingsDao,
        _logger = logger ?? const AppLogger('drive'),
        _chunkSize = chunkSizeBytes;

  final DriveClientProvider _clientProvider;
  final SettingsDao _settingsDao;
  final AppLogger _logger;
  final int _chunkSize;

  /// resumable の 1 チャンク（中間チャンクは 256KB の倍数必須）。8MB。
  static const int _defaultChunkSize = 8 * 1024 * 1024;

  // ---------------------------------------------------------------------------
  // フォルダ管理（§7.1）
  // ---------------------------------------------------------------------------

  @override
  Future<String> ensureRootFolder() async {
    final client = await _clientProvider();
    final cached =
        await _settingsDao.getValue(SettingsKeys.driveRootFolderId);
    if (cached != null && cached.isNotEmpty) {
      final meta = await _getMetadataOrNull(client, cached, fields: 'id,trashed');
      if (meta != null) {
        if (meta['trashed'] == true) {
          _logger.warning('root folder trashed');
          throw const DriveFolderMissingException('root folder trashed');
        }
        return cached;
      }
      // 404: settings のキャッシュが陳腐化。検索/再作成へフォールバック。
      _logger.info('cached root folder missing; recreating');
    }
    final id = await _getOrCreateFolder(
      client,
      parentId: null,
      name: AppConstants.driveRootFolderName,
      pathKey: AppConstants.driveRootFolderName,
    );
    await _settingsDao.setValue(SettingsKeys.driveRootFolderId, id);
    return id;
  }

  @override
  Future<String> ensureDateFolder(DateTime startedAt) async {
    final rootId = await ensureRootFolder();
    final client = await _clientProvider();
    final segments = Naming.driveFolderSegments(startedAt); // [YYYY, YYYY-MM]
    var parentId = rootId;
    var pathKey = AppConstants.driveRootFolderName;
    for (final segment in segments) {
      pathKey = '$pathKey/$segment';
      parentId = await _getOrCreateFolder(
        client,
        parentId: parentId,
        name: segment,
        pathKey: pathKey,
      );
    }
    return parentId;
  }

  /// フォルダを get-or-create する（appProperties のパスキーで検索し冪等化）。
  Future<String> _getOrCreateFolder(
    http.Client client, {
    required String? parentId,
    required String name,
    required String pathKey,
  }) async {
    final parentClause =
        parentId == null ? "'root' in parents" : "'$parentId' in parents";
    final q = "mimeType='${DriveEndpoints.folderMimeType}' and "
        "name='${escapeDriveQueryValue(name)}' and "
        '$parentClause and trashed=false and '
        "appProperties has {key='${AppConstants.drivePropFolderPath}' and "
        "value='${escapeDriveQueryValue(pathKey)}'}";
    final existing = await _listFiles(client, q: q, fields: 'files(id,name)');
    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }
    final created = await _createMetadata(
      client,
      {
        'name': name,
        'mimeType': DriveEndpoints.folderMimeType,
        'parents': [parentId ?? 'root'],
        'appProperties': {AppConstants.drivePropFolderPath: pathKey},
      },
      fields: 'id',
    );
    return created['id'] as String;
  }

  // ---------------------------------------------------------------------------
  // resumable upload（§7.2）
  // ---------------------------------------------------------------------------

  @override
  Future<String> startResumableSession({
    required String parentFolderId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String vrId,
    required String vrKind,
  }) async {
    final client = await _clientProvider();
    final uri = Uri.parse(
      '${DriveEndpoints.upload}'
      '?uploadType=resumable&fields=id,name,mimeType,size,appProperties',
    );
    final body = jsonEncode({
      'name': fileName,
      'mimeType': mimeType,
      'parents': [parentFolderId],
      'appProperties': {
        AppConstants.drivePropVrId: vrId,
        AppConstants.drivePropVrKind: vrKind,
      },
    });
    final resp = await _guard(() => client.post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'X-Upload-Content-Type': mimeType,
            'X-Upload-Content-Length': '$sizeBytes',
          },
          body: body,
        ));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final location = resp.headers['location'];
      if (location == null || location.isEmpty) {
        throw const DriveTransientException('missing resumable session uri');
      }
      return location;
    }
    throw classifyDriveStatus(resp.statusCode, body: resp.body);
  }

  @override
  Future<DriveFile> uploadResumable({
    required String sessionUri,
    required File file,
    required String mimeType,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final client = await _clientProvider();
    final total = await file.length();

    // 現在オフセットを問い合わせ（中断後の再開に対応）。
    var offset = await _queryResumeOffset(client, sessionUri, total);
    if (offset is _CompletedUpload) {
      onProgress?.call(total, total);
      return offset.file;
    }
    var start = offset as int;
    onProgress?.call(start, total);

    final raf = await file.open();
    try {
      // 空ファイルは 1 回の PUT（bytes */0）で確定させる。
      if (total == 0) {
        final resp = await _guard(() => _putChunk(
              client,
              sessionUri,
              bytes: const <int>[],
              contentRange: 'bytes */0',
            ));
        return _handleUploadResponse(resp, total, onProgress);
      }

      while (start < total) {
        final end = math.min(start + _chunkSize, total);
        await raf.setPosition(start);
        final chunk = await raf.read(end - start);
        final resp = await _guard(() => _putChunk(
              client,
              sessionUri,
              bytes: chunk,
              contentRange: 'bytes $start-${end - 1}/$total',
            ));
        if (resp.statusCode == 308) {
          final nextEnd = _rangeUpperBound(resp.headers['range']);
          start = nextEnd == null ? end : nextEnd + 1;
          onProgress?.call(start, total);
          continue;
        }
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          return _handleUploadResponse(resp, total, onProgress);
        }
        throw classifyDriveStatus(resp.statusCode, body: resp.body);
      }
      // start==total に達したが 200 未受領: 最終問い合わせ。
      final finalOffset = await _queryResumeOffset(client, sessionUri, total);
      if (finalOffset is _CompletedUpload) {
        onProgress?.call(total, total);
        return finalOffset.file;
      }
      throw const DriveTransientException('upload did not finalize');
    } finally {
      await raf.close();
    }
  }

  Future<http.Response> _putChunk(
    http.Client client,
    String sessionUri, {
    required List<int> bytes,
    required String contentRange,
  }) async {
    final request = http.Request('PUT', Uri.parse(sessionUri))
      ..bodyBytes = bytes
      ..headers['Content-Range'] = contentRange;
    final streamed = await client.send(request);
    return http.Response.fromStream(streamed);
  }

  DriveFile _handleUploadResponse(
    http.Response resp,
    int total,
    void Function(int, int)? onProgress,
  ) {
    onProgress?.call(total, total);
    return _fileFromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// resumable セッションの現在オフセットを問い合わせる。
  /// 既に完了していれば [_CompletedUpload] を返す。
  Future<Object> _queryResumeOffset(
    http.Client client,
    String sessionUri,
    int total,
  ) async {
    final resp = await _guard(() => _putChunk(
          client,
          sessionUri,
          bytes: const <int>[],
          contentRange: 'bytes */$total',
        ));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return _CompletedUpload(
          _fileFromJson(jsonDecode(resp.body) as Map<String, dynamic>));
    }
    if (resp.statusCode == 308) {
      final upper = _rangeUpperBound(resp.headers['range']);
      return upper == null ? 0 : upper + 1;
    }
    if (resp.statusCode == 404) {
      // セッションが失効/不明。上位でセッション張り直しから再試行させる。
      throw const DriveTransientException('resumable session expired', 404);
    }
    throw classifyDriveStatus(resp.statusCode, body: resp.body);
  }

  /// `Range: bytes=0-262143` の上限（最後に受信したバイトの index）を返す。
  int? _rangeUpperBound(String? rangeHeader) {
    if (rangeHeader == null || rangeHeader.isEmpty) {
      return null;
    }
    final match = RegExp(r'-(\d+)\s*$').firstMatch(rangeHeader.trim());
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  // ---------------------------------------------------------------------------
  // 冪等検索 / fileId 基準操作（§7.3 / §7.4）
  // ---------------------------------------------------------------------------

  @override
  Future<String?> findByVrId(String vrId, String vrKind) async {
    final client = await _clientProvider();
    final q = 'trashed=false and '
        "appProperties has {key='${AppConstants.drivePropVrId}' and "
        "value='${escapeDriveQueryValue(vrId)}'} and "
        "appProperties has {key='${AppConstants.drivePropVrKind}' and "
        "value='${escapeDriveQueryValue(vrKind)}'}";
    final files = await _listFiles(client, q: q, fields: 'files(id)');
    return files.isEmpty ? null : files.first['id'] as String;
  }

  @override
  Future<void> renameFile(String fileId, String newName) async {
    final client = await _clientProvider();
    final uri = Uri.parse(
        '${DriveEndpoints.files}/${Uri.encodeComponent(fileId)}?fields=id');
    final resp = await _guard(() => client.patch(
          uri,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'name': newName}),
        ));
    if (resp.statusCode != 200) {
      throw classifyDriveStatus(resp.statusCode, body: resp.body);
    }
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final client = await _clientProvider();
    final uri =
        Uri.parse('${DriveEndpoints.files}/${Uri.encodeComponent(fileId)}');
    final resp = await _guard(() => client.delete(uri));
    // 204: 成功。404: 既に削除済み（冪等に成功扱い）。
    if (resp.statusCode == 204 || resp.statusCode == 200 ||
        resp.statusCode == 404) {
      return;
    }
    throw classifyDriveStatus(resp.statusCode, body: resp.body);
  }

  @override
  Future<void> downloadFile(String fileId, String localPath) async {
    final client = await _clientProvider();
    final uri = Uri.parse(
        '${DriveEndpoints.files}/${Uri.encodeComponent(fileId)}?alt=media');
    final request = http.Request('GET', uri);
    final streamed = await _guard(() => client.send(request));
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw classifyDriveStatus(streamed.statusCode, body: body);
    }
    final outFile = File(localPath);
    await outFile.parent.create(recursive: true);
    final sink = outFile.openWrite();
    try {
      await streamed.stream.pipe(sink);
    } finally {
      await sink.close();
    }
  }

  @override
  Future<DriveFile> updateFileContent(
    String fileId, {
    required File content,
    required String mimeType,
  }) async {
    final client = await _clientProvider();
    final uri = Uri.parse(
      '${DriveEndpoints.upload}/${Uri.encodeComponent(fileId)}'
      '?uploadType=media&fields=id,name,mimeType,size,appProperties',
    );
    final bytes = await content.readAsBytes();
    final resp = await _guard(() => client.patch(
          uri,
          headers: {'Content-Type': mimeType},
          body: bytes,
        ));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return _fileFromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    }
    throw classifyDriveStatus(resp.statusCode, body: resp.body);
  }

  // ---------------------------------------------------------------------------
  // 低レベル HTTP ヘルパ
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _listFiles(
    http.Client client, {
    required String q,
    required String fields,
  }) async {
    final uri = Uri.parse(DriveEndpoints.files).replace(queryParameters: {
      'q': q,
      'fields': fields,
      'spaces': 'drive',
      'pageSize': '10',
    });
    final resp = await _guard(() => client.get(uri));
    if (resp.statusCode != 200) {
      throw classifyDriveStatus(resp.statusCode, body: resp.body);
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final files = decoded['files'];
    if (files is! List) {
      return const [];
    }
    return files.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _createMetadata(
    http.Client client,
    Map<String, dynamic> body, {
    required String fields,
  }) async {
    final uri =
        Uri.parse(DriveEndpoints.files).replace(queryParameters: {'fields': fields});
    final resp = await _guard(() => client.post(
          uri,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(body),
        ));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw classifyDriveStatus(resp.statusCode, body: resp.body);
  }

  /// メタデータを取得。404 の場合は null（呼び出し側で再作成判断）。
  Future<Map<String, dynamic>?> _getMetadataOrNull(
    http.Client client,
    String fileId, {
    required String fields,
  }) async {
    final uri = Uri.parse(
      '${DriveEndpoints.files}/${Uri.encodeComponent(fileId)}'
      '?fields=${Uri.encodeComponent(fields)}',
    );
    final resp = await _guard(() => client.get(uri));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    if (resp.statusCode == 404) {
      return null;
    }
    throw classifyDriveStatus(resp.statusCode, body: resp.body);
  }

  /// ネットワーク例外を [DriveTransientException] に正規化する。
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DriveException {
      rethrow;
    } catch (error) {
      final classified = tryClassifyNetworkError(error);
      if (classified != null) {
        _logger.error('driveNetwork', error: error);
        throw classified;
      }
      rethrow;
    }
  }

  DriveFile _fileFromJson(Map<String, dynamic> json) {
    final rawProps = json['appProperties'];
    final props = <String, String>{};
    if (rawProps is Map) {
      rawProps.forEach((key, value) {
        props[key.toString()] = value?.toString() ?? '';
      });
    }
    final rawSize = json['size'];
    return DriveFile(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      mimeType: json['mimeType'] as String?,
      sizeBytes: rawSize == null ? null : int.tryParse(rawSize.toString()),
      appProperties: props,
    );
  }
}

/// resumable 問い合わせで「既に完了済み」を表す内部シグナル。
class _CompletedUpload {
  const _CompletedUpload(this.file);
  final DriveFile file;
}
