import 'contracts.dart';

/// 統合前の既定スタブ実装群。
///
/// 各 feature の実体が Provider override で差し替えられるまでの間、アプリを
/// 起動・巡回できるようにするためのもの。副作用を伴う操作は [NotWiredException]
/// を投げ、UI 側でスナックバー案内する。購読系は空/無を流す。
///
/// 統合フェーズではこれらは使われない（override される）。

class StubAuthController implements AuthController {
  @override
  AuthState get current => AuthState.signedOut;

  @override
  Stream<AuthState> watch() => Stream<AuthState>.value(AuthState.signedOut);

  @override
  Future<void> signIn() async => throw const NotWiredException('Google 連携');

  @override
  Future<void> signOut() async => throw const NotWiredException('Google 連携');
}

class StubRecordingController implements RecordingController {
  @override
  ActiveRecording? get active => null;

  @override
  Stream<ActiveRecording?> watchActive() =>
      Stream<ActiveRecording?>.value(null);

  @override
  Future<void> start() async => throw const NotWiredException('録音');

  @override
  Future<void> stop() async => throw const NotWiredException('録音');

  @override
  Future<void> recoverInterrupted() async {
    // リカバリは録音 feature が実装。スタブは何もしない。
  }
}

class StubUploadController implements UploadController {
  @override
  Future<void> renameRecording(String recordingId, String newTitle) async =>
      throw const NotWiredException('改名の Drive 反映');

  @override
  Future<void> deleteRecording(
    String recordingId, {
    required bool alsoDeleteFromDrive,
  }) async =>
      throw const NotWiredException('削除');

  @override
  Future<void> retryUpload(String recordingId) async =>
      throw const NotWiredException('アップロード再試行');

  @override
  Future<void> refetchLocalCopy(String recordingId) async =>
      throw const NotWiredException('Drive からの再取得');

  @override
  Future<int> pendingUploadCount() async => 0;

  @override
  Future<void> resumeQueue() async {
    // アップロード feature が実装。スタブは何もしない。
  }

  @override
  Future<StorageUsage> storageUsage() async => StorageUsage.empty;

  @override
  Future<void> deleteUploadedLocalFiles() async =>
      throw const NotWiredException('ローカル一括削除');
}

class StubTranscriptionController implements TranscriptionController {
  @override
  Future<void> retranscribe(String recordingId) async =>
      throw const NotWiredException('再文字起こし');

  @override
  Future<void> resumePendingJobs() async {
    // 文字起こし feature が実装。スタブは何もしない。
  }

  @override
  List<TranscriptionEngineInfo> availableEngines() => const [
        TranscriptionEngineInfo(id: 'cloud_stt', displayName: 'クラウド STT'),
      ];

  @override
  Future<List<String>> supportedLocales(String engineId) async =>
      const ['ja-JP', 'en-US'];
}

class StubPermissionController implements PermissionController {
  @override
  Future<AppPermissionStatus> microphoneStatus() async =>
      AppPermissionStatus.granted;

  @override
  Future<AppPermissionStatus> requestMicrophone() async =>
      AppPermissionStatus.granted;

  @override
  Future<void> openAppSettings() async {
    // 権限 feature が実装。
  }
}
