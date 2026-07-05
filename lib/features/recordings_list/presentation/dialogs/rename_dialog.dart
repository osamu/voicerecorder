import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/contracts.dart';
import '../../../../app/providers.dart';
import '../../../../core/constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/naming/naming.dart';

/// タイトル変更ダイアログ（§10.3 / §11）。
///
/// - 変更できるのは**タイトル部のみ**（日時プレフィックスは不変）。
/// - 入力は [Naming.sanitizeTitle] でサニタイズ。
/// - 確定時は upload feature の [UploadController.renameRecording] を呼ぶ
///   （ローカルファイル改名＋Drive 反映＝fileId 基準）。
Future<void> showRenameDialog(BuildContext context, Recording recording) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RenameDialog(recording: recording),
  );
}

class _RenameDialog extends ConsumerStatefulWidget {
  const _RenameDialog({required this.recording});

  final Recording recording;

  @override
  ConsumerState<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<_RenameDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.recording.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final sanitized = Naming.sanitizeTitle(_controller.text);
    setState(() => _saving = true);
    try {
      await ref
          .read(uploadControllerProvider)
          .renameRecording(widget.recording.id, sanitized);
      if (mounted) Navigator.of(context).pop();
    } on NotWiredException catch (e) {
      _snack('${e.feature} は統合フェーズで接続されます');
    } catch (_) {
      _snack('改名に失敗しました');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('タイトルを変更'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: AppConstants.maxTitleLength,
            decoration: const InputDecoration(
              labelText: 'タイトル',
              hintText: '空欄の場合は日時が使われます',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '日時（録音開始時刻）の部分は変更できません。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
