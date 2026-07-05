import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/contracts.dart';
import '../../../app/providers.dart';
import '../application/onboarding_providers.dart';

/// オンボーディング（§10.5）。
///
/// - 初回起動時は**マイク権限のみ必須**。
/// - 拒否時: 説明 → OS 設定への誘導、の 2 段フロー。
/// - 通知権限・バッテリ最適化除外は初回録音時に案内する（ここでは扱わない）。
/// - 録音はサインイン不要である旨を明示する。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// 直近のマイク権限リクエスト結果（説明/設定誘導の分岐用）。
  AppPermissionStatus? _lastStatus;
  bool _requesting = false;

  Future<void> _requestMic() async {
    setState(() => _requesting = true);
    try {
      final status =
          await ref.read(permissionControllerProvider).requestMicrophone();
      setState(() => _lastStatus = status);
      if (status == AppPermissionStatus.granted) {
        await _complete();
      }
    } catch (_) {
      // 権限機能未接続時も先へ進めるよう完了扱いにはしない（説明を出す）。
      setState(() => _lastStatus = AppPermissionStatus.denied);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _complete() async {
    await ref.read(markOnboardingCompleteProvider)();
    // RootGate が onboardingComplete を watch しており、一覧へ自動遷移する。
  }

  Future<void> _openSettings() async {
    try {
      await ref.read(permissionControllerProvider).openAppSettings();
    } catch (_) {
      // no-op
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final denied = _lastStatus == AppPermissionStatus.denied;
    final permanentlyDenied =
        _lastStatus == AppPermissionStatus.permanentlyDenied;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.mic, size: 88, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'ボイスレコーダへようこそ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                '会議を録音すると、自動で Google Drive にアップロードされます。'
                '録音を始めるにはマイクの使用を許可してください。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.cloud_off,
                text: 'サインインは不要です。録音はいつでも始められ、'
                    'サインインすると自動アップロードが有効になります。',
              ),
              const SizedBox(height: 24),
              if (denied)
                _Notice(
                  color: scheme.tertiaryContainer,
                  onColor: scheme.onTertiaryContainer,
                  text: 'マイクの使用が許可されませんでした。録音にはマイク権限が必要です。'
                      'もう一度お試しください。',
                ),
              if (permanentlyDenied)
                _Notice(
                  color: scheme.errorContainer,
                  onColor: scheme.onErrorContainer,
                  text: 'マイク権限が拒否されています。OS の設定画面から手動で許可してください。',
                ),
              const Spacer(),
              if (permanentlyDenied)
                FilledButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('設定を開く'),
                )
              else
                FilledButton(
                  onPressed: _requesting ? null : _requestMic,
                  child: _requesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(denied ? 'もう一度許可する' : 'マイクを許可して始める'),
                ),
              const SizedBox(height: 12),
              // 権限をスキップしても一覧は見られる（録音時に再度要求される）。
              TextButton(
                onPressed: _requesting ? null : _complete,
                child: const Text('あとで（一覧を見る）'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.color,
    required this.onColor,
    required this.text,
  });

  final Color color;
  final Color onColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: onColor)),
    );
  }
}
