# CLAUDE.md — 開発ガイド

## プロジェクト概要

「どんな会議でも、録音すれば自動でクラウド（Google Drive）へ上がるボイスレコーダ」の Flutter アプリ（iOS + Android）。録音停止と同時に音声ファイルを Drive のアプリ管理フォルダ `/VoiceRecorder/` 配下へ自動アップロードし、録音後にクラウド STT で非同期文字起こしした `.txt` を別ファイルとしてアップする。Drive をトリガーにした後段 Workflow（要約・議事録・タスク抽出）への接続が最終目的。現在はグリーンフィールド（Flutter プロジェクト未生成）。

## 技術スタック

- **Flutter**（iOS + Android、`minSdkVersion 29`）
- 録音: `record`（iOS=AAC `.m4a` モノラル32kbps / Android=Ogg Opus。**非統一を許容**）
- BG 継続: `flutter_foreground_task`（Android microphone FGS）+ `audio_session`（iOS `UIBackgroundModes=audio`）
- 認証/Drive: `google_sign_in` v7 + `extension_google_sign_in_as_googleapis_auth` + `googleapis`（**`drive.file` スコープのみ**、resumable upload）
- キュー/BG 実行: `workmanager` + `connectivity_plus`
- 状態管理: `flutter_riverpod` + `riverpod_generator`（UI 層のみ）
- 永続化: `drift`（`recordings` / `upload_jobs` / `transcription_jobs`）
- 機微情報: `flutter_secure_storage`
- 文字起こし: クラウド STT（Whisper API 等）を HTTP 直叩き。`speech_to_text` は将来のリアルタイムオプション用（MVP 不使用）

## 想定コマンド

```bash
flutter pub get                                        # 依存取得
dart run build_runner build --delete-conflicting-outputs  # drift / riverpod_generator コード生成
flutter run                                            # 実行（実機推奨。録音・BG 検証はエミュ不可の項目あり）
flutter test                                           # テスト
flutter analyze                                        # 静的解析
```

## ディレクトリ構成の要点（feature-first + core）

```
lib/
  app/          # ルーティング, テーマ, ProviderScope, 起動時リカバリ
  core/         # audio_session / background / database(drift) / drive / security
  features/
    recording/          # 録音＋データ保全（フラッシュ・割り込み・リカバリ）
    recordings_list/    # 一覧・バッジ・再生・改名・削除
    upload/             # UploadQueue（resumable・冪等・状態機械）
    transcription/      # 抽象IF＋engines/（既定: cloud_stt）
    auth/ settings/ onboarding/
```

## 重要な設計原則（違反しないこと）

1. **状態の single source of truth は DB（drift）**。アップ状態・文字起こし状態はジョブテーブルが正。UI は drift の watch を StreamProvider で購読。メモリ状態を正としない。
2. **ドメイン層は Riverpod 非依存**。BG isolate（workmanager / foreground_task）からはドメイン層＋DB を直接使う。
3. **STT 抽象化**: 出力は `TranscriptionEvent` ストリームで統一、入力は `StreamingTranscriptionEngine` / `BatchTranscriptionEngine` に分離。単一 IF に統合しない。ジョブ（jobHandle）は DB 永続化し起動時に再購読。
4. **Drive は `drive.file` スコープ＋アプリ自作 `/VoiceRecorder/` 配下のみ**。任意既存フォルダは扱わない。Drive 操作（改名・削除・txt 紐付け）は常に fileId 基準、appProperties の UUID で冪等化。
5. **音声フォーマット非統一を許容**（iOS `.m4a` / Android `.opus`）。ffmpeg での変換はしない（ffmpeg-kit は EOL）。
6. **録音優先／文字起こしベストエフォート**。文字起こしの失敗が音声アップロードを妨げてはならない。録音自体はサインイン不要で常に可能。
7. **未アップロード録音を自動削除しない**。逼迫時削除はアップ済み・古い順のみ。
8. トークンは `flutter_secure_storage`、ログにトークン・タイトル・文字起こし本文を出さない。

## 参照ドキュメント

- 詳細設計（スキーマ・状態機械・抽象 IF のコード片・命名規約）→ **`DESIGN.md`**
- 作業計画（Phase 0 の疎通検証から。チェックボックス管理）→ **`TODO.md`**
- プロダクト要件 → **`PRD.md`**
- レビュー指摘の全文（65 件・Blocker の背景）→ **`REVIEW.md`**
- 承認済み実装計画（原本）→ `~/.claude/plans/claude-md-prd-md-sleepy-deer.md`

実装に着手する際は、まず `TODO.md` の Phase 0（BG 録音・drive.file 疎通・フォーマット実機確認）から始めること。
