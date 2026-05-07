# SPECA 詳細解説（日本語版） — 第 7 章 CLI（speca-cli）

> 関連：[概略と目次](概略と目次.md) ／ [前：第 6 章 スキル・プロンプト・MCP](SPECA詳細解説日本語版_第6章.md) ／ [次：第 8 章 サーバと Web UI 設計](SPECA詳細解説日本語版_第8章.md)

第 5 章までは Python パイプラインの内部を解説しました。本章では、その **前面に立つ TUI（Terminal User Interface）** である `speca-cli` を扱います。

`speca-cli` は **設計仕様（`docs/SPECA_CLI_SPEC.md`）が確立済み** で、現在は **M1（スケルトン）** までが実装されている段階です。M2 以降の機能（プロジェクト初期化ウィザード、認証、パイプラインダッシュボード、所見ブラウザ、Claude チャット）は roadmap に従って順次実装される予定です。

---

## 7.1 立ち位置：なぜ TUI が必要なのか

現状の SPECA OSS をユーザがそのまま使うと、次のような手数が必要です：

1. リポジトリをクローン
2. `uv` ／ Claude Code CLI ／ Node.js を個別にインストール
3. `outputs/BUG_BOUNTY_SCOPE.json` ／ `outputs/TARGET_INFO.json` を手書きする
4. `uv run python3 scripts/run_phase.py --target 04 --workers 4` を実行
5. 別ターミナルで `outputs/logs/*.jsonl` を tail
6. `outputs/03_PARTIAL_*.json` ／ `04_PARTIAL_*.json` を手作業で読む

これは新規ユーザに対する障壁が高すぎます。`speca-cli` は **これらすべてを `npx speca-cli` という 1 コマンドに集約** することを目標にした、対話型ターミナル UI です。

具体的には：

- ユーザは **Claude Code サブスクリプション** で認証（API キー不要）
- 対象リポジトリと仕様 URL を **ガイド付きプロンプト** で設定（JSON 手書き不要）
- フェーズごとに **「実行 / スキップ / 強制再実行」** のプロンプトで進める
- 右ペインで **ログと部分結果がライブ表示**
- フェーズ 03／04 完了後は **所見ブラウザ** で重要度ソート・フィルタしながら閲覧
- 任意の所見・ログ行・プロパティに対して **「Claude に質問」** が可能

---

## 7.2 設計方針：再利用、再発明しない

`speca-cli` のドキュメントには印象的な原則が書かれています：

> `speca-cli` is therefore designed as an **integration project**, not a from-scratch TUI.

具体的には：

| 既存資産 | 活用方法 |
|---|---|
| Python オーケストレータ | **書き直さず subprocess として呼び出す** |
| Claude Code OAuth フロー | `ex-machina-co/opencode-anthropic-auth` の動作するコードを **vendor**（自前で書かない） |
| TUI フレームワーク | **Ink + React 19** をそのまま使う（独自レンダリングループ無し） |
| プロンプト UI | **`@clack/prompts`** をそのまま使う |
| ファイル監視 | **`chokidar`** をそのまま使う |
| レイアウトパターン | opencode と lazygit から **借用**（forkはしない） |

これにより、`speca-cli` は **TUI 層のみ** が新規コードで、その他は既存資産の組み合わせになります。OSS をスタートアップが運営する以上、メンテナンス対象を増やさない判断は重要です。

### 拒否された代替案

仕様書には、検討の上で却下された選択肢も明記されています：

| 候補 | 却下理由 |
|---|---|
| **Bubble Tea**（Go） | エルゴノミクスは優秀だが、Go バイナリは `npx` 配布できない |
| **Charm Crush** | 最高品質のチャット TUI だが、FSL-1.1-MIT ライセンス（2 年遅延 MIT）。自由に vendor／fork できない |
| **OpenTUI** | opencode が最近採用したが、まだ若い（v0.2.2、2026 年 5 月時点）かつ Bun 依存。Ink の方が安全 |
| **blessed**（生 API） | 柔軟だが、5 章のレイアウトを命令型 API で書くと LoC が膨れ上がる |
| **prompts／inquirer のみ** | 単発プロンプトしかできず、永続ペインとライブログストリーミングには不足 |
| Web UI（Electron／ブラウザ） | TUI で十分、かつ監査ハーネスにとってヘビーすぎる |

---

## 7.3 ゴールと非ゴール

### ゴール

| # | ゴール | 動機 |
|---|---|---|
| G1 | `npx speca-cli` 1 コマンドで対象リポジトリへの監査が完了 | 10 ステップのセットアップが新規採用の障壁 |
| G2 | 認証は Claude Code サブスクリプションを使用 | Anthropic API は従量課金、サブスクライバはフラット料金。サブスク勢を排除しない |
| G3 | ワーカ進捗・ログ・部分所見をリアルタイム可視化 | フェーズ 03 は数分〜十数分かかるため、黒箱待ちは耐えられない |
| G4 | `BUG_BOUNTY_SCOPE.json` ／ `TARGET_INFO.json` を **対話的** に作成 | 初回失敗の最大原因がここ |
| G5 | 所見について「Claude に質問」がワンキーで可能 | 「ツールが何かを見つけた」から「で、何をすべきか」へのループを閉じる |
| G6 | macOS ／ Linux ／ WSL2 で動作 | 監査者は 3 OS にまたがる |
| G7 | 既存の venv ／ クローン済リポを尊重して degradation 可能 | パワーユーザがガイド付きステップを skip できる |

### 非ゴール

| # | 非ゴール | 理由 |
|---|---|---|
| N1 | Web UI ／ VSCode 拡張 | TUI で十分、メンテナンスコストが安い |
| N2 | Node.js でオーケストレータを再実装 | Python が公式アーティファクト。並行実装は二重保守 |
| N3 | SaaS としてホスト | ローカルツール。監査データはユーザのもの |
| N4 | フェーズ 5/6 で非 Claude モデル対応 | v1 は対象外、上流対応待ち |
| N5 | `uv` ／ `git` ／ `node` の自動インストール | bootstrap は別問題。エラーメッセージで明示 |

---

## 7.4 ユーザストーリー

### 7.4.1 初回監査者（Alice）

> Alice は学会で SPECA の話を聞いたセキュリティ研究者。Claude Code は普段使い。お気に入りのコンセンサスクライアントを SPECA で監査したい。

**フロー**：

1. `npx speca-cli` → スプラッシュ＋MIT ライセンス通知 → 「キーを押して開始」
2. **認証チェック**：内部で `claude auth status` を実行 → 既にログイン済みを検出 → ✅「alice@example.com として認証済み（Claude Code サブスクリプション）」
3. **プロジェクトウィザード**：
   - 「何を監査しますか？」 → `lighthouse`
   - 「対象リポジトリの GitHub URL は？」 → `https://github.com/sigp/lighthouse`
   - 「特定のコミットに pin しますか？（既定：default ブランチの HEAD）」 → Enter で skip
   - 「仕様 URL を貼り付けてください（複数可、Ctrl-D で終了）」 → EIP-7594 の URL
   - 「バグバウンティスコープ。テンプレートを使いますか？」 → Y → `ethereum-consensus` テンプレート読込
4. **パイプライン実行**：TUI に 6 行（フェーズごと）が表示。Enter で開始。各フェーズが順次進み、ワーカ進捗バー＋ライブログが右ペインに表示
5. **所見ブラウザ**：フェーズ 04 完了後、TUI が所見リスト画面に切替（重要度別カラー）。Alice が CONFIRMED_VULNERABILITY を選んで proof trace と attack scenario を確認
6. **Claude に質問**：`?` を押すと所見コンテキスト付きでチャットペインが開く。「これは P2P 越しの第三者から exploit 可能？」と聞いて 3 秒で回答。**サブスクリプション従量で課金される**
7. **エクスポート**：`Ctrl-S` でプロジェクトディレクトリに Markdown サマリを書出

### 7.4.2 パワーユーザ（Bob）

> Bob は CI で SPECA を回している。Python オーケストレータは既に動いている。CI ランのライブモニタだけを TUI で見たい。

**フロー**：

1. 既存の SPECA リポジトリ内で `npx speca-cli`（または `speca attach`）
2. CLI が既存の `outputs/` を検出し「Attach ／ Resume ／ Force re-run ／ Browse」を提示
3. Bob は「Attach」を選択 → 設定プロンプトをスキップしてライブログと部分結果を即座に表示

### 7.4.3 レビュア／トリアージユーザ（Carol）

> Carol は前日の SPECA ランを PR 提出前にレビューしたい。特定の所見だけドリルダウンしたい。

**フロー**：

1. `npx speca-cli browse outputs/04_PARTIAL_*.json`（またはプロジェクトディレクトリ内で `speca browse`）
2. パイプライン実行不要で、TUI が直接所見ブラウザを開く
3. `severity:high` でフィルタ、所見を選択、`?` で Claude に grounded 質問

---

## 7.5 認証：Claude Code サブスクリプション活用

### 7.5.1 なぜサブスクリプション認証なのか

Anthropic の課金は 2 系統：

- **API**：トークン従量課金（`ANTHROPIC_API_KEY`）
- **Claude Code サブスクリプション**：定額（個人 / Max プラン）

Claude Code サブスクライバは既に定額を払っているので、**API キーを別途使わせるとダブルチャージになります**。`speca-cli` は **デフォルトでサブスクリプション認証** を使うことで、サブスクライバを排除しません。

### 7.5.2 検出アルゴリズム

```
起動時:
  1. claude auth status を実行
     - exit 0 + status == "authenticated" → サブスクリプションを使用（推奨）
     - 失敗 → step 2 へ
  2. ANTHROPIC_API_KEY 環境変数があれば → API キーフォールバックを提示
  3. なければ → claude auth login をインタラクティブに起動
                成功すれば step 1 を再試行
                失敗ならエラーメッセージ付きで終了
```

### 7.5.3 OAuth フローの実装（vendor 戦略）

サブスクリプション認証は **Anthropic 公式には開かれていない** （Claude Code 内部メカニズムとして扱われる）ため、vendor している `ex-machina-co/opencode-anthropic-auth` のコードを使い、Claude Code CLI を装って OAuth を実行します。

```
[speca-cli] ──(1) URL 開く──▶ [ブラウザ] ──(2) ログイン──▶ [claude.ai/oauth/authorize]
                                                                        │
                                                            (3) リダイレクト
                                                                        ▼
                                                       [platform.claude.com/oauth/code/callback]
                                                                        │
                                                            (4) ページにコード表示
                                                                        ▼
[speca-cli] ◀──(5) ユーザがコードを貼付け──────────────────────────────┘
       │
       │  (6) POST platform.claude.com/v1/oauth/token
       │      { code, state, code_verifier, client_id, redirect_uri,
       │        grant_type: "authorization_code" }
       ▼
   { access_token, refresh_token, expires_in }
```

### 7.5.4 「魔法のスコープ」`user:sessions:claude_code`

OAuth スコープのうち、**Claude Code サブスクリプション枠で課金される** ためのキーは：

```typescript
export const OAUTH_SCOPES = [
  'org:create_api_key',
  'user:profile',
  'user:inference',
  'user:sessions:claude_code',  // ← これがサブスクリプション課金の鍵
  'user:mcp_servers',
  'user:file_upload',
]
```

これがないと、トークンが inference 呼び出しで拒否されるか、最悪「Pro web 限定（API 枠なし）」に課金されてしまいます。`speca doctor` はトークン中にこのスコープが含まれているかを必ず検証します。

### 7.5.5 ヘッダなりすまし

inference 呼び出し時には次のヘッダが必須：

| ヘッダ | 値 | 意図 |
|---|---|---|
| `Authorization` | `Bearer <access_token>` | 標準 OAuth |
| `User-Agent` | `claude-cli/2.1.87 (external, cli)` | Anthropic は不明 UA をブロックするため、公式 CLI を装う |
| `anthropic-beta` | `oauth-2025-04-20,interleaved-thinking-2025-05-14` | OAuth 自体が beta 機能 |
| `anthropic-version` | （上流の固定値） | 標準 |

### 7.5.6 安定性への注記

この OAuth フロー全体は **公式仕様化されていない** ため、いつ Anthropic 側で塞がれてもおかしくない、と仕様書は明記しています。緩和策：

- 認証定数を **1 ファイル（`src/auth/constants.ts`）** に集約してホットフィックスを容易に
- **API キーフォールバック** を必ず提供
- vendor 元の固定バージョンを `speca doctor` で表示
- 週次 CI スモークテストで OAuth フロー動作を検証

---

## 7.6 TUI のスクリーン構成

`speca-cli` は opencode／lazygit／k9s スタイルの **モーダルレイアウト** を踏襲します：

- 永続的な **ヘッダ**（プロジェクト名、フェーズ状態、認証状態）
- **メインペイン**（モードに応じて Setup ／ Run ／ Browse ／ Chat に切替）
- 永続的な **サイドペイン**（右または下、ライブログ用）
- 下部の **ステータスバー**（キーバインド表示）

### 7.6.1 Welcome / プロジェクトピッカー

プロジェクトコンテキストなしで起動された場合：

```
┌─ SPECA — Specification-to-Checklist Auditing ───────────────────────┐
│                                                                       │
│   Recent projects:                                                    │
│     ▸ ~/audits/lighthouse-fusaka      (last run 2 days ago)          │
│       ~/audits/grandine-fusaka        (last run 1 week ago)           │
│                                                                       │
│   [N]ew project   [O]pen by path   [B]rowse-only   [?] Help   [Q]uit │
└───────────────────────────────────────────────────────────────────────┘
```

「プロジェクト」とは、`outputs/TARGET_INFO.json` ＋ `outputs/BUG_BOUNTY_SCOPE.json` ＋ 過去の `outputs/*_PARTIAL_*.json` を含むディレクトリのこと。

### 7.6.2 新規プロジェクトウィザード

ステップ単位のフォーム：

| Step | プロンプト | フィールド | 検証 |
|---|---|---|---|
| 1 | プロジェクト名 | text | 非空、ファイル名安全 |
| 2 | ターゲット git URL | URL | `git ls-remote` で疎通確認 |
| 3 | コミット pin？ | text または "default" | optional、`git fetch` で確認 |
| 4 | 仕様 URL（複数行） | URL（複数） | 各 URL が 200 を返すこと |
| 5 | バグバウンティスコープ | template / paste / skip | （後述） |
| 6 | 監査予算 | dollar cap | 正数。v1 既定 $10 |

ウィザードは `outputs/TARGET_INFO.json` と `outputs/BUG_BOUNTY_SCOPE.json` を書き出してダッシュボード画面へ。

### 7.6.3 パイプラインダッシュボード（メイン画面）

```
┌─ lighthouse-fusaka ────────  alice@example.com (subscription) ──────────┐
│ Phase   Name                       Status        Progress    Findings    │
│  01a    Spec Discovery             ✔ done        28 specs    —           │
│  01b    Subgraph Extraction        ✔ done        41 graphs   —           │
│  01e    Property Generation        ⠋ running     34/47       —           │
│  02c    Code Pre-resolution        ◌ pending     —           —           │
│  03     Audit Map                  ◌ pending     —           —           │
│  04     Audit Review               ◌ pending     —           —           │
├──────────────────────────────────────────────────────────────────────────┤
│ Live log (right pane)                                                    │
│   [01e/W2] worker 2 batch 5: generated 4 properties (cumulative: 134)    │
│   [01e/W0] worker 0 batch 5: generated 2 properties (cumulative: 132)    │
│   [01e/W1] worker 1 batch 5: BudgetTrack: spent $0.42 / $10.00            │
├──────────────────────────────────────────────────────────────────────────┤
│ [Enter] run / pause   [F] force re-run   [L] full log   [B] browse       │
│ [?] ask Claude         [Q] quit                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

各行のキーバインド：

- `Enter` — フェーズを開始（キュー作成、ワーカ起動）
- `s` — スキップ（done としてマーク、実行しない）
- `f` — 強制再実行（resume state をクリア）
- `l` — フェーズの全ログを全画面ページャで開く

### 7.6.4 予算ゲージ

ボトムバーは `spent / cap` を CostTracker から更新表示。80% で黄色、100% でランナ停止＋モーダル「上限を上げて再開？」を表示。

### 7.6.5 所見ブラウザ

```
┌─ Findings (lighthouse-fusaka) ──────────────────────  72 total · 24 FP ─┐
│ Severity  Verdict                Property                    Loc       │
│ ▸ HIGH    CONFIRMED_VULN         PROP-6a4369e9-inv-042       data_co… │
│   HIGH    DOWNGRADED → MED       PROP-57888860-inv-006       reconst… │
│   MED     CONFIRMED_POTENTIAL    PROP-6a4369e9-pre-009       codec.r… │
├────────────────────────────────────────────────────────────────────────┤
│ Detail (selected finding)                                              │
│   Property:  PROP-6a4369e9-inv-042  (severity: HIGH)                   │
│   Verdict:   CONFIRMED_VULNERABILITY                                    │
│                                                                         │
│   Proof trace                                                           │
│     The cache key omits KzgCommitments (the data being proven), …      │
│                                                                         │
│   Attack scenario                                                       │
│     Attacker sends valid DataColumnSidecar A, then sends forged…       │
│                                                                         │
│   Code path                                                             │
│     beacon-chain/verification/data_column.go::inclusionProofKey :527-547│
├────────────────────────────────────────────────────────────────────────┤
│ [/] filter   [s] sort   [c] code-view   [?] ask Claude   [B] back     │
└────────────────────────────────────────────────────────────────────────┘
```

#### フィルタ DSL

`/` キーで開く検索バーは小さな DSL を解釈：

| フィルタ | 例 |
|---|---|
| `severity:` | `severity:high`、`severity:high\|critical` |
| `verdict:` | `verdict:CONFIRMED_VULNERABILITY` |
| `prop:` | `prop:PROP-6a4*`、`prop:*-inv-042` |
| `repo:` | `repo:lighthouse_fusaka`（RQ1 風マルチターゲット用） |
| 自由テキスト | `proof_trace` ＋ `attack_scenario` に対するマッチ |

複数指定で AND：`severity:high verdict:CONFIRMED_VULNERABILITY p256verify`

### 7.6.6 「Claude に質問」（チャットペイン）

`?` キーで起動。**現在の選択を system context として** Claude に渡すので、Claude は所見についてあらかじめ知っている状態で対話できます。

```
┌─ Ask Claude ─────────────  about: PROP-6a4369e9-inv-042 (HIGH) ────────┐
│  Claude                                                                 │
│  Yes, this is exploitable from a stranger over P2P. The                 │
│  DataColumnSidecar message is gossiped over the column-sidecar topic    │
│  with no peer-trust scoping; an attacker who can connect to the         │
│  validator's libp2p mesh can submit the second sidecar.                 │
│                                                                         │
│  > is this exploitable from a stranger over P2P?                        │
└─────────────────────────────────────────────────────────────────────────┘
```

実装は：

```typescript
// 各ターンで claude CLI を呼び、--resume で既存セッション ID を引継ぐ
spawnClaudeStream({
  args: ["-p", prompt, "--output-format", "stream-json", "--resume", sessionId],
  inheritEnv: true,  // サブスクリプショントークンは親シェルから継承
});
```

これによりサブスクリプション枠で課金され、マルチターン文脈も保持されます。

---

## 7.7 コマンドサーフェス

`speca` はインタラクティブ TUI（既定）と **スクリプティング向けサブコマンド** の両方を提供：

```
speca                          # TUI を起動
speca run [--phase=<id>]       # ヘッドレス実行（JSON イベントを stdout に流す）
speca browse [path-glob]       # 所見ブラウザに直行
speca attach                   # 動作中のパイプラインに read-only attach
speca auth status              # 認証状態を表示
speca auth login               # claude auth login の pass-through
speca init                     # 新規プロジェクトウィザードのみ実行
speca config get|set <key>     # BUG_BOUNTY_SCOPE.json の単一キーを読み書き
speca doctor                   # Node/uv/git/claude-code の診断
speca version
speca help [command]
```

共通フラグ：

| フラグ | 説明 |
|---|---|
| `--project, -C <dir>` | プロジェクトディレクトリ（既定：cwd） |
| `--auth=<mode>` | `auto` / `subscription` / `api-key`（既定：auto） |
| `--workers <n>` | ワーカ並列度（PhaseConfig 継承） |
| `--budget <usd>` | コスト上限 |
| `--no-tui` | プレーンテキスト出力（CI 用） |
| `--json` | 機械可読イベント出力（`--no-tui` を含意） |

---

## 7.8 アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│  speca-cli (Node.js, npm/npx 配布)                          │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Ink TUI layer │  │ project mgr  │  │  config mgr  │      │
│  └───────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│          │                 │                 │              │
│          ▼                 ▼                 ▼              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  process bridge  (node-pty + JSONL ストリームパーサ)  │  │
│  └─────────┬───────────────────────┬─────────────────────┘  │
│            │                       │                        │
│  ┌─────────▼─────────┐    ┌────────▼────────┐               │
│  │ Python オーケスト │    │ Claude Code CLI │               │
│  │ レータ (uv 管理)  │    │ (subscription)  │               │
│  └────────────────────┘    └─────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

| レイヤ | 責任 | 言語 |
|---|---|---|
| **Ink TUI layer** | 画面描画・キーバインド・モーダル状態 | TypeScript ＋ Ink |
| **project manager** | プロジェクトディレクトリの検出・新規作成・再開 | TypeScript |
| **config manager** | `TARGET_INFO.json` ／ `BUG_BOUNTY_SCOPE.json` を JSON Schema で検証 | TypeScript |
| **process bridge** | `uv run python3 scripts/run_phase.py …` を PTY 付きで起動、`--stream-json` イベントを型付きメッセージにパース、TUI 状態にマルチプレックス | TypeScript ＋ `node-pty` |
| **Python オーケストレータ** | **既存のまま**。SPECA 実行の真理元 | Python（既存） |
| **Claude Code CLI** | 認証＋バッチワーカ起動＋サブスクトークン処理 | Anthropic 提供 |

---

## 7.9 既存リポジトリへの上流変更

`speca-cli` がきれいに動くために、Python 側に 2 つの **小さな変更** が必要と仕様書に明記されています：

| # | ファイル | 変更 | 動機 |
|---|---|---|---|
| U1 | `scripts/run_phase.py` | `--json` フラグを追加し、パイプラインレベルイベント（`phase-started`、`phase-completed` 等）を 1 行 1 JSON で stdout に出力 | TUI／CI／ダッシュボードがログスクレイピング無しに UI を駆動できる |
| U2 | `scripts/orchestrator/schemas.py` | `scripts/export_schemas.py` を追加し、Pydantic モデルを JSON Schema として書き出す | `speca-cli` が Python 抜きで `TARGET_INFO.json` ／ `BUG_BOUNTY_SCOPE.json` を検証できる |

両方とも `speca-cli` 単独でも有用な汎用機能なので、`speca-cli@1.0.0` リリース前に PR で統合される予定です。

---

## 7.10 マイルストーン M1〜M7 と現状

| Milestone | スコープ | 現状（2026 年 5 月時点） |
|---|---|---|
| **M1 — Skeleton** | npm パッケージ scaffold、Ink レイアウトシェル、`speca version` ／ `speca doctor` | ✅ 実装済 |
| **M2 — 認証＋プロジェクトウィザード** | `ex-machina-co/opencode-anthropic-auth` を vendor、`speca auth status/login`、`@clack/prompts` で対話ウィザード | 計画 |
| **M3 — パイプラインダッシュボード** | プロセスブリッジ、`--json` フラグの追加、Screen 3 のライブフェーズ行とログペイン | 計画 |
| **M4 — 所見ブラウザ** | フィルタ DSL／ソート／コードピーク | 計画 |
| **M5 — Claude に質問** | Claude セッション ID にバインドした Screen 5 チャットペイン | 計画 |
| **M6 — Polish + ドキュメント** | テーマ、キーバインド、エラーモーダル、`speca attach`、`speca browse [glob]` | 計画 |
| **M7 — v1 リリース** | npm publish、README、CI matrix green | 計画 |

M2 完了時点で内部プレビュー版を出す計画。

---

## 7.11 章のまとめ

- `speca-cli` は SPECA への **新規ユーザ採用障壁を下げる** ことが目的の TUI
- 設計の柱は **「再利用、再発明しない」** — Python オーケストレータ・OAuth 実装・TUI フレームワークすべて既存資産で組む
- 認証は **Claude Code サブスクリプション** が主路、**API キー** が予備路。`user:sessions:claude_code` スコープが課金を分ける鍵
- TUI は opencode／lazygit スタイルの **モーダルレイアウト** で、プロジェクトピッカー → ウィザード → ダッシュボード → 所見ブラウザ → Claude チャットの 5 画面構成
- 現状は M1（スケルトン）まで実装済。M2 以降がロードマップ
- Python 側にも 2 つの小さな上流変更（`--json` フラグ、JSON Schema export）が予定されている

次章では、**ブラウザベースの代替フロントエンド** にあたる FastAPI サーバと Web UI 設計を解説します。

---

## 7.12 参考文献

- `docs/SPECA_CLI_SPEC.md`（v0.1 ドラフト）
- `cli/README.md`、`cli/package.json`、`cli/src/`
- 関連プロジェクト：`ex-machina-co/opencode-anthropic-auth`、`sst/opencode`、`openai/codex`
