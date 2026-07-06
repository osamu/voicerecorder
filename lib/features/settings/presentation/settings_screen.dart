import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/contracts.dart';
import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/security/secure_storage.dart';
import '../../recordings_list/presentation/format.dart';
import '../application/settings_providers.dart';

/// 設定画面（§10.6）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: const [
          _AccountSection(),
          Divider(height: 1),
          _DriveSection(),
          Divider(height: 1),
          _TranscriptionSection(),
          Divider(height: 1),
          _StorageSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// アカウント連携
// ---------------------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).maybeWhen(
          data: (s) => s,
          orElse: () => AuthState.signedOut,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('アカウント連携'),
        if (auth.isSignedIn)
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(auth.account?.displayName ?? 'Google アカウント'),
            subtitle: Text(auth.account?.email ?? ''),
            trailing: OutlinedButton(
              onPressed: () => _signOut(context, ref),
              child: const Text('サインアウト'),
            ),
          )
        else
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Google にサインイン'),
            subtitle: const Text('サインインすると録音が自動で Drive にアップロードされます'),
            trailing: FilledButton(
              onPressed: () => _signIn(context, ref),
              child: const Text('サインイン'),
            ),
          ),
      ],
    );
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider).signIn();
    } on NotWiredException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.feature} は統合フェーズで接続されます')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('サインインに失敗しました')),
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // 未アップ件数を取得して警告する。
    var pending = 0;
    try {
      pending = await ref.read(uploadControllerProvider).pendingUploadCount();
    } catch (_) {
      pending = 0;
    }
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('サインアウト'),
        content: Text(
          pending > 0
              ? '未アップロードの録音が $pending 件あります。'
                  'サインアウトしてもキューは保持され、次回サインイン時に再開されます。'
              : 'サインアウトします。録音自体はサインインなしでも続けられます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('サインアウト'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider).signOut();
    } on NotWiredException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.feature} は統合フェーズで接続されます')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('サインアウトに失敗しました')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Drive 保存先
// ---------------------------------------------------------------------------

class _DriveSection extends StatelessWidget {
  const _DriveSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeader('Drive 保存先'),
        ListTile(
          leading: Icon(Icons.folder_outlined),
          title: Text('/CloudRecorder/'),
          subtitle: Text('保存先は固定です。年/月のサブフォルダに自動整理されます。'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 文字起こし
// ---------------------------------------------------------------------------

class _TranscriptionSection extends ConsumerWidget {
  const _TranscriptionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(transcriptionEnabledProvider);
    final engines =
        ref.watch(transcriptionControllerProvider).availableEngines();
    final engineId = ref.watch(transcriptionEngineIdProvider);
    final localeId = ref.watch(transcriptionLocaleIdProvider);
    final localesAsync = ref.watch(supportedLocalesProvider);
    final apiKeyPresent = ref.watch(sttApiKeyPresentProvider).maybeWhen(
          data: (v) => v,
          orElse: () => false,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('文字起こし'),
        SwitchListTile(
          title: const Text('文字起こしを有効にする'),
          subtitle: const Text('録音後にクラウド STT で自動的に文字起こしします'),
          value: enabled,
          onChanged: (v) => ref.read(settingsDaoProvider).setValue(
                SettingsKeys.transcriptionEnabled,
                v ? 'true' : 'false',
              ),
        ),
        // エンジン選択（MVP はクラウド STT のみ）。
        ListTile(
          enabled: enabled,
          leading: const Icon(Icons.hearing),
          title: const Text('エンジン'),
          trailing: DropdownButton<String>(
            value: engineId,
            items: [
              for (final e in engines)
                DropdownMenuItem(value: e.id, child: Text(e.displayName)),
            ],
            onChanged: enabled
                ? (v) {
                    if (v == null) return;
                    ref.read(settingsDaoProvider).setValue(
                          SettingsKeys.transcriptionEngineId,
                          v,
                        );
                  }
                : null,
          ),
        ),
        // 言語選択（エンジン照会で構築。空なら autoDetect として非表示）。
        localesAsync.maybeWhen(
          data: (locales) {
            if (locales.isEmpty) return const SizedBox.shrink();
            final value = locales.contains(localeId) ? localeId : locales.first;
            return ListTile(
              enabled: enabled,
              leading: const Icon(Icons.language),
              title: const Text('言語'),
              trailing: DropdownButton<String>(
                value: value,
                items: [
                  for (final l in locales)
                    DropdownMenuItem(value: l, child: Text(l)),
                ],
                onChanged: enabled
                    ? (v) {
                        if (v == null) return;
                        ref.read(settingsDaoProvider).setValue(
                              SettingsKeys.transcriptionLocaleId,
                              v,
                            );
                      }
                    : null,
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
        // API キー。
        ListTile(
          enabled: enabled,
          leading: const Icon(Icons.key),
          title: const Text('API キー'),
          subtitle: Text(apiKeyPresent ? '設定済み' : '未設定'),
          trailing: TextButton(
            onPressed: enabled ? () => _editApiKey(context, ref) : null,
            child: Text(apiKeyPresent ? '変更' : '入力'),
          ),
        ),
      ],
    );
  }

  Future<void> _editApiKey(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('STT API キー'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API キー',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final key = controller.text.trim();
      if (key.isNotEmpty) {
        await ref.read(secureStoreProvider).write(SecureKeys.sttApiKey, key);
        ref.invalidate(sttApiKeyPresentProvider);
      }
    }
    controller.dispose();
  }
}

// ---------------------------------------------------------------------------
// ストレージ
// ---------------------------------------------------------------------------

class _StorageSection extends ConsumerWidget {
  const _StorageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(storageUsageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('ストレージ'),
        usageAsync.when(
          loading: () => const ListTile(
            leading: Icon(Icons.storage),
            title: Text('使用量'),
            trailing: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => const ListTile(
            leading: Icon(Icons.storage),
            title: Text('使用量'),
            subtitle: Text('取得できませんでした'),
          ),
          data: (usage) => Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('ローカル使用量'),
                subtitle: Text(RecordingFormat.size(usage.totalBytes)),
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('アップ済みローカルを一括削除'),
                subtitle: Text(
                  usage.reclaimableFileCount > 0
                      ? '${usage.reclaimableFileCount} 件・'
                          '${RecordingFormat.size(usage.reclaimableBytes)} を解放できます'
                      : '削除できるファイルはありません',
                ),
                trailing: TextButton(
                  onPressed: usage.reclaimableFileCount > 0
                      ? () => _bulkDelete(context, ref)
                      : null,
                  child: const Text('削除'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _bulkDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('アップ済みローカルを削除'),
        content: const Text(
          'Drive へアップロード済みの録音の、端末内ファイルのみを削除します。'
          '一覧には残り、再生時は Drive から再取得できます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(uploadControllerProvider).deleteUploadedLocalFiles();
      ref.invalidate(storageUsageProvider);
    } on NotWiredException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.feature} は統合フェーズで接続されます')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('削除に失敗しました')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// 共通
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
