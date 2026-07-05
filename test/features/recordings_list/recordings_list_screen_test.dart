import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicerecorder/app/providers.dart';
import 'package:voicerecorder/core/database/app_database.dart';
import 'package:voicerecorder/core/database/tables.dart';
import 'package:voicerecorder/features/recordings_list/presentation/recordings_list_screen.dart';

/// テスト用の録音行を組み立てる。
RecordingsCompanion _recording(
  String id, {
  required String title,
  String startedAt = '2026-07-04T14:30:05+09:00',
}) {
  final now = DateTime.now().toIso8601String();
  return RecordingsCompanion.insert(
    id: id,
    startedAt: startedAt,
    codec: Codec.aacM4a,
    title: Value(title),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  Widget harness(AppDatabase db) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: RecordingsListScreen()),
    );
  }

  testWidgets('一覧は drift の watch に追従して行を表示・追加する',
      (WidgetTester tester) async {
    // NOTE: drift の内部タイマは testWidgets の FakeAsync ゾーンでは発火しない
    // （デッドロックする）ため、DB の生成・操作・クローズはすべて
    // tester.runAsync（実イベントループ）で行う。
    late AppDatabase db;
    await tester.runAsync(() async {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
    });
    addTearDown(() => tester.runAsync(() => db.close()));

    // ストリームイベント（実時間）を反映させてから 1 フレーム進めるヘルパ。
    Future<void> settle() async {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }

    // 初期は空。
    await tester.pumpWidget(harness(db));
    await settle();
    expect(find.text('録音はまだありません'), findsOneWidget);

    // 1 件挿入 → 追従して表示される。
    await tester.runAsync(
        () => db.recordingsDao.insertRecording(_recording('r1', title: '経営会議')));
    await settle();
    expect(find.text('経営会議'), findsOneWidget);
    expect(find.text('録音はまだありません'), findsNothing);

    // 2 件目を挿入 → こちらも追従して表示される。
    await tester.runAsync(() => db.recordingsDao.insertRecording(
        _recording('r2', title: '定例MTG', startedAt: '2026-07-05T09:00:00+09:00')));
    await settle();
    expect(find.text('定例MTG'), findsOneWidget);
    expect(find.text('経営会議'), findsOneWidget);

    // 後始末: drift ストリーム購読のクローズ用ゼロタイマを本体内で発火させる
    // （テスト終了時の「Timer is still pending」を防ぐ）。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
