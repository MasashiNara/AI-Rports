# SPECA 詳細解説（日本語版） — 第 2 章 リポジトリ構成と主要コンポーネント

> 関連：[概略と目次](概略と目次.md) ／ [前：第 1 章 全体像とコンセプト](SPECA詳細解説日本語版_第1章.md) ／ [次：第 3 章 パイプライン詳細](SPECA詳細解説日本語版_第3章.md)

本章では、SPECA リポジトリの構成と各サブコンポーネントの役割を整理します。第 1 章の思想がコードベース上でどう実装されているかの「全景写真」です。

---

## 2.1 全体ディレクトリツリー

リポジトリのトップレベル構成は次のとおりです（主要ディレクトリのみ抜粋）：

```
speca/
├── README.md                    # OSS の入り口（評価結果含む）
├── CLAUDE.md                    # Claude Code 用のリポジトリガイド
├── pyproject.toml               # Python 依存定義（uv 管理）
├── conftest.py                  # pytest 共通設定
│
├── scripts/                     # ◎ Python パイプライン本体
│   ├── run_phase.py             #   エントリポイント（CLI から叩くスクリプト）
│   ├── setup_mcp.sh             #   MCP サーバ登録スクリプト
│   └── orchestrator/            #   ★ 監査ハーネス（再利用可能なフレームワーク）
│
├── prompts/                     # ◎ 各フェーズのワーカプロンプト
├── .claude/skills/              # ◎ Claude Code スキル（フェーズ 01a/01b 用）
│
├── tests/                       # Python ユニットテスト
├── schemas/                     # JSON Schema エクスポート
│
├── cli/                         # ◎ TypeScript / Ink TUI（speca-cli）
│   ├── package.json
│   ├── src/                     #   コマンド・コンポーネント・チェック処理
│   └── test/                    #   vitest テスト
│
├── server/                      # ◎ FastAPI サーバ（ローカル実行用 API）
│   ├── app.py                   #   FastAPI 本体
│   ├── routes/                  #   /phases /runs エンドポイント
│   ├── run_manager.py           #   非同期ラン管理
│   └── orchestrator_bridge.py   #   オーケストレータとの橋渡し
│
├── web/                         # ◎ Web UI 設計提案（実装は未着手）
│   └── WEB_APP_DESIGN.md
│
├── benchmarks/                  # ◎ 評価ベンチマーク（RQ1/RQ2/RQ2b）
│   ├── README.md
│   ├── rq1/  rq2a/  rq2b/       #   評価コード
│   └── results/                 #   論文に載せた数字の生成元アーティファクト
│
├── automation/                  # 補助プレイブック
│   └── AUDIT_PLAYBOOK.md
│
├── docs/                        # 各種設計ドキュメント
│   ├── SPECA_CLI_SPEC.md
│   ├── CLAUDE_CACHE_STRATEGY.md
│   └── ...
│
├── outputs/                     # 実行時出力（PARTIAL JSON、ログ、グラフ）
│
└── .github/workflows/           # ◎ GitHub Actions（フェーズごとに 1 ファイル）
    ├── 01a-discovery.yml
    ├── 01b-subgraph.yml
    ├── 01e-properties.yml
    ├── 02c-enrich-code.yml
    ├── 03-audit-map.yml
    ├── 04-audit-review.yml
    ├── full-audit.yml
    ├── benchmark-rq1-*.yml      #   RQ1 評価ジョブ群
    └── rq2a-*.yml  rq2b-*.yml   #   RQ2/RQ2b 評価ジョブ群
```

`◎` をつけたディレクトリが、本資料で個別に解説する **第一級コンポーネント** です。

---

## 2.2 Python 監査パイプライン（コア）

SPECA の本体です。「OSS としての SPECA」の中心はここで、CLI／サーバ／Web UI はすべてこれを呼び出すフロントエンドという位置付けです。

### 2.2.1 構成と責務

| ディレクトリ／ファイル | 責務 |
|---|---|
| `scripts/run_phase.py` | コマンドラインからの実行エントリ。依存解決・クリーンアップ・ラン起動 |
| `scripts/orchestrator/` | 再利用可能な監査ハーネス（後述、第 5 章） |
| `prompts/` | 各フェーズのワーカが受け取るプロンプト本体 |
| `.claude/skills/` | Claude Code に登録されるスキル（フェーズ 01a／01b で使用） |
| `tests/` | スキーマ・リゾルバ・キャッシュ検証のユニットテスト |
| `outputs/` | 実行時に作られる JSON／ログ／グラフ。`SPECA_OUTPUT_DIR` で位置を変更可能 |

### 2.2.2 「ハーネス＋プロンプト＋スキーマ」の三層構造

`scripts/orchestrator/` の `BaseOrchestrator` が監査ハーネスです。フェーズ追加は次の 3 点だけで完了します：

1. **`prompts/<phase>_*.md`** — ワーカが見るプロンプト
2. **`scripts/orchestrator/schemas.py`** — フェーズ間データ契約の Pydantic モデル
3. **`scripts/orchestrator/config.py`** の `PHASE_CONFIGS` — 新フェーズの登録（入力・出力パターン、バッチ戦略、回路ブレーカ閾値、コスト上限、MCP 構成、ツールフィルタ）

ハーネス自身（キューイング、トークンバッチング、再開、予算強制、ログ収集）は **触らずに** 新フェーズを追加できる設計です。これが「監査ハーネス＝再利用可能なフレームワーク」と呼ばれる所以です。

### 2.2.3 PHASE_CONFIGS の概観

`scripts/orchestrator/config.py` の `PHASE_CONFIGS` は、6 フェーズの設定を 1 つの dict で集中管理しています。代表的なフィールドだけ抜粋：

| Phase ID | model | バッチサイズ | 主な入力 | 主な出力 | MCP サーバ | ツールフィルタ |
|---|---|---|---|---|---|---|
| `01a` | （既定） | 1 | （初期フェーズ） | `outputs/01a_STATE.json` | `fetch` | （標準） |
| `01b` | （既定） | 2 | `01a_STATE.json` | `01b_PARTIAL_*.json` ＋ `.mmd` | `fetch`, `filesystem` | （標準） |
| `01e` | （既定） | 1 | `01b_PARTIAL_*.json` ＋ `BUG_BOUNTY_SCOPE.json` | `01e_PARTIAL_*.json` | （なし） | （標準） |
| `02c` | sonnet | 50 | `01e_PARTIAL_*.json` ＋ `01b_PARTIAL_*.json` | `02c_PARTIAL_*.json` | `tree_sitter`, `filesystem` | （標準） |
| `03` | sonnet | 1 | `02c_PARTIAL_*.json` | `03_PARTIAL_*.json` | （なし） | `Read,Write,Grep,Glob` |
| `04` | sonnet | 1 | `03_PARTIAL_*.json` ＋ `BUG_BOUNTY_SCOPE.json` | `04_PARTIAL_*.json` | （なし） | `Read,Write,Grep,Glob` |

特徴的な設計判断がいくつか読み取れます：

- **フェーズ 01a/01b は仕様理解中心** なので **Opus**（既定）、フェーズ 02c〜04 は **Sonnet**。論文も「仕様理解は Opus、コード解析は Sonnet」と書いており、コスト最適化が明確
- フェーズ 03 だけ **`max_budget_usd=200.0`** と高い予算上限。最も高コストなフェーズだから
- フェーズ 03／04 は **MCP を一切使わず**、組込みの `Read/Write/Grep/Glob` のみ。再現性とコンテキストの軽さのため
- フェーズ 02c は **`min_severity="Low"`** で `Informational` プロパティを早期に除外
- **`max_batch_size=1`**（フェーズ 03／04／01e）：プロパティ間で文脈が混入しないよう、1 件ずつ処理

詳細は第 5 章で扱います。

---

## 2.3 TypeScript CLI（`cli/`）

SPECA を「ターミナルから叩く」前面の TUI（Terminal UI）です。**Python パイプラインを書き直したものではなく、サブプロセスとして起動する** ラッパとして設計されています。

### 2.3.1 立ち位置

OSS 版 SPECA をそのまま使うには、現状こうしたステップが必要です：

1. リポジトリをクローン
2. `uv` ／ Claude Code CLI ／ Node.js をインストール
3. `outputs/BUG_BOUNTY_SCOPE.json` ／ `outputs/TARGET_INFO.json` を手書き
4. `uv run python3 scripts/run_phase.py --target 04 --workers 4` を実行
5. 別ターミナルで `outputs/logs/*.jsonl` を tail
6. `outputs/03_PARTIAL_*.json` ／ `04_PARTIAL_*.json` を手作業で読む

`speca-cli` は、これら全てを **`npx speca-cli` の 1 コマンド** に集約することを目標にした、対話型 TUI です（M1 リリース時点ではスケルトンで、現在はプロジェクト初期化／認証チェックなど一部のみ実装済み）。

### 2.3.2 構成

```
cli/
├── package.json                # speca-cli @ 0.1.0-alpha.0
├── tsconfig.json
├── src/
│   ├── cli.tsx                 # エントリ（meow + Ink + React 19）
│   ├── lib/checks.ts           # node / uv / git / claude の存在チェック
│   ├── components/Layout.tsx   # 共通ヘッダ／ボディ／ステータスフレーム
│   ├── auth/                   # 認証関連（Claude Code サブスクリプション）
│   └── commands/               # サブコマンド（version, doctor 等）
└── test/
    └── checks.test.ts          # vitest テスト
```

技術スタックは：

- **Ink 7 + React 19** — ターミナル UI のレンダリング
- **meow** — CLI 引数パース
- **which** — クロスプラットフォームのバイナリ検出
- **vitest** — テスト

設計詳細とロードマップ（M1〜M7）は **第 7 章** で扱います。

---

## 2.4 FastAPI サーバ（`server/`）

ブラウザや CLI／TUI から SPECA を起動するためのローカル API です。CLI とは別の選択肢として「Web ブラウザでパイプラインを動かす」用途を想定しています。

### 2.4.1 構成

```
server/
├── app.py                      # FastAPI 本体（CORS + lifespan）
├── routes/
│   ├── phases.py               # /phases — フェーズ起動・進捗
│   └── runs.py                 # /runs — ラン履歴・成果物取得
├── run_manager.py              # 並行ラン管理
├── orchestrator_bridge.py      # 既存 orchestrator パッケージとのアダプタ
├── progress.py                 # 進捗イベント抽象
├── discord.py                  # Discord 通知（Webhook）
└── models.py                   # API モデル（Pydantic）
```

### 2.4.2 起動方法

```bash
uv run uvicorn server.app:app --reload --port 8000
```

CORS は `http://localhost:5173`（Vite フロントエンド開発サーバ既定）に向けて開いており、ブラウザ側の Web UI と組み合わせて使うことが想定されています（Web UI 自体は現状 [`web/WEB_APP_DESIGN.md`](https://github.com/NyxFoundation/speca/blob/master/web/WEB_APP_DESIGN.md) の設計提案のみ）。

詳細は **第 8 章** で扱います。

---

## 2.5 Web UI 設計提案（`web/`）

`web/WEB_APP_DESIGN.md` に詳述されている **未実装の Next.js SSG（Static Site Generation）** 設計です。

ねらいは：

- Sherlock コンテストや RepoAudit ベンチマーク結果を **動的にフィルタリング可能な ダッシュボード** で公開
- 監査トレイル（フェーズ 03 の 3 サブフェーズ）を **アコーディオン展開** で可読化
- フェーズ 01b が出力する **Mermaid グラフ** をレンダリングして閲覧
- 学会の Artifact Evaluation で求められる「Available / Functional / Reproduced」バッジを取りやすくする

技術スタックは Next.js 14（App Router）／ TypeScript ／ shadcn/ui ＋ Tailwind ／ Recharts ＋ D3 ／ TanStack Table ／ Shiki ／ Mermaid.js。

「**既存コードへの影響ゼロ**」が原則で、Web UI 側は `outputs/` の JSON を `public/data/` にコピーするだけで動作する読取り専用ビューになる予定です。

詳細は **第 8 章** で扱います。

---

## 2.6 ベンチマーク（`benchmarks/`）

論文 RQ1／RQ2／RQ2b の評価コードと、論文に載った数字の **生成元アーティファクト** が一式入っています。

| 領域 | 内容 | ステータス |
|---|---|---|
| **RQ1** | Sherlock Ethereum Fusaka コンテスト評価（10 実装、366 件提出、15 件 H/M/L GT） | 論文掲載済み |
| **RQ2** | RepoAudit C/C++ ベンチマーク評価（15 プロジェクト、35 件 GT） | 論文掲載済み |
| **RQ2b** | ProFuzzBench（プロトコル実装、9 件 0day） | 探索的（論文未掲載） |

各ベンチマーク配下には：

- `evaluate.py` — 監査出力に対する精度／再現率／FP 分析
- `visualize.py` — 図表生成
- `ground_truth_bugs.yaml` — グラウンドトゥルース定義
- `published_baselines.yaml` — 比較対象（RepoAudit／Infer／CodeGuru 等）の数字
- `results/<rqX>/` — 生のアーティファクト（per-target 監査出力、ラベル、生成図）

論文の数字を「再現したい」場合は、`benchmarks/results/rq1/` または `benchmarks/results/rq2a/` の中身が **そのまま使える** ように設計されています。ベンチマーク詳細は **第 9 章** で扱います。

---

## 2.7 CI ワークフロー（`.github/workflows/`）

SPECA は CI／CD を「**実行手段の一つ**」として正面から扱っており、26 個のワークフローがあります。代表的なものを抜粋：

| ファイル | 役割 |
|---|---|
| `01a-discovery.yml` ～ `04-audit-review.yml` | 各フェーズを `workflow_dispatch` で個別起動 |
| `full-audit.yml` | エンドツーエンドのフル監査 |
| `benchmark-rq1-01-setup.yml` ～ `benchmark-rq1-04-report.yml` | RQ1 セットアップ → recall 評価 → FP 評価 → レポート |
| `rq2a-01-setup-dataset.yml`, `rq2a-03-audit-map-*.yml`, `rq2a-04-evaluate-*.yml` | RQ2 のモデル別評価（DeepSeek R1／Sonnet 4／Sonnet 4.5） |
| `rq2b-01-setup-dataset.yml`, `rq2b-02-visualize.yml` | RQ2b 探索的評価 |
| `cli-ci.yml` | TypeScript CLI のビルド／テスト |
| `issue-resolver.yml`, `openhands-resolver.yml`, `sweagent-issue-resolver.yml` | GitHub Issue 自動解決系（補助） |

各監査ワークフローの典型的な手順：

1. `master` から `scripts/`、`prompts/`、`.claude/` を最新化
2. Claude Code CLI のインストールと `setup_mcp.sh` の実行
3. `uv run python3 scripts/run_phase.py --phase <ID> --workers N` を実行
4. 結果を **専用の audit ブランチ** にコミットし、ログをアーティファクトとしてアップロード

詳細は **第 10 章** で扱います。

---

## 2.8 ディレクトリ構成から読み取れる設計判断

リポジトリの構成は、いくつかの明確な設計判断を反映しています：

### 設計判断 1: 「ハーネス／プロンプト／スキーマ」の三層分離

**プロンプトを書き換えればフェーズの挙動を変えられる、ハーネスは触らずに済む** という分離が徹底されています。これにより、「新しいターゲット領域」「新しいモデル」「新しい監査スタイル」を試すのが容易です。

### 設計判断 2: 「既存資産を書き直さない」

CLI（`cli/`）も Web UI（`web/`）も、Python オーケストレータを **書き直さず、サブプロセスや API で呼び出す** 方針です。これは公式 README にも明記されています：

> The Python orchestrator under `scripts/orchestrator/` is **not rewritten** — `speca-cli` invokes it as a subprocess and parses its stream-JSON output. This keeps the proven harness intact and confines the new code to the UI layer.

メンテナンス対象を増やさない、論文で評価された動作と同じものを動かす、という意図が明確です。

### 設計判断 3: 「PARTIAL ファイルが第一級市民」

`outputs/` 配下にバッチごとに `PARTIAL_*.json` を即座に保存する設計は、**再開・部分結果保持・スキーマ妥当性の遅延チェック** をすべて支えます。CI 実行で長時間かかっても、途中で落ちても続きから再開できる、という実用性が物理ファイルの形で担保されています。

### 設計判断 4: 「ベンチマーク成果物を git に同梱する」

論文の数字を裏付ける per-target 監査出力、ラベル、図表生成スクリプトが **すべてリポジトリ内** に入っています。これは学会コミュニティでの再現性を強く意識した判断で、「論文の主張がコミットの中身として確認できる」という性質を与えています。

---

## 2.9 章のまとめ

- SPECA リポジトリは **Python パイプライン本体**（`scripts/`＋`prompts/`＋`.claude/skills`）を中心に、**CLI**（`cli/`）、**サーバ**（`server/`）、**Web UI 設計**（`web/`）、**ベンチマーク**（`benchmarks/`）、**CI ワークフロー**（`.github/workflows/`）が衛星のように配置されている
- パイプライン本体は「ハーネス＋プロンプト＋スキーマ」の三層構造で、フェーズ追加コストが構造的に低い
- 周辺コンポーネントはすべて **Python パイプラインを書き直さず呼び出す** 方針で、責任分界が明確
- ベンチマーク成果物を git に同梱することで、論文の主張がコミットレベルで再現可能

次章では、6 フェーズそれぞれの動作を 1 つずつ詳細に追います。

---

## 2.10 参考文献

- README §「The Audit Harness」「Phases」
- `docs/SPECA_CLI_SPEC.md` §1.1「Build philosophy: reuse, don't reinvent」
- `web/WEB_APP_DESIGN.md`
- `benchmarks/README.md`
