import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

// アプリのルート Widget を再エクスポート（エントリポイント経由での参照用）。
export 'app/app.dart' show CloudRecorderApp;

Future<void> main() async {
  // 起動シーケンス（DB オープン → リカバリ → キュー/ジョブ再開）を実行し、
  // 構築済みの ProviderContainer で UI を起動する（DESIGN §12）。
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CloudRecorderApp(),
    ),
  );
}
