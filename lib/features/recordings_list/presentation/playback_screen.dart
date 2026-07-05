import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/contracts.dart';
import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../application/recordings_list_providers.dart';
import 'format.dart';

/// 再生画面（§10.3）。
///
/// - シークバー・±15 秒・再生速度 0.5x〜2.0x。
/// - localPath=NULL（逼迫時削除済み）の場合は「Drive から再取得」ボタンを出す。
class PlaybackScreen extends ConsumerStatefulWidget {
  const PlaybackScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  final AudioPlayer _player = AudioPlayer();

  /// 現在ロード済みのローカルパス（再ロード判定用）。
  String? _loadedPath;
  double _speed = 1.0;
  bool _refetching = false;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded(String? localPath) async {
    if (localPath == null || localPath == _loadedPath) return;
    _loadedPath = localPath;
    try {
      await _player.setFilePath(localPath);
      await _player.setSpeed(_speed);
    } catch (_) {
      _loadedPath = null;
    }
  }

  Future<void> _skip(Duration delta) async {
    final pos = _player.position + delta;
    final dur = _player.duration ?? Duration.zero;
    final target = pos < Duration.zero
        ? Duration.zero
        : (pos > dur ? dur : pos);
    await _player.seek(target);
  }

  Future<void> _refetch() async {
    setState(() => _refetching = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(uploadControllerProvider)
          .refetchLocalCopy(widget.recordingId);
      // 成功すると recordingByIdProvider（localPath）が更新され、build で再ロードされる。
    } on NotWiredException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.feature} は統合フェーズで接続されます')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Drive から再取得できませんでした')),
      );
    } finally {
      if (mounted) setState(() => _refetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recordingByIdProvider(widget.recordingId));

    return Scaffold(
      appBar: AppBar(title: const Text('再生')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('録音を読み込めませんでした')),
        data: (recording) {
          if (recording == null) {
            return const Center(child: Text('録音が見つかりません'));
          }
          // ローカルがあればロードを試みる。
          _ensureLoaded(recording.localPath);
          return _buildBody(recording);
        },
      ),
    );
  }

  Widget _buildBody(Recording recording) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            RecordingFormat.title(recording),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            RecordingFormat.dateTime(recording),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (recording.localPath == null)
            _RefetchPanel(refetching: _refetching, onRefetch: _refetch)
          else
            _buildPlayer(),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Column(
      children: [
        // シークバー＋時刻。
        StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final total = _player.duration ?? Duration.zero;
            final max = total.inMilliseconds.toDouble();
            final value = position.inMilliseconds
                .clamp(0, max <= 0 ? 0 : max.toInt())
                .toDouble();
            return Column(
              children: [
                Slider(
                  min: 0,
                  max: max <= 0 ? 1 : max,
                  value: max <= 0 ? 0 : value,
                  onChanged: max <= 0
                      ? null
                      : (v) => _player
                          .seek(Duration(milliseconds: v.toInt())),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(RecordingFormat.clock(position)),
                      Text(RecordingFormat.clock(total)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // 再生コントロール（±15秒＋再生/一時停止）。
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.replay_10),
              tooltip: '15秒戻る',
              onPressed: () => _skip(const Duration(seconds: -15)),
            ),
            const SizedBox(width: 8),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                final completed =
                    snap.data?.processingState == ProcessingState.completed;
                return IconButton.filled(
                  iconSize: 40,
                  icon: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () async {
                    if (completed) {
                      await _player.seek(Duration.zero);
                    }
                    if (playing) {
                      await _player.pause();
                    } else {
                      await _player.play();
                    }
                  },
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.forward_10),
              tooltip: '15秒進む',
              onPressed: () => _skip(const Duration(seconds: 15)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 再生速度。
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('再生速度'),
            const SizedBox(width: 12),
            DropdownButton<double>(
              value: _speed,
              items: [
                for (final s in _speeds)
                  DropdownMenuItem(value: s, child: Text('${s}x')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _speed = v);
                await _player.setSpeed(v);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// localPath=NULL 時の再取得パネル。
class _RefetchPanel extends StatelessWidget {
  const _RefetchPanel({required this.refetching, required this.onRefetch});

  final bool refetching;
  final VoidCallback onRefetch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.cloud_download_outlined,
            size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        const Text(
          'この録音は端末から削除されています。\n再生するには Drive から再取得してください（要オンライン）。',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: refetching ? null : onRefetch,
          icon: refetching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: const Text('Drive から再取得'),
        ),
      ],
    );
  }
}
