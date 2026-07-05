# DESIGN.md — 自動クラウドアップロード型ボイスレコーダ 詳細設計書

> 実装者向けの正（canonical）となる設計書。承認済み実装計画（`~/.claude/plans/claude-md-prd-md-sleepy-deer.md`）と Fable 多面レビュー（`REVIEW.md`, 65指摘）を反映済み。本書の「確定仕様サマリ」がインタビュー時の当初仕様より優先する。

---

## 1. 概要・コンセプト・スコープ

**コンセプト**: 「どんな会議でも、録音すれば自動でクラウド（Google Drive）へ上がるボイスレコーダ」。録音停止と同時に音声ファイルが Drive のアプリ管理フォルダへ自動アップロードされ、Drive をトリガーにした後段 Workflow（要約・議事録生成・タスク抽出）に繋げられる。

**MVP スコープ**:
- iOS + Android（Flutter 単一コードベース）
- 端末マイクによる録音（バックグラウンド／画面ロック中も継続）
- 録音データ保全（フラッシュ・割り込み対応・起動時リカバリ）
- Google Drive 自動アップロード（drive.file スコープ、キュー・リトライ・冪等）
- 録音後の非同期文字起こし（クラウド STT、`.txt` を別ファイルとしてアップ）
- 録音一覧（状態バッジ）・アプリ内再生・タイトル変更・削除・設定画面

**スコープ外（MVP）**: リアルタイム文字起こし表示、任意既存 Drive フォルダの指定、共有ドライブ、再インストール時の Drive からの一覧復元、多言語混在会議、ストア公開向けプライバシ対応（同意ダイアログ・App Privacy / Data Safety 申告）、録音の一時停止。

---

## 2. 確定仕様サマリ（最終決定を反映した正）

レビュー後のユーザー最終決定。**当初インタビュー仕様を上書きする**。

| 項目 | 確定仕様 | 上書きされた当初仕様 |
|---|---|---|
| 文字起こし | **録音後の非同期 STT が既定**（クラウド STT: Whisper API 等のバッチエンジン）。録音は `record` 単独で完結。リアルタイム表示は将来オプションへ格下げ | 録音中に OS 標準エンジンでリアルタイム逐次変換（B1: 両OSで技術的に不成立） |
| Drive スコープ | **`drive.file` ＋ アプリ自作ルートフォルダ `/VoiceRecorder/` 配下のみ管理**。任意既存フォルダ指定は不可。日付サブフォルダ（年/年-月）はルート配下に生成 | フルアクセス `drive` スコープ＋任意フォルダピッカー（B3: CASA 審査必須） |
| 音声フォーマット | **iOS: AAC `.m4a`（モノラル 32kbps）／ Android: Ogg Opus（`.opus`）。非統一を許容**。`minSdkVersion 29`。将来 libopus FFI で `.opus` 統一 | 両OS共通 `.opus`（B4: iOS 標準 API で Ogg Opus 生成不可、ffmpeg-kit EOL） |
| 同意・プライバシ | **最小限（個人利用割り切り）**。同意ダイアログ・ポリシー URL 等はストア公開時に別途対応 | — |

さらに以下の Blocker 対処を設計に織り込む（本書の該当章で詳細化）:

- **録音データ保全**（B2）→ §6
- **ストレージ削除の安全化**（B5）→ §7.7
- **アップロード冪等性・状態機械**（指摘#5,6）→ §7
- **STT 抽象化の是正**（指摘#9）→ §8
- **セキュリティ**（指摘#8）→ §9
- **オンボーディング**（指摘#10）→ §10.5

---

## 3. 技術スタック / パッケージ選定

| 領域 | パッケージ | 用途・補足 |
|---|---|---|
| 録音 | `record` | iOS=AAC(.m4a), Android=Ogg Opus。録音は本パッケージ単独で完結（STT とのマイク競合なし） |
| オーディオセッション | `audio_session` | iOS AVAudioSession（playAndRecord）設定、割り込み（interruption）イベント購読 |
| BG 継続 (Android) | `flutter_foreground_task` | microphone 型 FGS。常駐通知に経過時間表示。partial wakelock |
| BG 継続 (iOS) | `Info.plist UIBackgroundModes=audio` | audio_session と併用。録音中のみセッション保持 |
| 認証 | `google_sign_in` (v7) + `extension_google_sign_in_as_googleapis_auth` | v7 の Drive 疎通不安定報告（flutter#173407）あり → Phase 0 で実機検証。詰まれば v6 へフォールバック |
| Drive API | `googleapis` | Drive REST v3。resumable upload、appProperties、fileId ベース操作 |
| BG アップロード | `workmanager` + `connectivity_plus` | Android: WorkManager によるベストエフォート実行。ネット復帰検知 |
| 状態管理 | `flutter_riverpod` + `riverpod_generator` | UI 層のみ。ドメイン層は Riverpod 非依存 |
| 永続化 | `drift` | 状態の single source of truth。リアクティブクエリで一覧バッジ駆動 |
| 機微情報保存 | `flutter_secure_storage` | OAuth トークン（Keychain / Keystore） |
| 再生 | `just_audio`（または `audioplayers`） | シークバー・±15秒・再生速度 |
| 文字起こし（将来） | `speech_to_text` | 将来のリアルタイムオプション用。**MVP では使用しない** |
| クラウド STT | HTTP 直叩き（`http` / `dio`） | Whisper API 等。専用パッケージは追加しない |

**ffmpeg_kit_flutter は使用しない**（開発終了済み・当初の Opus 変換計画は撤回）。

---

## 4. アーキテクチャ

### 4.1 ディレクトリ構成（feature-first + core）

```
lib/
  app/                     # ルーティング, テーマ, ProviderScope, 起動時リカバリ呼び出し
  core/
    audio_session/         # audio_session 設定, iOS background audio, 割り込みハンドラ
    background/            # flutter_foreground_task, workmanager callbackDispatcher
    database/              # drift スキーマ定義, DAO, マイグレーション
    drive/                 # Drive API クライアント（googleapis ラッパ, resumable, appProperties）
    security/              # flutter_secure_storage ラッパ, ログポリシー実装
  features/
    recording/             # 録音: data(record) / domain(RecordingService, 保全) / presentation
    recordings_list/       # 一覧＋バッジ（drift リアクティブクエリ）, 再生, 改名, 削除
    upload/                # UploadQueue, UploadWorker, フォルダ管理(/VoiceRecorder/)
    transcription/         # 抽象IF, engines/(cloud_stt ほか), TranscriptionService, Registry
    auth/                  # google_sign_in, トークン管理, revoke
    settings/              # 設定画面
    onboarding/            # 権限フロー
```

### 4.2 設計原則

1. **状態の single source of truth は DB（drift）**。アップロード状態・文字起こし状態はすべて DB のジョブテーブルに記録し、UI は drift のリアクティブクエリ（`watch`）を Riverpod `StreamProvider` で購読する。メモリ上の状態を正としない。
2. **ドメイン層は Riverpod 非依存**。`RecordingService` / `UploadQueue` / `TranscriptionService` は plain Dart クラスとし、DB と直接やり取りする。Riverpod は UI への配線（provider）にのみ使う。
3. **バックグラウンド isolate**（workmanager の callbackDispatcher、flutter_foreground_task のタスクハンドラ）からは Riverpod のメモリ状態を更新できない。BG isolate は**ドメイン層＋DB を直接使用**し、結果は DB 書き込み経由で UI に伝播する（drift は複数 isolate からの同一 DB アクセスに対応した接続方法を使う）。
4. **録音優先／文字起こしベストエフォート**。音声ファイルのアップロードは文字起こしと独立して必ず走る。文字起こしの失敗が録音・アップロードに影響してはならない。

---

## 5. データベーススキーマ（drift）

enum は Dart 側で定義し、DB には文字列（`TextColumn`）で格納する（マイグレーション耐性のため整数インデックス格納は避ける）。

### 5.1 `recordings` テーブル

| 列 | 型 | 制約 | 説明 |
|---|---|---|---|
| `id` | TEXT | PK | UUID v4。生成はローカル録音開始時。Drive appProperties にも同値を付与 |
| `startedAt` | TEXT | NOT NULL | 録音開始時刻。**ISO8601＋タイムゾーンオフセット**（例 `2026-07-04T14:30:05+09:00`）。端末ローカル時刻基準 |
| `durationMs` | INTEGER | NOT NULL DEFAULT 0 | 録音時間（ミリ秒）。リカバリ復元時は推定値 |
| `localPath` | TEXT | NULLABLE | 端末内ファイルの絶対パス。逼迫時自動削除後は NULL |
| `title` | TEXT | NOT NULL DEFAULT '' | ユーザー指定タイトル（ファイル名のタイトル部）。空なら日時のみの名前 |
| `driveFileId` | TEXT | NULLABLE | 音声ファイルの Drive fileId。アップ成功時に保存 |
| `txtDriveFileId` | TEXT | NULLABLE | `.txt` の Drive fileId |
| `uploadState` | TEXT | NOT NULL DEFAULT 'pending' | `pending` / `uploading` / `done` / `actionRequired`（§7.5 の状態機械の射影） |
| `transcriptState` | TEXT | NOT NULL DEFAULT 'off' | `off` / `processing` / `done` / `partial` / `failed`（§8.6） |
| `sizeBytes` | INTEGER | NOT NULL DEFAULT 0 | ファイルサイズ |
| `codec` | TEXT | NOT NULL | `aacM4a`（iOS）/ `oggOpus`（Android）。拡張子・MIME 決定に使用 |
| `transcriptLocalPath` | TEXT | NULLABLE | 生成済み `.txt` のローカルパス（閲覧用） |
| `createdAt` / `updatedAt` | TEXT | NOT NULL | ISO8601。監査・ソート用 |

`uploadState` / `transcriptState` は一覧バッジ表示を単純化するための非正規化列。真の状態遷移はジョブテーブルが持ち、ジョブ更新時に同一トランザクションで recordings 側も更新する。

### 5.2 `upload_jobs` テーブル

| 列 | 型 | 制約 | 説明 |
|---|---|---|---|
| `id` | TEXT | PK | UUID |
| `recordingId` | TEXT | NOT NULL, FK→recordings.id | |
| `kind` | TEXT | NOT NULL | `audio` / `transcript`。transcript は低優先度 |
| `state` | TEXT | NOT NULL DEFAULT 'pending' | `pending` / `uploading` / `done` / `retryableFailed` / `permanentFailed` |
| `retryCount` | INTEGER | NOT NULL DEFAULT 0 | |
| `nextRetryAt` | TEXT | NULLABLE | 指数バックオフの次回試行時刻（ISO8601） |
| `resumableUri` | TEXT | NULLABLE | Drive resumable session URI（再開用） |
| `driveFolderId` | TEXT | NULLABLE | アップ先（年-月フォルダ）の fileId。解決済みならキャッシュ |
| `lastError` | TEXT | NULLABLE | 直近エラー（機微情報を含めない） |
| `createdAt` / `updatedAt` | TEXT | NOT NULL | |

UNIQUE 制約: `(recordingId, kind)` — 同一録音・同一種別のジョブは常に1つ（冪等性の第一防壁）。

### 5.3 `transcription_jobs` テーブル

| 列 | 型 | 制約 | 説明 |
|---|---|---|---|
| `id` | TEXT | PK | UUID |
| `recordingId` | TEXT | NOT NULL, FK→recordings.id | |
| `engineId` | TEXT | NOT NULL | `cloud_stt` 等。Registry のキー |
| `jobHandle` | TEXT | NULLABLE | エンジン固有のジョブ識別子を**シリアライズ保存**（JSON文字列）。再起動後の再購読に必須 |
| `state` | TEXT | NOT NULL DEFAULT 'queued' | `queued` / `submitted` / `running` / `done` / `partial` / `failed` |
| `attempt` | INTEGER | NOT NULL DEFAULT 0 | |
| `localeId` | TEXT | NULLABLE | ジョブ投入時点の言語設定（`ja-JP` 等）。autoDetect エンジンは NULL |
| `lastError` | TEXT | NULLABLE | |
| `createdAt` / `updatedAt` | TEXT | NOT NULL | |

**起動時再購読**: アプリ起動時に `state IN ('submitted','running')` のジョブを列挙し、各エンジンの `watch(jobHandle)` を再購読する。これがないとクラウド STT に課金だけ発生して結果を見失う。

### 5.4 `settings`（key-value）

`driveRootFolderId`（自作 `/VoiceRecorder/` の fileId）、`transcriptionEnabled`、`transcriptionEngineId`、`transcriptionLocaleId` 等。※ OAuth トークンはここに置かず flutter_secure_storage（§9）。

---

## 6. 録音サブシステム

### 6.1 基本フロー

1. 録音開始は**必ずフォアグラウンド（画面表示中）から**行う（Android 11+ は BG からの microphone FGS 起動不可）。
2. 開始時に `recordings` 行を INSERT（`id`=UUID、`startedAt`=端末ローカル時刻）してから録音開始。ファイルパスは開始時点で確定（§11 の命名規約）。
3. Android: `flutter_foreground_task` で microphone 型 FGS を起動し、`record` で Ogg Opus（モノラル 32kbps 目安）録音。iOS: `audio_session` で playAndRecord 設定＋`UIBackgroundModes=audio` により BG 継続、AAC `.m4a`（モノラル 32kbps）で録音。
4. 停止でファイルをクローズし、`durationMs`/`sizeBytes` を確定、`upload_jobs(kind=audio, state=pending)` を投入。文字起こし ON なら `transcription_jobs(state=queued)` も投入。

### 6.2 データ保全（B2 — 必須要件）

- **ストリーミング書き込み＋定期フラッシュ**: 録音はファイルへ逐次追記。数秒ごと（目安 5 秒）にフラッシュし、クラッシュ時の損失を直近数秒に限定する。`record` の実装がプラットフォーム側で逐次書き込みすることを Phase 0 で確認し、不足があれば stream API（PCM ストリーム受領→自前書き込み）へ切り替える。
- **割り込み処理**（着信 / Siri / 音声フォーカス喪失）: `audio_session` の interruption イベントを購読。割り込み発生時は**その時点までを確定保存**（正常クローズ）→割り込み終了後に**自動再開を試行**→再開分は**別セグメント**として保存（ファイル名サフィックス `_part2`, `_part3`…、`recordings` 行は別レコード・タイトル継承）。再開不可の場合は即ローカル通知でユーザーに知らせる。
- **起動時リカバリ**: アプリ起動時に「`recordings` に行があるがクローズ処理が完了していないファイル」（録音中フラグ、または durationMs=0 かつファイル実在）を検出。M4A は moov atom 未書込の可能性があるため可能な範囲で修復（修復不能なら生データのまま保持し failed 扱いにしない）。修復後は「中断された録音を復元しました」として一覧に表示し、アップロードキューへ投入する。
- **空き容量チェック**: 録音開始時に空き容量を確認し、不足時（目安 200MB 未満）は開始を警告付きにする。録音中も定期チェックし、閾値割れで警告、枯渇寸前で**安全クローズ**（それまでの録音を確定保存）する。
- **Android 電源対策**: バッテリ最適化除外の誘導 UI（初回録音時に案内）＋録音中の partial wakelock（flutter_foreground_task のオプション）。

### 6.3 通知・インジケータ

- **Android**: FGS 常駐通知に録音経過時間を表示（`flutter_foreground_task` の通知更新）。foregroundServiceType=`microphone`、`FOREGROUND_SERVICE_MICROPHONE` 権限を Manifest に宣言。
- **iOS**: **OS 標準のマイク使用インジケータのみ**（常駐通知に経過時間を出す仕組みは iOS に存在しない）。Live Activity（iOS 16.1+）は別枠工数として将来課題。

### 6.4 権限・プラットフォーム設定

- Android: `RECORD_AUDIO`、`FOREGROUND_SERVICE`、`FOREGROUND_SERVICE_MICROPHONE`、`POST_NOTIFICATIONS`（13+）。**`minSdkVersion 29`**（Ogg Opus 録音が API 29+ のため）。
- iOS: `NSMicrophoneUsageDescription`（文言確定要）。`UIBackgroundModes=audio`。audio BG モードは**録音中のみ**セッション保持（審査対策・電池対策）。
- 入力ソースは**常に内蔵マイク固定**（Bluetooth マイク切替は MVP 非対応）。
- **一時停止は MVP 非対応**（明示的決定）。**最大録音時間は上限を設けない**が、空き容量チェックで実質制限される。

### 6.5 多重録音排他

同時録音は常に 1 本。録音中は全画面共通の「録音中バー」を表示し（§10.2）、新規録音開始 UI を無効化。録音中の当該項目は削除・改名不可。

---

## 7. アップロードサブシステム

### 7.1 スコープとフォルダ管理

- OAuth スコープは **`drive.file` のみ**（アプリが作成したファイル/フォルダのみアクセス可。CASA 審査不要）。
- 初回サインイン後、アプリが Drive ルート直下に **`/VoiceRecorder/`** フォルダを作成し、fileId を `settings.driveRootFolderId` に保存。**任意の既存フォルダ指定は不可**。
- 日付サブフォルダは `/VoiceRecorder/<年>/<年-月>/`（例 `/VoiceRecorder/2026/2026-07/`）をアップロード時に必要に応じ作成（get-or-create、フォルダも appProperties にパスキーを付与して検索可能にする）。
- 基準は**録音開始時点の端末ローカル時刻**（アップロード時刻ではない）。
- ルートフォルダがユーザーにより削除/trashed されていた場合は permanent-failed（§7.5）とし、再作成の導線を出す。

### 7.2 アップロード方式

- **resumable upload**（`googleapis` Drive v3）を使用。セッション URI は `upload_jobs.resumableUri` に保存し、中断後に再開する。
- `.txt` は同じキューに `kind=transcript`・**低優先度**で投入（audio が常に先）。

### 7.3 冪等性（二重アップロード防止）

- ファイル名は**秒まで**含む（`2026-07-04_14-30-05_タイトル.m4a`）。
- ローカル UUID（`recordings.id`）を Drive の **`appProperties`**（例 `{"vrId": "<uuid>", "vrKind": "audio"}`）に付与。
- リトライ前に必ず `appProperties` で既存検索（`q: appProperties has { key='vrId' and value='<uuid>' }`）し、既に存在すれば fileId を回収して done 遷移（新規作成しない）。
- 成功時に `driveFileId` / `txtDriveFileId` を保存。**以後の改名・削除・txt 後追い紐付けは常に fileId 基準**とし、録音単位（recordingId 単位）で操作を直列化する（同一録音への並行 Drive 操作を禁止）。

### 7.4 後段 Workflow 契約

- Workflow は `/VoiceRecorder/` を**フォルダ ID で監視**する。
- **`.txt` の到着は保証しない**。Workflow は音声ファイル（`.m4a`/`.opus`）をトリガーとし、`.txt` は任意添付。
- 音声と txt のペアリングは**ファイル名でなく appProperties の不変 ID（`vrId`）**で行う。
- 再文字起こし時の Drive txt は同名上書き（fileId 維持の update）。

### 7.5 キュー状態機械

```
pending ──開始──▶ uploading ──成功──▶ done
   ▲                  │
   │   一時エラー      │ (ネットワーク断 / 5xx / 429)
   └── retryableFailed ◀┘   → 指数バックオフ(nextRetryAt)で自動的に pending へ戻す
                      │
                      │ 恒久エラー (401 トークン失効 / フォルダ削除・trashed / Drive容量超過)
                      ▼
              permanentFailed ──手動再試行 / 原因解消──▶ pending
```

- `recordings.uploadState` への射影: pending/retryableFailed→`pending`（バッジ「未アップ」）、uploading→`uploading`、done→`done`、permanentFailed→`actionRequired`（バッジ「要対応」＋原因別の解決導線＋手動再試行ボタン）。
- **認証エラー時**: キューは保持したまま全体を一時停止し、通知＋アプリ内バナーで再サインインを誘導。サインイン成功で自動再開。
- **サインアウト時**: 未アップ N 件を警告表示。キューは破棄せず保持。
- **未サインイン時**: ジョブは pending のまま滞留し、バッジは「Drive未設定」（§10.5）。
- 指数バックオフ: 初回 30 秒、倍々で最大 1 時間。`connectivity_plus` のネット復帰イベントで即時再試行。

### 7.6 バックグラウンド挙動（2段構えの保証レベル）

| 状況 | 挙動 |
|---|---|
| フォアグラウンド中 | アプリ内 HTTP で即時 resumable アップロード（最速・確実） |
| iOS バックグラウンド | MVP は「FG 復帰時に resumable 再開」を主体とする。background URLSession 統合（multipart 一発アップ）は工数が重いため将来課題として明記 |
| Android バックグラウンド | WorkManager（`workmanager`）による OS 裁量のベストエフォート実行。Doze で遅延しうる |

- **24 時間以上キュー滞留でローカル通知**（「N 件が未アップロードです」）。
- 「自動・即時」は FG 中のみの保証であり、BG では「次回 FG 復帰までに」がユーザーへの約束レベル。

### 7.7 ストレージ逼迫時の自動削除（B5 — 安全化済み）

- 対象: **アップロード完了済み（uploadState=done）のローカルファイルのみ、古い順**。
- 閾値: **空き容量 500MB 未満（仮値、定数で一元管理）**で発動。
- 未アップロード録音は**いかなる場合も自動削除しない**。
- 削除後は `localPath=NULL` とし、一覧には残す。再生時は「Drive から再取得（要オンライン）」導線を出す。

---

## 8. 文字起こしサブシステム（是正済み抽象化）

### 8.1 設計方針

- 単一 `TranscriptionEngine` インターフェース（同期/非同期を1つの IF に押し込む案）は**採用しない**（レビュー指摘#9: ファットインターフェース化・ジョブ喪失・BG isolate 問題）。
- **出力は `TranscriptionEvent` ストリームで統一**、**入力は Streaming / Batch の2インターフェースに分離**。
- capability（静的宣言）＋ `checkAvailability()`（動的照会）の**2層公開**。
- ジョブは DB に永続化し、起動時に再購読。**状態の single source of truth は DB**。

### 8.2 抽象インターフェース（Dart）

```dart
/// 出力イベント — 全エンジン共通。UI/永続化はこのストリームだけを見る
sealed class TranscriptionEvent {
  const TranscriptionEvent();
}

class TranscriptionPartial extends TranscriptionEvent {
  final String text;          // 暫定テキスト（Streaming 用 / Batch の途中結果）
  final bool isFinalSegment;  // このセグメントが確定したか
  const TranscriptionPartial(this.text, {this.isFinalSegment = false});
}

class TranscriptionProgress extends TranscriptionEvent {
  final double? ratio;        // 0.0-1.0（不明なら null）
  const TranscriptionProgress(this.ratio);
}

class TranscriptionCompleted extends TranscriptionEvent {
  final String fullText;      // 確定全文（.txt の内容）
  const TranscriptionCompleted(this.fullText);
}

class TranscriptionFailed extends TranscriptionEvent {
  final String reason;
  final bool isRetryable;
  final String? partialText;  // 部分成功分（あれば保存し「一部のみ」状態にする）
  const TranscriptionFailed(this.reason, {required this.isRetryable, this.partialText});
}

/// capability 静的宣言
enum AudioInputMode { feedsPcm, ownsMic, file }
enum LanguageMode { fixedList, autoDetect }

class EngineCapability {
  final AudioInputMode audioInputMode;
  final Set<String> acceptedFormats;   // 例 {'m4a', 'opus'}（file モードのみ意味を持つ）
  final int? maxFileSizeBytes;         // 例 Whisper API: 25MB。null=無制限
  final LanguageMode languageMode;
  const EngineCapability({
    required this.audioInputMode,
    required this.acceptedFormats,
    required this.maxFileSizeBytes,
    required this.languageMode,
  });
}

class EngineAvailability {
  final bool available;
  final String? unavailableReason;     // 'offline' | 'permissionDenied' | 'localeUnsupported' ...
  const EngineAvailability(this.available, [this.unavailableReason]);
}

/// 全エンジン共通の基底
abstract interface class TranscriptionEngine {
  String get id;                       // 'cloud_stt' | 'os_native' | 'whisper_cpp' ...
  String get displayName;
  EngineCapability get capability;
  /// 実行時の動的照会（ネット接続・OS権限・言語対応・モデルDL済み等）
  Future<EngineAvailability> checkAvailability({String? localeId});
  /// 選択中エンジンが対応する言語一覧（設定画面の言語リスト用）
  Future<List<String>> supportedLocales();
}

/// 入力IF その1: ストリーミング型（将来のリアルタイム用。MVP では実装しない）
abstract interface class StreamingTranscriptionEngine implements TranscriptionEngine {
  Stream<TranscriptionEvent> start({required String localeId});
  Future<void> stop();
}

/// 入力IF その2: バッチ型（MVP の既定。録音ファイルを渡して後で結果受領）
abstract interface class BatchTranscriptionEngine implements TranscriptionEngine {
  /// 投入。戻り値はシリアライズ可能な jobHandle（JSON文字列）— DB に永続化する
  Future<String> submit(File audio, {String? localeId});
  /// jobHandle からイベントストリームを（再）購読。アプリ再起動後もこれで復帰する
  Stream<TranscriptionEvent> watch(String jobHandle);
  Future<void> cancel(String jobHandle);
}
```

### 8.3 サービス層とユースケース

```dart
/// ドメインサービス（Riverpod 非依存・BG isolate からも直接使用可）
class TranscriptionService {
  /// 録音単位の（再）文字起こし。新規/失敗後リトライ/エンジン切替後の再実行すべてこの1本
  Future<void> transcribe(String recordingId, {String? engineId});
  /// 起動時: submitted/running のジョブを watch() で再購読
  Future<void> resumePendingJobs();
}
```

- `transcribe(recordingId)` の流れ: エンジン解決（Registry）→ `checkAvailability()` → capability 検証（フォーマット・サイズ。超過時は failed＋理由）→ `transcription_jobs` INSERT（queued）→ `submit()` → jobHandle 永続化（submitted）→ `watch()` 購読 → イベントを DB へ反映 → Completed で `.txt` をローカル生成し `upload_jobs(kind=transcript)` へ投入。
- **再文字起こし**は一覧項目のメニューから実行可能（既存 txt は Drive 側同名上書き＝fileId 維持の update）。
- エンジン選択は `TranscriptionEngineRegistry`（`Map<String, TranscriptionEngine>`、Riverpod provider で公開）で差し替え。

### 8.4 MVP の既定エンジン

- **`CloudSttEngine`**（`BatchTranscriptionEngine` 実装、Whisper API 等のクラウド STT）。
  - capability: `audioInputMode: file`, `acceptedFormats: {'m4a','opus'}`, `maxFileSizeBytes: 25MB`（API 制約に合わせる）, `languageMode: fixedList`。
  - `checkAvailability()`: ネット接続＋API キー設定済みかを確認。
  - maxFileSize 超過時: MVP では failed（理由バッジ）。将来は分割送信を検討。
  - API キーは flutter_secure_storage に保存（MVP は設定画面から入力）。
- 将来追加: `OsNativeEngine`（Streaming、オンデバイス対応言語のみ・ベストエフォート）、`WhisperCppEngine`（Batch・オフライン）。

### 8.5 言語設定

- 設定画面の言語リストは**選択中エンジンへの動的照会**（`supportedLocales()`）で構築。autoDetect エンジンでは言語選択を非表示。
- グローバル設定のみ（録音単位の言語指定なし）。ジョブ投入時点の設定値を `transcription_jobs.localeId` に固定。
- 非対応言語だった場合は自動スキップ（failed 扱い＋バッジで通知）。

### 8.6 文字起こし状態（recordings.transcriptState への射影）

| transcriptState | バッジ表示 | 条件 |
|---|---|---|
| `off` | OFF（非表示可） | 文字起こし設定 OFF、または権限縮退 |
| `processing` | 処理中 | job が queued / submitted / running |
| `done` | 完了 | Completed 受領・txt 生成済み |
| `partial` | 一部のみ | Failed だが partialText あり（得られた分の txt を保存・アップ） |
| `failed` | 失敗（再試行可） | 完全失敗。タップで再文字起こし |

---

## 9. 認証・セキュリティ

- **トークン保存**: `flutter_secure_storage`。iOS Keychain は `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`、Android は Keystore ベース。shared_preferences には絶対に置かない。
- **サインアウト時に revoke**: トークン破棄だけでなく Google 側の revoke エンドポイントを呼ぶ。未アップ件数の警告を出しつつキューは保持。
- **保存先はアプリ内部ストレージ限定**（録音・txt・drift DB）。外部ストレージ・共有ディレクトリに置かない。
- **バックアップ除外**: iOS は `isExcludedFromBackup`、Android は `android:allowBackup="false"` または `dataExtractionRules` で録音・DB・トークンを除外。
- iOS ファイル保護: `NSFileProtectionCompleteUntilFirstUserAuthentication`（BG 録音・アップロードと両立する最も強いレベル）。
- **ログポリシー**: トークン・録音タイトル・文字起こし本文をログに出さない。エラーログは種別＋recordingId（UUID）まで。
- 同意・プライバシ配慮は**最小限（個人利用割り切り）**。初回同意ダイアログ・ポリシー URL・ストア申告はストア公開時の課題（§13）。

---

## 10. UX / 画面設計

### 10.1 録音一覧（ホーム）

- 起動時に表示。各行: タイトル（または日時）・録音日時・録音時間・ファイルサイズ・**アップロードバッジ**・**文字起こしバッジ**。
- drift のリアクティブクエリ（recordings 単独。ジョブ状態は非正規化列で保持）を `StreamProvider` で購読し、バッジは実状態に自動追従。
- **アップロードバッジ（4状態＋未設定変種）**: 未アップ（pending。未サインイン時は「Drive未設定」表示・タップで設定誘導）/ アップ中（進捗）/ 完了 / 要対応（permanentFailed。タップで原因と解決導線＋手動再試行）。
- 一覧上部に**オフラインバナー**（connectivity_plus 検知。「オフライン: N 件が未アップロード」）。
- 行操作: 再生 / タイトル変更 / 削除 / 再文字起こし / txt 閲覧。

### 10.2 録音中 UI

- 全画面共通の**録音中バー**（経過時間＋停止ボタン）。どの画面からでも状態が見え、停止できる。
- 録音中は新規録音ボタン無効化（多重録音排他）、当該録音項目の削除・改名不可。

### 10.3 再生・txt 閲覧

- 再生 UI: **シークバー＋±15秒スキップ＋再生速度（0.5x–2.0x）**。
- `localPath=NULL`（自動削除済み）の場合は「Drive から再取得（要オンライン）」ボタン。
- txt 閲覧画面: `transcriptLocalPath` の内容をプレーン表示（partial 時は「一部のみ」注記）。

### 10.4 削除フロー（安全化済み）

- 既定 = **ローカルのみ削除**（Drive 側は残る）。
- Drive 側も削除する場合は明示チェックボックス＋赤字警告。txt があればペアで削除（fileId 基準）。
- **未アップロード録音の削除は強警告**（「まだ Drive に上がっていません。削除すると復元できません」）＋アップロードキューからジョブ除去。

### 10.5 オンボーディング

- **録音はサインイン不要で常に可能**。アップロードのみ保留され、バッジ「Drive未設定」→タップでサインイン誘導。
- 初回起動時は**マイク権限のみ必須**。拒否時: 説明画面 → OS 設定への誘導、の2段フロー。
- 通知権限（Android 13+）は初回録音開始時に要求（拒否でも録音は可能、FGS 通知が出ないだけである旨を説明）。
- 初回録音時に Android バッテリ最適化除外を案内（スキップ可）。

### 10.6 設定画面

- Google アカウント連携（サインイン / サインアウト。サインアウト時は未アップ警告）
- Drive 保存先の表示（`/VoiceRecorder/` 固定。フォルダを開くリンクのみ）
- 文字起こし ON/OFF ・エンジン（MVP はクラウド STT のみ）・言語（エンジン照会で構築）・API キー入力
- ストレージ: 使用量表示・アップ済みローカルファイルの手動一括削除

---

## 11. 命名・フォルダ規約

- 基準時刻: **録音開始時点の端末ローカル時刻**（DB には TZ オフセット付き ISO8601 で保存）。
- ファイル名: `YYYY-MM-DD_HH-mm-ss[_タイトル].<ext>`（**秒まで**含む）。例: `2026-07-04_14-30-05_経営会議.m4a`（iOS）/ `.opus`（Android）。txt は同名 `.txt`。
- タイトル部: ユーザー入力をサニタイズ（`/ \ : * ? " < > |` と制御文字を除去、長さ上限 80 文字）。
- **改名はタイトル部のみ**変更可能。日時プレフィックスは不変。音声と `.txt` は**ペアで改名**し、Drive 反映は fileId 基準の update。
- Drive フォルダ: `/VoiceRecorder/<YYYY>/<YYYY-MM>/`（録音開始時刻基準の月次サブフォルダ）。

---

## 12. 起動シーケンス（リカバリ・再購読）

1. drift DB オープン
2. 未クローズ録音のリカバリ（§6.2）→ 復元分をキュー投入
3. `upload_jobs` の `uploading`（中断）を `pending` に戻す／`nextRetryAt` 経過分を再開
4. `transcription_jobs` の `submitted`/`running` を `resumePendingJobs()` で再購読
5. connectivity 監視開始、FG 復帰時のキュー flush
6. UI 起動（一覧表示）

---

## 13. 既知の制約・将来課題

| 項目 | 内容 |
|---|---|
| フォーマット非統一 | iOS `.m4a` / Android `.opus`。後段 Workflow は両方を受ける前提。将来 libopus/libogg の FFI 統合で `.opus` に統一 |
| リアルタイム文字起こし | 将来オプション。`StreamingTranscriptionEngine` の席は確保済み。オンデバイス対応言語のみ・ベストエフォート・取りこぼし許容。録音との同時マイク利用は自前ネイティブパイプラインが必要 |
| iOS BG アップロード | MVP は FG 復帰時再開が主体。background URLSession 統合は将来課題 |
| ストア公開時の対応 | 初回録音同意ダイアログ、利用規約/プライバシーポリシー URL、STT 外部送信の明示オプトイン、App Privacy / Data Safety 申告 |
| 共有ドライブ・共有フォルダ | MVP 対象外 |
| 再インストール時の復元 | Drive からの一覧復元は MVP 対象外（appProperties があるため将来実装可能） |
| 多言語混在会議 | MVP 対象外 |
| Whisper API 25MB 制限 | 長時間録音は超過しうる。MVP は failed＋理由表示。将来は分割送信 |
| google_sign_in v7 | Drive 疎通の既知の不安定報告。Phase 0 で検証し、必要なら v6 へフォールバック |
