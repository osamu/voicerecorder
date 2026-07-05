import 'package:flutter/material.dart';

import '../../../../core/database/tables.dart';

/// アップロードバッジ（§10.1）。4 状態＋未サインイン変種「Drive未設定」。
///
/// - pending: 未アップ（未サインイン時は「Drive未設定」→タップでサインイン誘導）
/// - uploading: アップ中
/// - done: 完了
/// - actionRequired: 要対応（タップで原因と手動再試行）
class UploadBadge extends StatelessWidget {
  const UploadBadge({
    super.key,
    required this.state,
    required this.isSignedIn,
    this.onTap,
  });

  final UploadState state;
  final bool isSignedIn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 未サインイン かつ 未アップの場合は「Drive未設定」変種。
    if (!isSignedIn && state == UploadState.pending) {
      return _Chip(
        icon: Icons.cloud_off_outlined,
        label: 'Drive未設定',
        fg: scheme.onSurfaceVariant,
        bg: scheme.surfaceContainerHighest,
        onTap: onTap,
      );
    }

    switch (state) {
      case UploadState.pending:
        return _Chip(
          icon: Icons.cloud_queue,
          label: '未アップ',
          fg: scheme.onSurfaceVariant,
          bg: scheme.surfaceContainerHighest,
          onTap: onTap,
        );
      case UploadState.uploading:
        return _Chip(
          icon: Icons.cloud_upload_outlined,
          label: 'アップ中',
          fg: scheme.onPrimaryContainer,
          bg: scheme.primaryContainer,
          onTap: onTap,
          showSpinner: true,
        );
      case UploadState.done:
        return _Chip(
          icon: Icons.cloud_done,
          label: '完了',
          fg: scheme.onSecondaryContainer,
          bg: scheme.secondaryContainer,
          onTap: onTap,
        );
      case UploadState.actionRequired:
        return _Chip(
          icon: Icons.error_outline,
          label: '要対応',
          fg: scheme.onErrorContainer,
          bg: scheme.errorContainer,
          onTap: onTap,
        );
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    this.onTap,
    this.showSpinner = false,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
