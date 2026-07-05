import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/recording_runtime.dart';
import 'recording_providers.dart';

part 'recording_controller.g.dart';

/// 録音ボタン用のコントローラ（§10.2）。
///
/// 開始/停止を UI から呼ぶための薄いラッパ。永続状態・実行時状態は
/// [recordingServiceProvider] / [recordingRuntimeProvider] が正。ここは操作のみ。
///
/// build() は「進行中の非同期操作があるか」を表すために [AsyncValue<void>] を返す。
@riverpod
class RecordingController extends _$RecordingController {
  @override
  Future<void> build() async {
    // 副作用なし。操作結果のローディング/エラー表現に AsyncValue を使う。
  }

  /// 録音を開始する（必ず FG=画面表示中から呼ぶこと §6.1）。
  ///
  /// 拒否時（多重録音・権限・容量）は [RecordingStartException] が
  /// AsyncError として state に反映される。呼び出し側は state.hasError を見る。
  Future<RecordingStartResult?> start({String title = ''}) async {
    state = const AsyncLoading();
    final service = await ref.read(recordingServiceProvider.future);
    try {
      final result = await service.start(title: title);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 録音を停止して確定保存する。
  Future<void> stop() async {
    state = const AsyncLoading();
    final service = await ref.read(recordingServiceProvider.future);
    try {
      await service.stop();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
