import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/contracts.dart';
import '../../../../app/providers.dart';
import '../format.dart';

/// 全画面共通の「録音中バー」（§10.2）。
///
/// 進行中録音があるときのみ表示し、経過時間（1 秒ごと更新）と停止ボタンを出す。
/// どの画面からでも状態が見え、停止できるよう Scaffold の bottom に差し込む想定。
class RecordingBar extends ConsumerStatefulWidget {
  const RecordingBar({super.key});

  @override
  ConsumerState<RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends ConsumerState<RecordingBar> {
  Timer? _ticker;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _stop(ActiveRecording active) async {
    setState(() => _stopping = true);
    try {
      await ref.read(recordingControllerProvider).stop();
    } on NotWiredException catch (e) {
      _snack(e.feature);
    } catch (_) {
      _snack('録音の停止');
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  void _snack(String feature) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature は統合フェーズで接続されます')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeRecordingProvider).maybeWhen(
          data: (a) => a,
          orElse: () => null,
        );
    if (active == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(active.startedAt);

    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // 赤い録音インジケータ。
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '録音中',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                RecordingFormat.clock(elapsed),
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _stopping ? null : () => _stop(active),
                icon: _stopping
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop),
                label: const Text('停止'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
