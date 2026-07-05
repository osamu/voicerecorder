import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../application/recordings_list_providers.dart';

/// オフラインバナー（§10.1）。connectivity_plus 検知でオフライン時に表示。
///
/// 「オフライン: N 件が未アップロード」。オンライン時・未アップ 0 件時は非表示。
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider).maybeWhen(
          data: (v) => v,
          orElse: () => true, // 判定不能時はオンライン扱い（バナーを出さない）。
        );
    if (online) return const SizedBox.shrink();

    final outstanding = ref.watch(outstandingUploadCountProvider).maybeWhen(
          data: (n) => n,
          orElse: () => 0,
        );

    final scheme = Theme.of(context).colorScheme;
    final message = outstanding > 0
        ? 'オフライン: $outstanding 件が未アップロード'
        : 'オフライン';

    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wifi_off, size: 18, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
