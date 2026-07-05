import 'package:flutter/material.dart';

import '../../../../core/database/tables.dart';

/// 文字起こしバッジ（§8.6 / §10.1）。5 状態。
///
/// - off: OFF（非表示）
/// - processing: 処理中
/// - done: 完了（タップで txt 閲覧）
/// - partial: 一部のみ（タップで txt 閲覧）
/// - failed: 失敗（タップで再実行）
class TranscriptBadge extends StatelessWidget {
  const TranscriptBadge({
    super.key,
    required this.state,
    this.onTap,
  });

  final TranscriptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (state) {
      case TranscriptState.off:
        // OFF は非表示（バッジを出さない）。
        return const SizedBox.shrink();
      case TranscriptState.processing:
        return _Chip(
          icon: Icons.subtitles_outlined,
          label: '文字起こし中',
          fg: scheme.onTertiaryContainer,
          bg: scheme.tertiaryContainer,
          onTap: onTap,
          showSpinner: true,
        );
      case TranscriptState.done:
        return _Chip(
          icon: Icons.subtitles,
          label: '文字起こし',
          fg: scheme.onSecondaryContainer,
          bg: scheme.secondaryContainer,
          onTap: onTap,
        );
      case TranscriptState.partial:
        return _Chip(
          icon: Icons.subtitles,
          label: '一部のみ',
          fg: scheme.onTertiaryContainer,
          bg: scheme.tertiaryContainer,
          onTap: onTap,
        );
      case TranscriptState.failed:
        return _Chip(
          icon: Icons.refresh,
          label: '文字起こし失敗',
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
