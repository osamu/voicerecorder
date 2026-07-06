# TODO.md — 実装プラン

> 詳細設計は `DESIGN.md`、要件は `PRD.md`、レビュー指摘の全文は `REVIEW.md` を参照。
> 括弧内の (B1)〜(B5) は REVIEW.md の Blocker、(#n) は主要指摘、(SC-n) は specChanges 番号。

---

## Phase 0: 疎通検証（着手初期・最優先）

計画済みリスクの潰し込み。**ここが通らない場合は設計の見直しに戻る**。

- [ ] Flutter プロジェクト雛形生成（`flutter create`、iOS/Android 最小設定のみ）
- [ ] (a) **バックグラウンド録音継続 PoC**: iOS（`UIBackgroundModes=audio` + `audio_session`）と Android（`flutter_foreground_task` microphone FGS）で、画面ロック・アプリ切替後も 30 分以上録音継続することを実機確認 (#2, #12)
- [ ] (b) **google_sign_in v7 + drive.file 疎通 PoC**: 実機でサインイン → `drive.file` スコープでフォルダ作成・ファイルアップロードまで通す。"unregistered callers" 問題（flutter#173407）に当たったら v6 フォールバックを判断 (B3)
- [ ] (c) **録音フォーマット実機確認**: iOS で AAC `.m4a`（モノラル 32kbps）、Android（API 29+ 実機/エミュ）で Ogg Opus が `record` で録れること、生成ファイルが PC/Drive 上で再生できることを確認 (B4, SC-4)
- [ ] (d) `record` の書き込み挙動確認: 録音中プロセス kill 後にファイルへ途中まで書かれているか（フラッシュ粒度）を両 OS で確認。不十分なら PCM ストリーム受領＋自前書き込み方式へ設計切替 (B2)

**DoD**: 上記 4 点が実機で確認でき、フォールバック要否（sign_in v6 / stream 書き込み）が確定している。

---

## Phase 1: プロジェクト基盤・権限・DB スキーマ

- [ ] 依存パッケージ追加（record, flutter_foreground_task, audio_session, google_sign_in, extension_google_sign_in_as_googleapis_auth, googleapis, workmanager, connectivity_plus, flutter_riverpod, riverpod_generator, drift, flutter_secure_storage, just_audio ほか）
- [ ] feature-first + core のディレクトリ構成を敷く（DESIGN.md §4.1）
- [ ] Android: `minSdkVersion 29`、`RECORD_AUDIO` / `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MICROPHONE` / `POST_NOTIFICATIONS` 宣言、foregroundServiceType=microphone (SC-6)
- [ ] iOS: `NSMicrophoneUsageDescription` 文言確定、`UIBackgroundModes=audio` (SC-15)
- [ ] iOS/Android バックアップ除外設定（`allowBackup=false` / dataExtractionRules / isExcludedFromBackup）＋ iOS `NSFileProtectionCompleteUntilFirstUserAuthentication` (#8, SC-14)
- [ ] drift スキーマ実装: `recordings` / `upload_jobs` / `transcription_jobs` / `settings`（DESIGN.md §5 の列定義どおり。enum は文字列格納、`(recordingId, kind)` UNIQUE） (#5, SC-16)
- [ ] DAO とリアクティブクエリ（一覧用 watch）実装＋ユニットテスト
- [ ] ログポリシーの実装（ログラッパ: トークン・タイトル・本文を出さない） (SC-14)

**DoD**: `flutter test` で DB の CRUD・watch テストが通り、両 OS でビルド・起動できる。

---

## Phase 2: 録音機能＋データ保全

- [ ] `RecordingService`（ドメイン層・Riverpod 非依存）実装: 開始時に recordings 行 INSERT（UUID・ISO8601+TZ）→録音→停止で duration/size 確定→upload_jobs 投入
- [ ] 命名規約実装: `YYYY-MM-DD_HH-mm-ss[_タイトル].<ext>`（秒まで・サニタイズ・録音開始時刻基準） (#13, SC-12)
- [ ] Android FGS 常駐通知に経過時間表示 / iOS は OS 標準インジケータのみ (#12, SC-6)
- [ ] 定期フラッシュ（約5秒ごと）の実装または Phase 0(d) の結果に基づく stream 書き込み (B2, SC-5)
- [ ] 割り込み処理: audio_session interruption 購読 → 確定保存 → 自動再開 → `_part2` 別セグメント継続、再開不可なら即ローカル通知 (B2, #2, SC-5)
- [ ] 起動時リカバリ: 未クローズファイル検出・修復 →「中断された録音を復元しました」として一覧＋キュー投入 (B2, SC-5)
- [ ] 空き容量チェック: 開始時＋録音中の閾値割れ警告＋枯渇時の安全クローズ (B2, SC-5)
- [ ] Android バッテリ最適化除外の誘導 UI＋録音中 partial wakelock (SC-6)
- [ ] 多重録音排他＋録音開始は FG 起点のみ（Android 11+ 制約） (#11)
- [ ] マイク権限フロー: 拒否→説明→OS 設定誘導 (#10, SC-17)

**DoD**: 画面ロック・割り込み（着信/Siri）・強制 kill のいずれでも録音データが失われない（直近数秒以内の損失に収まる）ことを実機で確認。

---

## Phase 3: 一覧・バッジ・再生 UI

- [ ] 録音一覧画面: 日時・録音時間・サイズ・アップバッジ（4状態＋Drive未設定）・文字起こしバッジ（5状態）を drift watch + StreamProvider で駆動 (#11, SC-11)
- [ ] 全画面共通の録音中バー（経過時間＋停止）＋録音中の削除/改名不可制御 (#11, SC-11)
- [ ] 再生 UI: シークバー＋±15秒＋再生速度 (#15, SC-19)
- [ ] タイトル変更: タイトル部のみ・サニタイズ・ローカルファイル改名（Drive 反映は Phase 5 で fileId 接続） (SC-12)
- [ ] 削除フロー: 既定=ローカルのみ / Drive 側削除は明示チェック＋赤字警告 / 未アップは強警告＋キュー除去 (B5, SC-11)
- [ ] オフラインバナー（connectivity_plus） (SC-17)
- [ ] txt 閲覧画面（Phase 6 の出力を表示。先に画面だけ用意） (#15)

**DoD**: 録音→一覧反映→再生→改名→削除の一連の操作が動き、バッジが DB 状態に追従する。

---

## Phase 4: 認証＋Drive 基盤（drive.file）

- [ ] google_sign_in（Phase 0 で確定した版）＋ `drive.file` スコープでのサインイン/サインアウト
- [ ] トークンを flutter_secure_storage に保存、サインアウト時に revoke (#8, SC-14)
- [ ] `/CloudRecorder/` ルートフォルダの get-or-create、fileId を settings に保存 (B3, SC-7)
- [ ] 日付サブフォルダ `<年>/<年-月>` の get-or-create（録音開始時刻基準・appProperties パスキー付与） (SC-7, SC-12)
- [ ] ルートフォルダ削除/trashed 検出と再作成導線 (SC-9)
- [ ] サインアウト時の未アップ N 件警告＋キュー保持 (SC-9)
- [ ] オンボーディング: 録音はサインイン不要、「Drive未設定」バッジ→タップでサインイン誘導 (#10, SC-17)

**DoD**: サインイン→`/CloudRecorder/2026/2026-07/` へ手動アップロードが通り、サインアウト→再サインインでもフォルダが重複作成されない。

---

## Phase 5: アップロードキュー（resumable・冪等・状態機械・BG）

- [ ] `UploadQueue`（ドメイン層）: pending→uploading→done / retryableFailed（指数バックオフ 30s〜1h）/ permanentFailed の状態機械 (#5, SC-9)
- [ ] resumable upload 実装＋ `resumableUri` 永続化・中断再開 (SC-8)
- [ ] 冪等化: appProperties に `vrId`(UUID)/`vrKind` 付与、リトライ前の既存検索で二重作成防止、成功時 fileId 保存 (SC-8)
- [ ] fileId 基準の改名・削除の Drive 反映＋録音単位の直列化（Phase 3 の操作と接続） (SC-8, SC-12)
- [ ] 一時エラー/恒久エラーの分類（ネットワーク・5xx・429 vs 401・フォルダ削除・容量超過）と「要対応」バッジ＋原因別解決導線＋手動再試行 (SC-9)
- [ ] 認証エラー時: キュー保持で一時停止＋通知＋バナー再サインイン誘導、成功で自動再開 (SC-9)
- [ ] 録音停止直後の自動アップ（FG 中の即時 resumable）＋connectivity 復帰・FG 復帰時の flush (#6, SC-10)
- [ ] Android: workmanager による BG リトライ（callbackDispatcher はドメイン層＋DB を直接使用） (#6, SC-10, SC-16)
- [ ] 24 時間以上滞留のローカル通知 (SC-10)
- [ ] 逼迫時自動削除: アップ済みのみ・古い順・空き 500MB 閾値、`localPath=NULL` 化＋「Drive から再取得」導線 (B5, SC-10, SC-11)
- [ ] 起動時: uploading 中断分の pending 戻し・キュー再開（DESIGN.md §12）

**DoD**: 機内モードで録音停止→キュー滞留→復帰後自動アップ、アップ中の kill→再起動→resumable 再開、リトライ連打でも Drive 上にファイルが 1 つだけ、を実機確認。

---

## Phase 6: 文字起こし（抽象レイヤ＋クラウド STT＋txt 別アップ）

- [ ] 抽象 IF 実装: `TranscriptionEvent`（Partial/Progress/Completed/Failed）、`TranscriptionEngine` 基底＋capability＋`checkAvailability()`、`StreamingTranscriptionEngine` / `BatchTranscriptionEngine` 分離（DESIGN.md §8.2 のコードどおり） (#9, B1, SC-2)
- [ ] `TranscriptionEngineRegistry`（Riverpod provider で差し替え可能に） (SC-2)
- [ ] `TranscriptionService.transcribe(recordingId)`: capability 検証→job 永続化→submit→jobHandle 保存→watch→DB 反映 (#9, SC-2)
- [ ] 起動時 `resumePendingJobs()`: submitted/running の再購読 (#9, SC-2)
- [ ] `CloudSttEngine`（Whisper API 等、Batch）実装: maxFileSize 検証・API キーは secure_storage・失敗分類（retryable/permanent） (B1, SC-1)
- [ ] Completed→`.txt` ローカル生成→`upload_jobs(kind=transcript, 低優先度)` 投入、appProperties で音声とペアリング (SC-3, SC-18)
- [ ] 部分成功: partialText を txt 保存・アップ＋「一部のみ」バッジ (SC-3)
- [ ] 再文字起こし（一覧メニュー）: Drive txt は fileId 維持の同名上書き (SC-2, SC-3)
- [ ] 言語設定: エンジン動的照会で対応言語のみ表示、autoDetect では非表示、非対応言語は自動スキップ＋バッジ (SC-3)
- [ ] 録音優先の担保確認: 文字起こし失敗・OFF でも音声アップが影響を受けないことをテスト (SC-1)
- [ ] txt 閲覧画面へ実データ接続（Phase 3 の画面）

**DoD**: 録音停止→音声アップ＋文字起こし→`.txt` が Drive の同フォルダに別ファイルとして出現。アプリ再起動を挟んでもジョブが完走する。文字起こし失敗時も音声は必ず上がる。

---

## Phase 7: 設定画面・仕上げ

- [ ] 設定画面: アカウント連携、Drive 保存先表示（`/CloudRecorder/` 固定＋開くリンク）、文字起こし ON/OFF・エンジン・言語・API キー、ストレージ使用量＋手動一括削除
- [ ] マイク以外の権限フロー整備（通知権限は初回録音時、拒否でも録音可） (SC-17)
- [ ] 全体の状態遷移の結合テスト（DESIGN.md §14 相当の検証項目: BG 録音・機内モード・バッジ追従）
- [ ] エッジケース掃討: 録音中の設定変更、サインアウト中のアップ、容量枯渇、フォルダ手動削除

**DoD**: PRD.md の受け入れ基準（検証項目）をすべて実機で通過。

---

## Phase 8: ストア公開対応（将来・MVP 外）

- [ ] 初回起動時の録音同意ダイアログ＋利用規約/プライバシーポリシー URL (#7, SC-13)
- [ ] 文字起こし初回 ON 時の「音声が外部サーバに送信される場合があります」明示オプトイン (SC-13)
- [ ] iOS App Privacy / Android Data Safety 申告 (SC-15)
- [ ] OAuth 同意画面の本審査（drive.file は CASA 不要だが検証は必要）
- [ ] Live Activity（iOS 16.1+）による録音中表示の検討 (#12)
- [ ] libopus FFI 統合による `.opus` 統一の検討 (B4)
- [ ] リアルタイム文字起こしオプション（StreamingTranscriptionEngine 実装＋録音併用のネイティブパイプライン PoC） (B1)
