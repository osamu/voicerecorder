import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/recorder_backend.dart';

part 'mic_permission.g.dart';

/// マイク権限の状態（§10.5 / #10）。
enum MicPermissionStatus {
  /// 許可済み。録音可能。
  granted,

  /// 未許可（初回、または今回拒否）。説明のうえ再要求できる。
  denied,

  /// 恒久拒否相当。OS 設定への誘導が必要。
  ///
  /// NOTE: `record` パッケージは「恒久拒否」を明示できないため、
  /// 「一度要求して拒否された」状態を本ステータスにマップする運用とする。
  permanentlyDenied,
}

/// マイク権限フローのヘルパ（拒否 → 説明 → OS 設定誘導）（§10.5）。
///
/// 2 段フロー:
/// 1. [request] で OS 権限ダイアログを出す。許可されれば [MicPermissionStatus.granted]。
/// 2. 拒否されたら UI 側で説明を表示し、再要求 or [openSettings] で OS 設定へ誘導。
///
/// OS 設定を開く処理はプラットフォーム依存のため [openAppSettings] コールバックで
/// 注入する（未注入なら no-op）。
class MicPermissionFlow {
  MicPermissionFlow(
    this._recorder, {
    Future<void> Function()? openAppSettings,
  }) : _openAppSettings = openAppSettings;

  final RecorderBackend _recorder;
  final Future<void> Function()? _openAppSettings;

  bool _requestedOnce = false;

  /// 現在の権限を確認する（要求はしない）。
  Future<MicPermissionStatus> check() async {
    final granted = await _recorder.hasPermission(request: false);
    if (granted) return MicPermissionStatus.granted;
    return _requestedOnce
        ? MicPermissionStatus.permanentlyDenied
        : MicPermissionStatus.denied;
  }

  /// OS 権限ダイアログを出して要求する。
  Future<MicPermissionStatus> request() async {
    final granted = await _recorder.hasPermission(request: true);
    if (granted) return MicPermissionStatus.granted;
    // 一度要求して拒否 → 次回以降は OS 設定誘導へ。
    final wasRequested = _requestedOnce;
    _requestedOnce = true;
    return wasRequested
        ? MicPermissionStatus.permanentlyDenied
        : MicPermissionStatus.denied;
  }

  /// OS のアプリ設定画面へ誘導する。
  Future<void> openSettings() async {
    await _openAppSettings?.call();
  }
}

/// マイク権限フロー provider。
///
/// 権限確認専用に軽量な [RecorderBackend] を用いる（録音サービスとは独立）。
/// ASSUMPTION: OS 設定を開く処理は未配線（`openAppSettings` 未注入）。統合時に
/// permission_handler 等で override する想定（下記「必要な追加依存」参照）。
@riverpod
MicPermissionFlow micPermissionFlow(Ref ref) {
  return MicPermissionFlow(RecordRecorderBackend());
}
