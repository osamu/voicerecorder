// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 録音ボタン用のコントローラ（§10.2）。
///
/// 開始/停止を UI から呼ぶための薄いラッパ。永続状態・実行時状態は
/// [recordingServiceProvider] / [recordingRuntimeProvider] が正。ここは操作のみ。
///
/// build() は「進行中の非同期操作があるか」を表すために [AsyncValue<void>] を返す。

@ProviderFor(RecordingController)
const recordingControllerProvider = RecordingControllerProvider._();

/// 録音ボタン用のコントローラ（§10.2）。
///
/// 開始/停止を UI から呼ぶための薄いラッパ。永続状態・実行時状態は
/// [recordingServiceProvider] / [recordingRuntimeProvider] が正。ここは操作のみ。
///
/// build() は「進行中の非同期操作があるか」を表すために [AsyncValue<void>] を返す。
final class RecordingControllerProvider
    extends $AsyncNotifierProvider<RecordingController, void> {
  /// 録音ボタン用のコントローラ（§10.2）。
  ///
  /// 開始/停止を UI から呼ぶための薄いラッパ。永続状態・実行時状態は
  /// [recordingServiceProvider] / [recordingRuntimeProvider] が正。ここは操作のみ。
  ///
  /// build() は「進行中の非同期操作があるか」を表すために [AsyncValue<void>] を返す。
  const RecordingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingControllerHash();

  @$internal
  @override
  RecordingController create() => RecordingController();
}

String _$recordingControllerHash() =>
    r'55c01a06e8fdbee556fe1ae6bb6f0fcd8ac23abe';

/// 録音ボタン用のコントローラ（§10.2）。
///
/// 開始/停止を UI から呼ぶための薄いラッパ。永続状態・実行時状態は
/// [recordingServiceProvider] / [recordingRuntimeProvider] が正。ここは操作のみ。
///
/// build() は「進行中の非同期操作があるか」を表すために [AsyncValue<void>] を返す。

abstract class _$RecordingController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
