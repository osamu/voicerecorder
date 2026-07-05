// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mic_permission.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// マイク権限フロー provider。
///
/// 権限確認専用に軽量な [RecorderBackend] を用いる（録音サービスとは独立）。
/// ASSUMPTION: OS 設定を開く処理は未配線（`openAppSettings` 未注入）。統合時に
/// permission_handler 等で override する想定（下記「必要な追加依存」参照）。

@ProviderFor(micPermissionFlow)
const micPermissionFlowProvider = MicPermissionFlowProvider._();

/// マイク権限フロー provider。
///
/// 権限確認専用に軽量な [RecorderBackend] を用いる（録音サービスとは独立）。
/// ASSUMPTION: OS 設定を開く処理は未配線（`openAppSettings` 未注入）。統合時に
/// permission_handler 等で override する想定（下記「必要な追加依存」参照）。

final class MicPermissionFlowProvider
    extends
        $FunctionalProvider<
          MicPermissionFlow,
          MicPermissionFlow,
          MicPermissionFlow
        >
    with $Provider<MicPermissionFlow> {
  /// マイク権限フロー provider。
  ///
  /// 権限確認専用に軽量な [RecorderBackend] を用いる（録音サービスとは独立）。
  /// ASSUMPTION: OS 設定を開く処理は未配線（`openAppSettings` 未注入）。統合時に
  /// permission_handler 等で override する想定（下記「必要な追加依存」参照）。
  const MicPermissionFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'micPermissionFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$micPermissionFlowHash();

  @$internal
  @override
  $ProviderElement<MicPermissionFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MicPermissionFlow create(Ref ref) {
    return micPermissionFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MicPermissionFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MicPermissionFlow>(value),
    );
  }
}

String _$micPermissionFlowHash() => r'660678292206dbef2db8f1a202ee7ebd472363be';
