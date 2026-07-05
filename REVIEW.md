# 仕様レビュー指摘（Fable 多面レビュー）

> 承認済み計画 `~/.claude/plans/claude-md-prd-md-sleepy-deer.md` に対する、Fable モデル6エージェント（技術的実現性／要件網羅・矛盾／UX・エッジケース／プライバシ・セキュリティ・法務／STT抽象化設計）による多面レビュー結果。**総指摘 65 件**を統合・重複排除したもの。
>
> 生成日: 2026-07-04 / レビュアー: Fable（claude-fable-5）

## 総括

5観点のレビューは同じ根本問題に収束した。最大の問題は **「録音中に OS 標準エンジンでリアルタイム文字起こし」という中核仕様が両 OS で技術的に成立しない**こと（Android=SpeechRecognizer のマイク排他、iOS=約1分制限＋スロットリング＋プラグイン併用不可）で、デフォルトを「録音後の非同期 STT」に入れ替える仕様変更が必要。

次いで「録音すれば必ず Drive に上がる」というコンセプトの根幹を脅かす欠落として、
1. 割り込み・クラッシュ・電池切れ時のデータ保全
2. 逼迫時自動削除が未アップロード録音を消しうる設計
3. Drive full スコープ（restricted scope, CASA 審査必須）とフォルダピッカー要件の衝突
4. iOS で Ogg Opus コンテナが標準 API で生成不可

が挙がった。幸い **プラガブル STT 設計・録音優先の方針・キュー機構という骨格は正しい**ため、仕様の大枠は保ったまま、下記の決定と文言修正で計画を成立させられる。

---

## 🚨 Blockers（実装着手前に必ず決定する）

### B1. リアルタイム STT の撤回／縮退の決定
デフォルトを「OS標準リアルタイム」から **「録音完了後の非同期 STT（ファイルベース）」** に変更する。Android は SpeechRecognizer のマイク排他で録音と同時実行が根本的に不可能、iOS も約1分制限＋スロットリング＋既製プラグイン併用不可で長時間会議に耐えない。リアルタイム表示を残すなら自前ネイティブ音声パイプライン（単一入力タップからエンコーダと STT へ分配）が必要になり、その場合は最初期からネイティブ層の仕事として計画し直す。**どちらにするかを実装着手前に確定**（残す場合は両OS同時実行 PoC を最優先）。

### B2. 録音データ保全の仕様化
録音はストリーミング書き込み＋定期フラッシュ（数秒ごと）とし、割り込み（着信/Siri/音声フォーカス喪失）検知→自動再開試行→失敗時は即ローカル通知、異常終了（クラッシュ/kill/電池切れ/容量枯渇）後の起動時に未クローズファイルを検出・修復してアップロードキューへ投入するリカバリフローを**必須要件**として追加。これがないと2時間会議の途中クラッシュで全損する。

### B3. Drive スコープと配布形態の決定
`drive` フルアクセスは restricted scope で OAuth 審査＋年次 CASA Tier 2 評価（有償・数週間〜）が必要。審査不要の `drive.file` では「既存の任意フォルダをピッカーで指定」が実現できない。**個人/テストユーザー運用で現仕様のまま**か、**ストア公開前提で `drive.file` ＋ アプリ自作ルートフォルダ（`/VoiceRecorder/`）配下のみ管理**へ仕様変更するかを決めないと、認証・フォルダ選択・アップロードの設計が定まらない（推奨は後者）。

### B4. iOS の録音フォーマット決定
iOS 標準 API は Opus コーデックを CAF コンテナでしか書き出せず、仕様の `.opus`/`.ogg`（Ogg Opus）は生成不可。ffmpeg-kit も開発終了済み。**iOS は AAC `.m4a`（モノラル32kbps）へ変更し OS 間フォーマット非統一を許容**するか（推奨・後段 Workflow は M4A も受けられる）、libopus/libogg を自前 FFI 統合するかを決める。あわせて Android の Ogg/Opus は API 29+ 限定のため **minSdk 29** を明記。

### B5. ストレージ逼迫時削除と削除操作の安全化
自動削除の対象を **「アップロード完了済みファイルのみ、古い順」** に限定し閾値を数値定義（未アップロード録音の自動削除は恒久データ喪失）。ユーザーの削除操作のスコープ（既定=ローカルのみ、Drive側削除は明示チェック＋警告、未アップ分は「まだ Drive に上がっていません」の強警告＋キュー除去）を定義。

---

## 主要指摘（重要度順）

| # | 指摘 | 重大度 | 観点 |
|---|---|---|---|
| 1 | 録音+OS標準リアルタイムSTTは両OSで成立しない（中核仕様が技術的に不可能） | **blocker** | 技術/要件/STT（5観点中4が独立指摘） |
| 2 | 録音中の割り込み・プロセスkill・電源断でデータが黙って失われる | **blocker** | 技術/要件/UX |
| 3 | Drive fullスコープはrestricted scopeでフォルダピッカー要件と直接衝突 | **blocker** | 技術/法務/UX |
| 4 | iOSで.opus/.ogg生成不可・AndroidはAPI 29+限定 | high | 技術 |
| 5 | アップロードの冪等性・fileId管理・キュー状態機械が未定義 | high | 要件/UX |
| 6 | バックグラウンドアップロードのOS制約と「自動・即時」の乖離 | high | 技術 |
| 7 | 「同意リマインド等の追加配慮は不要」は法務リスクの未評価 | high | 法務 |
| 8 | OAuthトークン・録音データの端末内保護が未規定 | high | セキュリティ |
| 9 | STT抽象化: 単一インターフェースは破綻する（出力統一・入力分離+ジョブ永続化が必要） | high | STT設計 |
| 10 | 初回オンボーディングと未サインイン時の録音可否が未定義 | high | UX |
| 11 | 録音中の画面遷移・多重録音排他・状態バッジ定義が未定義 | medium | UX |
| 12 | iOS「常駐通知に経過時間」は存在しない/Android 14+のFGS制約 | medium | 技術 |
| 13 | 命名・フォルダ規約の曖昧さ（TZ/基準時刻/月次フォルダ/改名との衝突） | medium | 要件/UX |
| 14 | 共有フォルダ指定時の意図しない開示 | medium | 法務 |
| 15 | 再生UI・文字起こし閲覧・一時停止の欠落 | medium | UX |

### 詳細と推奨対処

**1. 録音+OS標準リアルタイムSTTは両OSで成立しない**
Android: SpeechRecognizer は認識サービス側プロセスがマイクを占有し、Android 10+ の同時キャプチャポリシーにより自アプリの録音と併用不可（音声バッファ注入 API も存在しない）。iOS: サーバ認識は約1分/リクエスト＋日次スロットリングで数時間の連続認識に不向き、record 系と speech_to_text 系プラグインは AVAudioSession を取り合い併用不可。リアルタイムのみだと失敗区間は永久に失われ「失敗バッジに打つ手なし」という UX 破綻も併発。
→ **推奨**: デフォルトエンジンを「録音後の非同期 STT（クラウド Whisper API 等またはオンデバイス Whisper.cpp）」に変更。録音は record プラグイン単独で完結しマイク競合問題ごと消える。リアルタイム表示は「オンデバイス認識対応言語のみ・ベストエフォート・取りこぼし許容」の任意機能に格下げするか MVP から外す。

**2. 録音中の割り込み・kill・電源断でデータ喪失**
仕様は「停止で Opus ローカル保存」のみで、AVAudioSession interruption（着信/Siri）、audio focus 喪失、OEM バッテリ最適化による FGS kill、クラッシュ、容量枯渇時の挙動がすべて未定義。M4A 採用時は moov 未書込クラッシュで全損。
→ **推奨**: 逐次追記＋定期フラッシュ、割り込み時「その時点まで確定保存→自動再開→別セグメント継続（失敗時は即通知）」、起動時クラッシュリカバリ、録音開始時の空き容量チェック＋枯渇時の安全クローズ、Android 向けバッテリ最適化除外誘導 UI＋partial wakelock。

**3. Drive fullスコープの衝突**
フルアクセスは CASA Tier 2 評価（有償・年次）必須、未審査だと100ユーザー上限＋警告画面。drive.file なら審査不要だが任意既存フォルダ指定が不可。トークン漏洩時の被害範囲も Drive 全体に及ぶ過剰権限。
→ **推奨**: `drive.file` ＋ アプリ自作ルートフォルダ（`/VoiceRecorder/` 配下のみ管理）へ変更。後段 Workflow はそのフォルダを ID 監視すればコンセプトは損なわれない。個人利用なら「テストユーザー運用・restricted scope 審査未実施」を明記。

**4. iOS で .opus/.ogg 生成不可**
iOS 標準 API の Opus 書き出しは CAF コンテナのみ。ffmpeg-kit は2025年に開発終了。Android の OutputFormat.OGG+Opus は API 29 以上。
→ **推奨**: iOS=AAC `.m4a`（モノラル32kbps）でフォーマット非統一を許容（最低コスト、将来 libopus 統合で .opus 統一へ移行）。minSdkVersion 29 を明記。

**5. アップロードの冪等性・fileId 管理・状態機械が未定義**
分単位ファイル名の同名衝突、リトライでの二重アップロード、改名/削除/txt 紐付けの名前ベース運用の脆弱性、一時エラー（ネットワーク/5xx/429）と恒久エラー（トークン失効/フォルダ削除/容量超過）の未区別、恒久エラーの無限リトライで「上がったつもり」滞留。
→ **推奨**: 録音エンティティスキーマ（UUID, startedAt(TZ付), duration, localPath, title, driveFileId, txtDriveFileId, uploadState, transcriptState）を仕様化。ファイル名に秒を含め、UUID を appProperties に付与し冪等化。改名・削除・txt 後追いは常に fileId 基準で録音単位に直列化。状態機械（待機/アップ中/完了/要対応）を定義し、恒久エラーはバッジ「要対応」＋原因別解決導線＋手動再試行。

**6. バックグラウンドアップロードの OS 制約**
iOS は URLSession background configuration 必須で Drive resumable の多段プロトコルとの統合が重い。Android は Doze/WorkManager 前提の遅延実行、dataSync FGS は Android 15 で6時間/日上限。
→ **推奨**: 「FG中=アプリ内 HTTP で即時 resumable / それ以外=iOS: background URLSession（multipart一発）＋FG復帰時 resumable 再開、Android: WorkManager による OS 裁量ベストエフォート」の2段構え。24時間以上滞留時のローカル通知を追加。工数を厚めに。

**7. 録音同意・法務リスク**
米国全当事者同意州では刑事罰対象になり得る。文字起こし ON で会議音声が Apple/Google サーバへ送信される事実の開示も欠落（ストアのデータ開示フォーム申告必須）。
→ **推奨**: 「追加配慮不要」を削除し「初回起動時の同意確認ダイアログ＋利用規約/プライバシーポリシー明記」に置換。STT 設定に「音声が外部サーバに送信される場合があります」の明示オプトイン。両ストアの App Privacy/Data Safety 申告とプライバシーポリシー URL 作成を MVP スコープに追加。

**8. トークン・データの端末内保護**
トークン保存先未定義（shared_preferences だと平文）、録音/txt/メタ DB のバックアップ経由複製、ログへの機微情報出力の考慮なし。
→ **推奨**: flutter_secure_storage（Keychain/Keystore）＋ `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`、allowBackup 無効化/バックアップ除外、保存先はアプリ内部ストレージ限定、サインアウト時のトークン revoke、ログポリシー（トークン/タイトル/本文を出さない）。

**9. STT 抽象化は単一インターフェースだと破綻**
同期型と非同期型は起動タイミング・入力・寿命が根本的に異なり、単一 `transcribe()` に押し込むとファットインターフェース化する。非同期エンジンの JobHandle 永続化がないと再起動後にジョブを見失う（課金だけ発生）。バックグラウンド isolate から Riverpod のメモリ状態は更新できない。
→ **推奨**: 出力は `TranscriptionEvent` ストリーム（Partial/Progress/Completed/Failed）で統一、入力は `StreamingTranscriptionEngine`/`BatchTranscriptionEngine` の2インターフェースに分離。capability（audioInputMode: feedsPcm/ownsMic/file、acceptedFormats、maxFileSize、languageMode）＋動的 `checkAvailability()` の2層で公開。`TranscriptionJob` テーブル（jobHandle をシリアライズ保存、起動時再購読）をアップロードキューと同じ永続層に持たせる。状態の single source of truth は DB、ドメイン層は Riverpod 非依存、UI は DB 変更ストリームを StreamProvider で購読。`transcribe(recordingId)` による録音単位の再文字起こしユースケースの席を最初から用意。

**10. オンボーディング・未サインイン時の録音**
主ユースケースは「会議が始まるからすぐ録りたい」なのに、サインイン強制だと初回の会議を録り逃す。権限拒否時のフローも未定義。
→ **推奨**: 録音はサインインなしでも常に可能とし、アップロードのみ保留（バッジ「Drive未設定」→タップで設定誘導）。初回起動はマイク権限のみ必須。権限ごとに拒否→説明→OS設定誘導を定義。iOS の音声認識権限（NSSpeechRecognitionUsageDescription）を権限計画に追加。

**11–15**（詳細は末尾の specChanges 参照）: 全画面共通の録音中バー＋多重録音排他＋バッジ状態機械の定義／iOS は Live Activity（16.1+）が別枠工数・Android 14+ の FGS 宣言／録音開始時刻・端末ローカル TZ・月次フォルダへ命名規約統一／フォルダ共有状態の警告・既定は非共有フォルダ／再生 UI（シークバー＋±15秒＋速度）・txt 閲覧・一時停止・最大録音時間の明示。

---

## 計画へ反映すべき仕様変更（specChanges 全18項目）

1. **【文字起こし】** 「録音中に OS 標準エンジンでリアルタイム逐次変換」を削除し、「デフォルト=録音完了後にファイルベースで非同期文字起こし（MVP はクラウド STT: Whisper API 等を第一候補）。リアルタイム画面表示は将来オプション（オンデバイス対応言語のみ・ベストエフォート・取りこぼし許容）」に差し替え
2. **【文字起こし】** エンジン抽象を「1インターフェース」から「出力=TranscriptionEvent ストリームで統一、入力=Streaming/Batch の2インターフェース分離、capability＋動的 checkAvailability() の2層公開」に書き換え。TranscriptionJob テーブル（recordingId, engineId, シリアライズ可能な jobHandle, state, attempt）をローカル DB に持ち、起動時に未完ジョブを再購読。`transcribe(recordingId)` による再文字起こしの席を最初から用意
3. **【文字起こし】** 言語設定は「選択中エンジンへの動的照会で対応言語のみ表示。autoDetect エンジンでは言語選択非表示。グローバル設定のみ・録音開始時点の値を採用・非対応言語は自動スキップ＋バッジ通知」。部分成功時は得られた分の txt を保存・アップし「一部のみ」状態を表示。txt も同キューに低優先度で投入。再実行時の Drive txt は同名上書き
4. **【録音】** フォーマットを「Android=Ogg Opus（minSdkVersion 29）、iOS=AAC .m4a モノラル32kbps（OS標準 API で Ogg Opus 生成不可。将来 libopus 統合で .opus 統一）」に変更
5. **【録音】** 保全要件を新設: ストリーミング書き込み＋定期フラッシュ、割り込み時「確定保存→自動再開→別セグメント(_part2)継続、再開不可なら即通知」、異常終了後の起動時に未クローズファイル検出・修復し「中断された録音を復元しました」として一覧＋キューに投入、開始時に空き容量チェック＋録音中の閾値割れ警告＋枯渇時は安全クローズ
6. **【録音】** Android 要件追記: foregroundServiceType=microphone＋FOREGROUND_SERVICE_MICROPHONE 宣言（録音開始は FG 起点のみ）、バッテリ最適化除外誘導 UI、録音中の partial wakelock。通知仕様は「Android=FGS 通知に経過時間 / iOS=OS標準マイクインジケータのみ（Live Activity は別枠工数）」に分割。入力は「常に内蔵マイク固定」。一時停止・最大録音時間は MVP 対応/非対応を明示的に決定
7. **【アップロード】** スコープを「drive.file＋アプリ自動作成ルートフォルダ（/VoiceRecorder/）配下のみ管理。任意既存フォルダ指定は不可」に変更（ストア公開前提の場合）。個人利用なら「テストユーザー運用・restricted scope 審査未実施」を明記
8. **【アップロード】** 冪等性と紐付け: ファイル名は秒まで含む（2026-07-04_14-30-05）、ローカル UUID を appProperties に付与しリトライ前に既存検索で二重作成防止、resumable upload 採用。成功時に Drive fileId をローカルメタに保存し、以後の改名・削除・txt 後追いは常に fileId 基準・録音単位で直列化
9. **【アップロード】** キュー状態機械: pending→uploading→done / retryable-failed（ネットワーク・5xx・429: 指数バックオフで自動）→pending / permanent-failed（401・フォルダ削除/trashed・容量超過: 即バッジ「要対応」＋原因別解決導線＋手動再試行）。認証エラー時はキュー保持のまま一時停止＋通知＋バナーで再サインイン誘導、成功で自動再開。サインアウト時は未アップ N 件を警告しキュー保持
10. **【アップロード】** BG 挙動の保証レベル明記（前述の2段構え）＋24時間以上滞留で通知。逼迫時自動削除は「アップロード完了済みのみ・古い順・閾値=空き容量500MB未満（仮）」と数値定義
11. **【一覧/操作】** 削除仕様: 既定=ローカルのみ削除、Drive 側削除は明示チェック＋赤字警告。未アップは強警告＋キュー除去。自動削除済みの再生は「Drive から再取得（要オンライン）」。録音中は全画面共通の録音中バー＋新規録音無効化＋当該項目の削除/改名不可。バッジ状態一覧（アップ4状態/文字起こし5状態）を定義
12. **【一覧/操作】** 改名: ファイル名=日時プレフィックス＋タイトル（例 2026-07-04_14-30-05_経営会議.opus）、改名はタイトル部のみ・不正文字サニタイズ・.opus と .txt はペア改名・fileId ベースで Drive 反映。フォルダ規約は「録音開始時点の端末ローカル時刻基準・月次サブフォルダ（年/年-月）」に文言修正
13. **【法務/プライバシ】** 「追加配慮不要」を削除し「初回起動時に録音同意ダイアログ（一度きり）＋利用規約/プライバシーポリシー明記。適法性はユーザー帰属の免責」に置換。文字起こし初回 ON 時に「音声が外部サーバに送信される場合があります」の明示オプトイン。エンジンごとの送信先開示をインターフェース要件に含める
14. **【セキュリティ】** OAuth トークンは flutter_secure_storage（iOS Keychain: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly / Android Keystore）、サインアウト時 revoke。録音・txt・メタ DB はアプリ内部ストレージ限定＋バックアップ除外（isExcludedFromBackup / dataExtractionRules）。iOS ファイル保護は NSFileProtectionCompleteUntilFirstUserAuthentication。ログにトークン・タイトル・本文を出さない
15. **【ストア対応】** ステップ1に追記: iOS=NSMicrophoneUsageDescription/NSSpeechRecognitionUsageDescription 文言確定、audio BG モードは録音中のみセッション保持、App Privacy 申告。Android=Data Safety 申告。プライバシーポリシー URL 作成を MVP スコープに追加
16. **【メタデータ】** 録音エンティティスキーマ: {id(UUID), startedAt(ISO8601+TZ), duration, localPath, title, driveFileId, txtDriveFileId, uploadState, transcriptState, sizeBytes}。状態の single source of truth は DB、ドメイン層は Riverpod 非依存、UI は DB 変更ストリームを StreamProvider で購読、BG isolate はドメイン層を直接使用
17. **【オンボーディング】** 録音はサインインなしでも常に可能、アップロードのみ保留（バッジ「Drive未設定」）。初回起動はマイク権限のみ必須。権限ごとの拒否→説明→OS設定誘導を定義。音声認識のみ拒否時は「録音可・文字起こし自動OFF」に縮退。一覧上部にオフラインバナー
18. **【後段Workflow契約】** 「.txt の到着は保証しない（Workflow は .opus トリガー、.txt は任意添付）。ペアリングはファイル名でなく appProperties の不変 ID」。共有フォルダ・再インストール時の Drive からの一覧復元・多言語混在会議は MVP 対象外と明記
19. **【実装ステップ】** ステップ7を「文字起こし抽象（Streaming/Batch 分離＋ジョブ永続化）＋非同期クラウド STT 実装＋txt 別アップ」に変更。ステップ3に保全要件、ステップ5に drive.file＋アプリ管理フォルダ、ステップ6に resumable/冪等/状態機械を織り込み工数を再見積もり。再生 UI と文字起こし閲覧画面をステップ4に追加
