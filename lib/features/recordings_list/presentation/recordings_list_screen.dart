import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/contracts.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../application/recordings_list_providers.dart';
import 'widgets/offline_banner.dart';
import 'widgets/recording_bar.dart';
import 'widgets/recording_tile.dart';

/// 録音一覧（ホーム）（§10.1）。
///
/// - drift watch を StreamProvider 経由で購読し、バッジは実状態に自動追従。
/// - 上部にオフラインバナー、下部に全画面共通の録音中バー。
/// - マイク FAB で録音開始（録音中は無効化＝多重録音排他）。
class RecordingsListScreen extends ConsumerWidget {
  const RecordingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(recordingsListProvider);
    final isRecording = ref.watch(isRecordingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('録音一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => AppRouter.toSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: recordings.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const _ErrorState(),
              data: (list) {
                if (list.isEmpty) return const _EmptyState();
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      RecordingTile(recording: list[i]),
                );
              },
            ),
          ),
          const RecordingBar(),
        ],
      ),
      // 録音中は FAB を非表示（録音中バーの停止ボタンと重なるため。多重録音排他 §6.5）
      floatingActionButton: isRecording ? null : const _RecordFab(),
    );
  }
}

/// 録音開始 FAB。録音中は画面側で非表示にする（多重録音排他 §6.5）。
class _RecordFab extends ConsumerWidget {
  const _RecordFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _start(context, ref),
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: const Icon(Icons.mic),
      label: const Text('録音'),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(recordingControllerProvider).start();
    } on NotWiredException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.feature} は統合フェーズで接続されます')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('録音を開始できませんでした')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_none,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('録音はまだありません'),
            const SizedBox(height: 8),
            Text(
              '下のマイクボタンから録音を始めましょう。\nサインインなしでも録音できます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('一覧を読み込めませんでした'));
  }
}
