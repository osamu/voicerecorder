import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/contracts.dart';
import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';

/// 削除フロー（§10.4 / B5）。
///
/// - 既定はローカルのみ削除（Drive 側は残る）。
/// - 「Drive からも削除」は明示チェックボックス＋赤字警告。
/// - 未アップロード録音は強警告文言＋キューからジョブ除去（UploadController が処理）。
Future<void> showDeleteDialog(BuildContext context, Recording recording) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DeleteDialog(recording: recording),
  );
}

class _DeleteDialog extends ConsumerStatefulWidget {
  const _DeleteDialog({required this.recording});

  final Recording recording;

  @override
  ConsumerState<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends ConsumerState<_DeleteDialog> {
  bool _alsoDrive = false;
  bool _deleting = false;

  bool get _isUploaded =>
      widget.recording.uploadState == UploadState.done;

  bool get _isUnuploaded => !_isUploaded;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await ref.read(uploadControllerProvider).deleteRecording(
            widget.recording.id,
            alsoDeleteFromDrive: _alsoDrive,
          );
      if (mounted) Navigator.of(context).pop();
    } on NotWiredException catch (e) {
      _snack('${e.feature} は統合フェーズで接続されます');
    } catch (_) {
      _snack('削除に失敗しました');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('録音を削除'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 未アップは強警告。
          if (_isUnuploaded)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: scheme.onErrorContainer, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'まだ Drive に上がっていません。削除すると復元できません。',
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Text('この録音を端末から削除します。'),
          // Drive からも削除（アップ済みのときのみ意味がある）。
          if (_isUploaded)
            CheckboxListTile(
              value: _alsoDrive,
              onChanged: _deleting
                  ? null
                  : (v) => setState(() => _alsoDrive = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Drive からも削除する',
                style: TextStyle(color: scheme.error),
              ),
              subtitle: _alsoDrive
                  ? Text(
                      'Drive 上の音声と .txt も完全に削除されます。元に戻せません。',
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    )
                  : null,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _deleting ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('削除'),
        ),
      ],
    );
  }
}
