import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/recordings_list_providers.dart';
import '../../../core/database/tables.dart';
import 'format.dart';

/// txt 閲覧画面（§10.3）。
///
/// `transcriptLocalPath` の内容をプレーン表示する。partial（一部のみ）時は
/// 冒頭に注記を出す。localPath の txt が無い場合は案内を表示する。
class TranscriptViewScreen extends ConsumerWidget {
  const TranscriptViewScreen({super.key, required this.recordingId});

  final String recordingId;

  Future<String?> _readTranscript(String? path) async {
    if (path == null) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recordingByIdProvider(recordingId));

    return Scaffold(
      appBar: AppBar(title: const Text('文字起こし')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('読み込めませんでした')),
        data: (recording) {
          if (recording == null) {
            return const Center(child: Text('録音が見つかりません'));
          }
          final isPartial =
              recording.transcriptState == TranscriptState.partial;
          return FutureBuilder<String?>(
            future: _readTranscript(recording.transcriptLocalPath),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final text = snap.data;
              if (text == null || text.trim().isEmpty) {
                return const _NoTranscript();
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    RecordingFormat.title(recording),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    RecordingFormat.dateTime(recording),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (isPartial) const _PartialNote(),
                  SelectableText(text),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PartialNote extends StatelessWidget {
  const _PartialNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '一部のみ: 文字起こしが途中で失敗したため、得られた分のみ表示しています。',
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTranscript extends StatelessWidget {
  const _NoTranscript();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.subtitles_off_outlined,
                size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text(
              '表示できる文字起こしがありません。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
