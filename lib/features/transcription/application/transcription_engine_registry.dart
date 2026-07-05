import '../domain/transcription_engine.dart';

/// 文字起こしエンジンの登録簿（DESIGN.md §8.3）。
///
/// `Map<String, TranscriptionEngine>` を保持し、id でエンジンを解決する。
/// Riverpod provider（presentation 層）から公開し、テストや将来のエンジン追加で
/// 差し替え可能にする。ドメイン層のためここ自体は Riverpod 非依存。
class TranscriptionEngineRegistry {
  TranscriptionEngineRegistry(
    Map<String, TranscriptionEngine> engines, {
    String? defaultEngineId,
  })  : _engines = Map.unmodifiable(engines),
        _defaultEngineId = defaultEngineId ??
            (engines.isNotEmpty ? engines.keys.first : null);

  final Map<String, TranscriptionEngine> _engines;
  final String? _defaultEngineId;

  /// 既定エンジンの id（未指定時のフォールバック）。
  String? get defaultEngineId => _defaultEngineId;

  /// 登録済みエンジン一覧（設定画面のエンジン選択用）。
  List<TranscriptionEngine> get all => _engines.values.toList(growable: false);

  /// 登録済みエンジン id 一覧。
  Iterable<String> get ids => _engines.keys;

  /// id 登録の有無。
  bool contains(String id) => _engines.containsKey(id);

  /// id でエンジンを取得（無ければ null）。
  TranscriptionEngine? engine(String id) => _engines[id];

  /// id を解決する。null や未登録 id は既定エンジンにフォールバックする。
  /// 解決不能（登録簿が空）なら null。
  TranscriptionEngine? resolve(String? id) {
    if (id != null) {
      final found = _engines[id];
      if (found != null) return found;
    }
    final fallbackId = _defaultEngineId;
    return fallbackId == null ? null : _engines[fallbackId];
  }
}
