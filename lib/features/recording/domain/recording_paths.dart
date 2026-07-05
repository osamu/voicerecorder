import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 録音ファイルの保存先解決（§6.1）。
///
/// 保存先はアプリ内部ストレージ（[getApplicationDocumentsDirectory] 配下の
/// `recordings/`）。テストでは [RecordingPaths.withBaseDir] で任意ディレクトリを注入。
class RecordingPaths {
  RecordingPaths._(this._recordingsDir);

  final Directory _recordingsDir;

  /// 本番用: ApplicationDocumentsDirectory/recordings/ を用意して返す。
  static Future<RecordingPaths> create() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/recordings');
    return RecordingPaths._(dir);
  }

  /// テスト・DI 用: 任意のベースディレクトリを注入。
  static RecordingPaths withBaseDir(Directory recordingsDir) =>
      RecordingPaths._(recordingsDir);

  /// 録音保存ディレクトリ（未作成なら作成する）。
  Future<Directory> ensureDir() async {
    if (!await _recordingsDir.exists()) {
      await _recordingsDir.create(recursive: true);
    }
    return _recordingsDir;
  }

  /// ディレクトリの絶対パス（作成はしない）。
  String get dirPath => _recordingsDir.path;

  /// ファイル名から絶対パスを組み立てる。
  String pathFor(String fileName) => '${_recordingsDir.path}/$fileName';
}
