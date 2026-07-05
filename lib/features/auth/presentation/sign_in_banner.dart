import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_state.dart';
import 'auth_providers.dart';

/// Google サインインを実行するボタン。
///
/// 押下中はスピナーを表示し、失敗時は SnackBar で通知する（本文は最小限）。
class SignInButton extends ConsumerStatefulWidget {
  const SignInButton({super.key, this.label = 'Google でサインイン'});

  final String label;

  @override
  ConsumerState<SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends ConsumerState<SignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signIn();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('サインインに失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _busy ? null : _signIn,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.login),
      label: Text(widget.label),
    );
  }
}

/// 未サインイン時に表示する「Drive未設定」誘導バナー（§10.5 / SC-17）。
///
/// 録音はサインイン不要のため、バナーはブロッキングにしない。サインイン済みの
/// 場合は何も描画しない（[SizedBox.shrink]）。
class SignInBanner extends ConsumerWidget {
  const SignInBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);
    final signedIn = state.value is AuthSignedIn;
    if (signedIn) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drive未設定',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    '録音はできますが、サインインすると自動で Google Drive に保存されます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SignInButton(label: 'サインイン'),
          ],
        ),
      ),
    );
  }
}

/// サインアウトボタン。未アップ N 件があれば確認ダイアログで警告する（§7.5）。
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  Future<void> _confirmAndSignOut(BuildContext context, WidgetRef ref) async {
    final service = ref.read(authServiceProvider);
    final pending = await service.unuploadedCount();
    if (!context.mounted) {
      return;
    }
    final message = pending > 0
        ? '未アップロードの録音が $pending 件あります。サインアウトしても録音は保持され、'
            '再サインイン後にアップロードされます。サインアウトしますか？'
        : 'サインアウトしますか？';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('サインアウト'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('サインアウト'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await service.signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _confirmAndSignOut(context, ref),
      icon: const Icon(Icons.logout),
      label: const Text('サインアウト'),
    );
  }
}
