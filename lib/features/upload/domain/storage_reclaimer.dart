import 'dart:io';

import '../../../core/constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/security/app_logger.dart';
import 'upload_ports.dart';

/// ストレージ逼迫時の自動削除（DESIGN.md §7.7 / B5）。ドメイン層・plain Dart。
///
/// 安全条件（違反禁止）:
/// - 対象は **アップロード完了済み（uploadState=done）のローカルファイルのみ・古い順**。
///   候補選定は [RecordingsDao.getReclaimableOldestFirst] に委譲（DB 側でフィルタ済み）。
/// - 未アップロード録音は **いかなる場合も削除しない**。
/// - 削除後は `localPath=NULL`。一覧には残す（再生時は Drive 再取得導線）。
class StorageReclaimer {
  StorageReclaimer({
    required AppDatabase db,
    DeviceStorageProbe storage = const UnlimitedDeviceStorageProbe(),
    AppLogger? logger,
    Future<void> Function(String path)? deleteFile,
  })  : _db = db,
        _storage = storage,
        _log = logger ?? const AppLogger('upload.reclaim'),
        _deleteFile = deleteFile ?? _defaultDelete;

  final AppDatabase _db;
  final DeviceStorageProbe _storage;
  final AppLogger _log;
  final Future<void> Function(String path) _deleteFile;

  static Future<void> _defaultDelete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  /// 空き容量が閾値未満なら、アップ済み・古い順にローカル実体を削除する。
  ///
  /// 閾値（[AppConstants.reclaimThresholdBytes]・500MB）を回復するか、削除候補が
  /// 尽きるまで削除する。削除した件数を返す。
  Future<int> reclaimIfNeeded() async {
    final free = await _storage.freeBytes();
    if (free >= AppConstants.reclaimThresholdBytes) return 0;

    final candidates = await _db.recordingsDao.getReclaimableOldestFirst();
    if (candidates.isEmpty) return 0;

    var reclaimed = 0;
    var estimatedFree = free;
    for (final rec in candidates) {
      if (estimatedFree >= AppConstants.reclaimThresholdBytes) break;
      final path = rec.localPath;
      if (path == null) continue;
      try {
        await _deleteFile(path);
      } catch (e) {
        _log.error('reclaimDelete', recordingId: rec.id, error: e);
        continue;
      }
      // localPath を NULL 化（DB が source of truth。一覧には残る）。
      await _db.recordingsDao.setLocalPath(rec.id, null);
      estimatedFree += rec.sizeBytes;
      reclaimed++;
    }
    if (reclaimed > 0) {
      _log.info('reclaimed count=$reclaimed');
    }
    return reclaimed;
  }
}
