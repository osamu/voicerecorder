// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcription_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 文字起こしエンジン登録簿。差し替え（テスト・エンジン追加）はこの provider を override。
///
/// MVP は [CloudSttEngine] 一択（API キーは secure_storage から読む）。

@ProviderFor(transcriptionEngineRegistry)
const transcriptionEngineRegistryProvider =
    TranscriptionEngineRegistryProvider._();

/// 文字起こしエンジン登録簿。差し替え（テスト・エンジン追加）はこの provider を override。
///
/// MVP は [CloudSttEngine] 一択（API キーは secure_storage から読む）。

final class TranscriptionEngineRegistryProvider
    extends
        $FunctionalProvider<
          TranscriptionEngineRegistry,
          TranscriptionEngineRegistry,
          TranscriptionEngineRegistry
        >
    with $Provider<TranscriptionEngineRegistry> {
  /// 文字起こしエンジン登録簿。差し替え（テスト・エンジン追加）はこの provider を override。
  ///
  /// MVP は [CloudSttEngine] 一択（API キーは secure_storage から読む）。
  const TranscriptionEngineRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptionEngineRegistryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptionEngineRegistryHash();

  @$internal
  @override
  $ProviderElement<TranscriptionEngineRegistry> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TranscriptionEngineRegistry create(Ref ref) {
    return transcriptionEngineRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranscriptionEngineRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranscriptionEngineRegistry>(value),
    );
  }
}

String _$transcriptionEngineRegistryHash() =>
    r'b4f7be29bd329d385519a45a8218966958b459cc';

/// ドメインサービス（Riverpod 非依存の実体を DI で組む）。

@ProviderFor(transcriptionService)
const transcriptionServiceProvider = TranscriptionServiceProvider._();

/// ドメインサービス（Riverpod 非依存の実体を DI で組む）。

final class TranscriptionServiceProvider
    extends
        $FunctionalProvider<
          TranscriptionService,
          TranscriptionService,
          TranscriptionService
        >
    with $Provider<TranscriptionService> {
  /// ドメインサービス（Riverpod 非依存の実体を DI で組む）。
  const TranscriptionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptionServiceHash();

  @$internal
  @override
  $ProviderElement<TranscriptionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TranscriptionService create(Ref ref) {
    return transcriptionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranscriptionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranscriptionService>(value),
    );
  }
}

String _$transcriptionServiceHash() =>
    r'f6049970c7043a54ac8d05968a7c2cc164933f08';

/// 一覧メニューの「再文字起こし」アクション。
///
/// バッジ状態自体は recordings テーブルの watch で足りるため、状態を持つ provider は
/// これ（アクション）だけを公開する（DESIGN.md §8.6）。

@ProviderFor(RetranscribeController)
const retranscribeControllerProvider = RetranscribeControllerProvider._();

/// 一覧メニューの「再文字起こし」アクション。
///
/// バッジ状態自体は recordings テーブルの watch で足りるため、状態を持つ provider は
/// これ（アクション）だけを公開する（DESIGN.md §8.6）。
final class RetranscribeControllerProvider
    extends $AsyncNotifierProvider<RetranscribeController, void> {
  /// 一覧メニューの「再文字起こし」アクション。
  ///
  /// バッジ状態自体は recordings テーブルの watch で足りるため、状態を持つ provider は
  /// これ（アクション）だけを公開する（DESIGN.md §8.6）。
  const RetranscribeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'retranscribeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$retranscribeControllerHash();

  @$internal
  @override
  RetranscribeController create() => RetranscribeController();
}

String _$retranscribeControllerHash() =>
    r'7f48795181d19872f540d06009c22d2c80db9bda';

/// 一覧メニューの「再文字起こし」アクション。
///
/// バッジ状態自体は recordings テーブルの watch で足りるため、状態を持つ provider は
/// これ（アクション）だけを公開する（DESIGN.md §8.6）。

abstract class _$RetranscribeController extends $AsyncNotifier<void> {
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
