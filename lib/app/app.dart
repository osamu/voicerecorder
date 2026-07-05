import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/recordings_list/presentation/recordings_list_screen.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

/// アプリのルート Widget。日本語 UI・Material 3・ライト/ダーク対応。
class VoiceRecorderApp extends StatelessWidget {
  const VoiceRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ボイスレコーダ',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      // ルート名 '/' は RootGate（オンボーディング判定）に置き換える。
      home: const _RootGate(),
    );
  }
}

/// 初回起動判定。オンボーディング未完了ならオンボーディング、完了なら一覧へ。
///
/// 判定は drift settings の `onboardingComplete` を watch し、状態変化に追従する
/// （オンボーディング完了時に自動で一覧へ遷移する）。
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(onboardingCompleteProvider);
    if (done) {
      return const RecordingsListScreen();
    }
    return const OnboardingScreen();
  }
}
