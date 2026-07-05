import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/contracts.dart';
import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../dialogs/delete_dialog.dart';
import '../dialogs/rename_dialog.dart';
import '../format.dart';
import 'transcript_badge.dart';
import 'upload_badge.dart';

/// 録音一覧の 1 行（§10.1）。バッジは drift 由来の状態にリアクティブ追従する。
class RecordingTile extends ConsumerWidget {
  const RecordingTile({super.key, required this.recording});

  final Recording recording;

  bool _isBeingRecorded(WidgetRef ref) {
    final active = ref.watch(activeRecordingProvider).maybeWhen(
          data: (a) => a,
          orElse: () => null,
        );
    return active?.recordingId == recording.id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final beingRecorded = _isBeingRecorded(ref);

    return ListTile(
      onTap: () => AppRouter.toPlayback(context, recording.id),
      title: Text(
        RecordingFormat.title(recording),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${RecordingFormat.dateTime(recording)}'
              '  ・  ${RecordingFormat.duration(recording.durationMs)}'
              '  ・  ${RecordingFormat.size(recording.sizeBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                UploadBadge(
                  state: recording.uploadState,
                  isSignedIn: isSignedIn,
                  onTap: () => _onUploadBadgeTap(context, ref, isSignedIn),
                ),
                TranscriptBadge(
                  state: recording.transcriptState,
                  onTap: () => _onTranscriptBadgeTap(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
      trailing: _menu(context, ref, beingRecorded),
      isThreeLine: true,
    );
  }

  Widget _menu(BuildContext context, WidgetRef ref, bool beingRecorded) {
    return PopupMenuButton<String>(
      onSelected: (value) => _onMenu(context, ref, value),
      itemBuilder: (context) {
        final hasTranscript = recording.transcriptState == TranscriptState.done ||
            recording.transcriptState == TranscriptState.partial;
        return [
          const PopupMenuItem(value: 'play', child: Text('再生')),
          PopupMenuItem(
            value: 'rename',
            enabled: !beingRecorded,
            child: const Text('タイトル変更'),
          ),
          const PopupMenuItem(value: 'retranscribe', child: Text('再文字起こし')),
          if (hasTranscript)
            const PopupMenuItem(value: 'transcript', child: Text('文字起こしを見る')),
          PopupMenuItem(
            value: 'delete',
            enabled: !beingRecorded,
            child: Text(
              '削除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ];
      },
    );
  }

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, String value) async {
    switch (value) {
      case 'play':
        await AppRouter.toPlayback(context, recording.id);
      case 'rename':
        await showRenameDialog(context, recording);
      case 'delete':
        await showDeleteDialog(context, recording);
      case 'transcript':
        await AppRouter.toTranscript(context, recording.id);
      case 'retranscribe':
        await _retranscribe(context, ref);
    }
  }

  // アップロードバッジのタップ。未サインインなら設定（サインイン誘導）、
  // 要対応なら原因＋手動再試行ダイアログ。
  Future<void> _onUploadBadgeTap(
      BuildContext context, WidgetRef ref, bool isSignedIn) async {
    if (!isSignedIn && recording.uploadState == UploadState.pending) {
      await _promptSignIn(context);
      return;
    }
    if (recording.uploadState == UploadState.actionRequired) {
      await _promptRetry(context, ref);
    }
  }

  Future<void> _onTranscriptBadgeTap(
      BuildContext context, WidgetRef ref) async {
    switch (recording.transcriptState) {
      case TranscriptState.done:
      case TranscriptState.partial:
        await AppRouter.toTranscript(context, recording.id);
      case TranscriptState.failed:
        await _retranscribe(context, ref);
      case TranscriptState.off:
      case TranscriptState.processing:
        break;
    }
  }

  Future<void> _promptSignIn(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Drive 未設定'),
        content: const Text(
          'この録音はまだ Drive にアップロードされていません。'
          'Google にサインインすると自動でアップロードされます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('後で'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('サインイン設定へ'),
          ),
        ],
      ),
    );
    if (go == true && context.mounted) {
      await AppRouter.toSettings(context);
    }
  }

  Future<void> _promptRetry(BuildContext context, WidgetRef ref) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('アップロード要対応'),
        content: const Text(
          'アップロードに失敗しました（認証切れ・フォルダ削除・容量超過など）。'
          '原因を解消してから再試行してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('閉じる'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
    if (retry == true && context.mounted) {
      await _run(
        context,
        () => ref.read(uploadControllerProvider).retryUpload(recording.id),
        fallback: 'アップロード再試行',
      );
    }
  }

  Future<void> _retranscribe(BuildContext context, WidgetRef ref) async {
    await _run(
      context,
      () => ref.read(transcriptionControllerProvider).retranscribe(recording.id),
      fallback: '再文字起こし',
      success: '再文字起こしを開始しました',
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String fallback,
    String? success,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (success != null) {
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
    } on NotWiredException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.feature} は統合フェーズで接続されます')),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text('$fallback に失敗しました')));
    }
  }
}
