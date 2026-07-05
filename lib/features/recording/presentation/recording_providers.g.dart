// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリ共通の drift データベース。
///
/// ASSUMPTION: 統合フェーズでは app/core 側の集約 provider に置き換える想定。
/// 単一インスタンスを保つため keepAlive。テストでは override する。

@ProviderFor(appDatabase)
const appDatabaseProvider = AppDatabaseProvider._();

/// アプリ共通の drift データベース。
///
/// ASSUMPTION: 統合フェーズでは app/core 側の集約 provider に置き換える想定。
/// 単一インスタンスを保つため keepAlive。テストでは override する。

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// アプリ共通の drift データベース。
  ///
  /// ASSUMPTION: 統合フェーズでは app/core 側の集約 provider に置き換える想定。
  /// 単一インスタンスを保つため keepAlive。テストでは override する。
  const AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// iOS 録音セッション＋割り込み購読マネージャ（keepAlive）。

@ProviderFor(audioSessionManager)
const audioSessionManagerProvider = AudioSessionManagerProvider._();

/// iOS 録音セッション＋割り込み購読マネージャ（keepAlive）。

final class AudioSessionManagerProvider
    extends
        $FunctionalProvider<
          AudioSessionManager,
          AudioSessionManager,
          AudioSessionManager
        >
    with $Provider<AudioSessionManager> {
  /// iOS 録音セッション＋割り込み購読マネージャ（keepAlive）。
  const AudioSessionManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioSessionManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioSessionManagerHash();

  @$internal
  @override
  $ProviderElement<AudioSessionManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AudioSessionManager create(Ref ref) {
    return audioSessionManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioSessionManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioSessionManager>(value),
    );
  }
}

String _$audioSessionManagerHash() =>
    r'f030fe4c5477e28250fef18069fef1c05a040026';

/// 録音サービス本体（keepAlive）。組み立て＋初期化まで行う。
///
/// 録音は FG 起点のみ・単一インスタンスであるべきなので keepAlive。

@ProviderFor(recordingService)
const recordingServiceProvider = RecordingServiceProvider._();

/// 録音サービス本体（keepAlive）。組み立て＋初期化まで行う。
///
/// 録音は FG 起点のみ・単一インスタンスであるべきなので keepAlive。

final class RecordingServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecordingService>,
          RecordingService,
          FutureOr<RecordingService>
        >
    with $FutureModifier<RecordingService>, $FutureProvider<RecordingService> {
  /// 録音サービス本体（keepAlive）。組み立て＋初期化まで行う。
  ///
  /// 録音は FG 起点のみ・単一インスタンスであるべきなので keepAlive。
  const RecordingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingServiceHash();

  @$internal
  @override
  $FutureProviderElement<RecordingService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecordingService> create(Ref ref) {
    return recordingService(ref);
  }
}

String _$recordingServiceHash() => r'c4d97a600736faf44cfca60bef6bcc4047121e17';

/// 録音の実行時スナップショットを購読するストリーム（§10.2）。
///
/// 全画面共通の「録音中バー」・録音ボタンはこれを watch する。

@ProviderFor(recordingRuntime)
const recordingRuntimeProvider = RecordingRuntimeProvider._();

/// 録音の実行時スナップショットを購読するストリーム（§10.2）。
///
/// 全画面共通の「録音中バー」・録音ボタンはこれを watch する。

final class RecordingRuntimeProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecordingRuntime>,
          RecordingRuntime,
          Stream<RecordingRuntime>
        >
    with $FutureModifier<RecordingRuntime>, $StreamProvider<RecordingRuntime> {
  /// 録音の実行時スナップショットを購読するストリーム（§10.2）。
  ///
  /// 全画面共通の「録音中バー」・録音ボタンはこれを watch する。
  const RecordingRuntimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingRuntimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingRuntimeHash();

  @$internal
  @override
  $StreamProviderElement<RecordingRuntime> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RecordingRuntime> create(Ref ref) {
    return recordingRuntime(ref);
  }
}

String _$recordingRuntimeHash() => r'3f3fdf4973dd8ec03a07898252749bd509cbe5da';

/// 全画面共通「録音中バー」用の状態 provider。

@ProviderFor(recordingBar)
const recordingBarProvider = RecordingBarProvider._();

/// 全画面共通「録音中バー」用の状態 provider。

final class RecordingBarProvider
    extends
        $FunctionalProvider<
          RecordingBarState,
          RecordingBarState,
          RecordingBarState
        >
    with $Provider<RecordingBarState> {
  /// 全画面共通「録音中バー」用の状態 provider。
  const RecordingBarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingBarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingBarHash();

  @$internal
  @override
  $ProviderElement<RecordingBarState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecordingBarState create(Ref ref) {
    return recordingBar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingBarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingBarState>(value),
    );
  }
}

String _$recordingBarHash() => r'06c34397a4ab6dec7615a65f86055f648c7f0fa9';
