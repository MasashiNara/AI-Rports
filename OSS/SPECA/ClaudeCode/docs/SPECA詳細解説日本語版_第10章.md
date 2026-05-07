# SPECA 詳細解説（日本語版） — 第 10 章 CI/CD と運用

> 関連：[概略と目次](概略と目次.md) ／ [前：第 9 章 実績とベンチマーク](SPECA詳細解説日本語版_第9章.md) ／ [次：第 11 章 まとめと適用ガイド](SPECA詳細解説日本語版_第11章.md)

本章では SPECA の **運用面** — CI/CD ワークフロー、必須設定ファイル、環境変数、`outputs/` の規約を解説します。SPECA を実際にデプロイ・運用する際に必要な情報を集約します。

---

## 10.1 GitHub Actions ワークフロー一覧

SPECA リポジトリには **26 個** のワークフローファイル（`.github/workflows/*.yml`）があります。役割で分類すると次のとおりです。

### 10.1.1 監査パイプライン（フェーズ別）

| ファイル | 役割 |
|---|---|
| `01a-discovery.yml` | フェーズ 01a：仕様文書の発見 |
| `01b-subgraph.yml` | フェーズ 01b：サブグラフ抽出 |
| `01e-properties.yml` | フェーズ 01e：プロパティ生成 |
| `02c-enrich-code.yml` | フェーズ 02c：コード位置の事前解決 |
| `03-audit-map.yml` | フェーズ 03：監査マップ生成 |
| `04-audit-review.yml` | フェーズ 04：監査レビュー |
| `full-audit.yml` | エンドツーエンドのフル監査（01a → 04） |

各フェーズワークフローは **`workflow_dispatch`** トリガで個別起動できます。これにより：

- **フェーズ単位での再実行** が容易（プロンプトを変えて 03 だけ再実行など）
- **CI ジョブを途中まで進めて検証**してから次フェーズを起動、というワークフローが可能
- **コスト管理**：高コストフェーズ（03）だけ承認制にする運用ができる

### 10.1.2 ベンチマークワークフロー（RQ1）

| ファイル | 役割 |
|---|---|
| `benchmark-rq1-01-setup.yml` | 各監査ブランチのターゲットリポジトリをクローン |
| `benchmark-rq1-02-eval-recall.yml` | 再現率評価（issue マッチング） |
| `benchmark-rq1-03-eval-fp.yml` | 新規所見への FP ラベリング |
| `benchmark-rq1-035-collect-phase04.yml` | フェーズ 04 出力を集めて Phase 5→6 デルタを計算 |
| `benchmark-rq1-04-report.yml` | `evaluation_summary.md` とチャート生成 |

RQ1 は **5 ワークフローの直列実行** で完結します。

### 10.1.3 ベンチマークワークフロー（RQ2）

| ファイル | 役割 |
|---|---|
| `rq2a-01-setup-dataset.yml` | RepoAudit データセットを `target_workspace/` に展開 |
| `rq2a-02-visualize.yml` | ベースラインのみで可視化（API コスト 0） |
| `rq2a-03-audit-map.yml` | Sonnet 4.5 で監査（メイン構成） |
| `rq2a-03-audit-map-sonnet4.yml` | Sonnet 4 で監査 |
| `rq2a-03-audit-map-deepseek-r1.yml` | DeepSeek R1 で監査（マッチドバックボーン制御） |
| `rq2a-04-evaluate.yml` ／ `-sonnet4.yml` ／ `-deepseek-r1.yml` | モデル別評価 |
| `rq2b-01-setup-dataset.yml` | RQ2b（探索的）：ProFuzzBench セットアップ |
| `rq2b-02-visualize.yml` | RQ2b 可視化 |

### 10.1.4 補助ワークフロー

| ファイル | 役割 |
|---|---|
| `cli-ci.yml` | TypeScript CLI（`cli/`）のビルド・テスト |
| `issue-resolver.yml`／`openhands-resolver.yml`／`sweagent-issue-resolver.yml` | GitHub Issue 自動解決系（補助、本流ではない） |

---

## 10.2 監査ワークフローの典型構造

各監査ワークフローは似た構造を持っています。例として `03-audit-map.yml` の手順：

```yaml
on:
  workflow_dispatch:
    inputs:
      workers:        { default: 4,  type: number }
      max_concurrent: { default: 64, type: number }

permissions:
  contents: write

jobs:
  audit-map:
    if: ${{ github.actor == 'grandchildrice' || github.actor == 'hirorogo' }}
    runs-on: self-hosted   # ← ローカルランナで実行
    env:
      CLAUDE_CODE_PERMISSIONS: bypassPermissions
      CLAUDE_CODE_MAX_OUTPUT_TOKENS: 100000

    steps:
      - name: Checkout Branch
        uses: actions/checkout@v4
        with:
          ref: ${{ github.ref_name }}
          fetch-depth: 0

      - name: Update Scripts and Prompts from Remote
        run: |
          # 監査ブランチに残った古い scripts/ prompts/ を main から最新化
          git fetch --prune origin
          git checkout origin/${{ github.ref_name }} -- \
            scripts/ prompts/ .github/workflows/ .claude/

      - name: Load Target Info
        # outputs/TARGET_INFO.json を読み、対象を target_workspace/ にクローン

      - name: Install Claude Code CLI
        # npm install -g @anthropic-ai/claude-code

      - name: Setup MCP Servers
        # bash scripts/setup_mcp.sh

      - name: Run Phase
        # uv run python3 scripts/run_phase.py --phase 03 --workers ... --max-concurrent ...

      - name: Commit Audit Outputs
        # outputs/03_PARTIAL_*.json を当該ブランチへ commit

      - name: Upload Logs
        # outputs/logs/*.jsonl をアーティファクトとしてアップロード
```

### 重要な設計判断

#### 「アクターの allowlist」

```yaml
if: ${{ github.actor == 'grandchildrice' || github.actor == 'hirorogo' }}
```

ワークフローを起動できるユーザを **明示的に列挙** しています。OSS だけれども API 課金が発生するワークフローは、PR 経由で外部の人が誤って／意図的に起動できないように制限する必要があります。

#### `runs-on: self-hosted`

GitHub Hosted Runner ではなく **セルフホスト** ランナを使用。理由：

- 高コストフェーズの実行時間（Phase 03 で数分〜十数分）と並列度が GitHub Hosted の制限を超える
- API キーやリポジトリトークンを安全に注入できる
- ローカルキャッシュを活用してコスト削減

#### `CLAUDE_CODE_PERMISSIONS: bypassPermissions`

CI 環境では Claude Code の対話的な許可プロンプトを **すべてバイパス**。`Read`／`Write`／`Grep` 等のツール呼び出しを自動承認します。**ローカルでは決して使うべきでない** 設定です。

#### `CLAUDE_CODE_MAX_OUTPUT_TOKENS: 100000`

Claude の出力上限を **10 万トークン** に引き上げ。長大な監査トレースを切り捨てないため。

#### 「リモートから最新化」ステップ

```bash
git checkout origin/${branch} -- scripts/ prompts/ .github/workflows/ .claude/
```

これは興味深いパターンで、**監査ブランチには古いスクリプトが残っているかもしれないが、最新の `scripts/`／`prompts/` で実行する** ためのものです。コードと監査結果のバージョンを切り離す設計です。

#### Audit Branch 戦略

各クライアント／ターゲットに対して **専用 git ブランチ** を作り、そのブランチに：

- `outputs/TARGET_INFO.json`
- `outputs/BUG_BOUNTY_SCOPE.json`
- 各フェーズの PARTIAL ファイル
- ログ

を commit します。これにより：

- **監査結果が git 履歴として残る**：再現可能
- **複数ターゲットの並列監査** が ブランチで分離される
- **PR 化** して人間レビューに送れる

---

## 10.3 必須設定ファイル

SPECA を動かす前に **必須の 2 ファイル** があります。

### 10.3.1 `outputs/BUG_BOUNTY_SCOPE.json`（フェーズ 01e／04 が必須）

ターゲットの **信頼モデルと重要度ルーブリック** を定義します。フェーズ 01e はこれが無いと `sys.exit(1)` で停止します。

#### 最小構造

```json
{
  "in_scope":   { "components": ["..."], "scope_restriction": "..." },
  "out_of_scope": ["..."],
  "conditional_scope": ["..."],
  "trust_assumptions": {
    "p2p_input":        { "trust_level": "UNTRUSTED",    "rationale": "..." },
    "consensus_state":  { "trust_level": "TRUSTED",      "rationale": "..." },
    "rpc_input":        { "trust_level": "SEMI_TRUSTED", "rationale": "..." }
  },
  "severity_classification": {
    "CRITICAL": "Loss of funds / consensus split / mass DoS",
    "HIGH":     "...",
    "MEDIUM":   "...",
    "LOW":      "..."
  },
  "deployment_context": {
    "type": "multi-implementation",
    "target_share": { "value": 0.31, "metric": "validator-share" }
  }
}
```

#### フィールドの役割

| セクション | 用途 |
|---|---|
| `in_scope` | 監査対象のコンポーネント・スコープ制限 |
| `out_of_scope` | 監査対象外のカテゴリ（`Gate 3` でのドロップに使用） |
| `conditional_scope` | 条件付きスコープ |
| `trust_assumptions` | データソースごとの信頼レベル（`Gate 2` での判断に使用） |
| `severity_classification` | 重要度ごとの定義テキスト（フェーズ 01e／04 が参照） |
| `deployment_context.target_share` | 0〜1 の値。フェーズ 04 でのセベリティキャップに使用 |

#### `target_share` のセベリティキャップ

```
target_share.value = 0.31  # クライアントのバリデータシェア
```

シェアが特定閾値（例：33%）未満の単一クライアントバグは **重要度が一段階下がる** 仕組みです。「3 分の 1 未満のクライアントだけがバグっていてもチェイン全体は壊れない」というルーブリックを反映しています。

#### 標準テンプレート（speca-cli）

`speca-cli` の M2 ロードマップで、5 つの **テンプレート** が用意される予定です：

- `ethereum-consensus`
- `solana-validator`
- `evm-defi`
- `c-cpp-repo-audit`
- `generic`

各テンプレートに `severity_classification` と `trust_assumptions` のプリセットが含まれ、ユーザは差分のみを編集すれば良くなります。

### 10.3.2 `outputs/TARGET_INFO.json`（フェーズ 02c／03／04 が必須）

対象リポジトリと **固定コミット** を pin します。フェーズ 03 はこのファイルの内容で `git clone` します：

```json
{
  "name":     "go-ethereum",
  "repo":     "https://github.com/ethereum/go-ethereum",
  "commit":   "abc1234deadbeef...",
  "language": "go"
}
```

#### フィールド説明

| フィールド | 用途 |
|---|---|
| `name` | 識別名（`outputs/` の命名にも使用） |
| `repo` | git URL |
| `commit` | 固定コミットハッシュ。**監査の再現性を保証するため必須** |
| `language` | 主言語（02c が言語別の識別子変換ルールを切り替えるのに使用：例 Go なら `snake_case → PascalCase`） |

#### オプションフィールド（02c 用）

| フィールド | 用途 |
|---|---|
| `target_layer` | 機能レイヤ（"consensus"／"execution"／"l2-node"／"validator-runtime"） |
| `out_of_scope_spec_layers` | スコープ外の仕様レイヤリスト。例 execution クライアントなら `["consensus"]` 等 |

これにより、Ethereum execution クライアントを監査する時に、コンセンサス層の仕様プロパティを **早期に out_of_scope** にできます。

---

## 10.4 環境変数

### 10.4.1 認証

| 変数 | 用途 |
|---|---|
| `ANTHROPIC_API_KEY` | Claude API 直叩き時の認証。CI で必須 |

### 10.4.2 仕様クロール（フェーズ 01a）

| 変数 | 用途 |
|---|---|
| `SPEC_URLS` | カンマ区切りのシード URL |
| `KEYWORDS` | 任意のクロールキーワードフィルタ |

### 10.4.3 実行制御

| 変数 | 用途 |
|---|---|
| `FORCE_EXECUTE=1` | 再開ステートをバイパス（`--force` フラグで自動設定） |
| `SPECA_OUTPUT_DIR` | `outputs/` のルートディレクトリを変更（後述） |

### 10.4.4 CI 専用

| 変数 | 用途 |
|---|---|
| `CLAUDE_CODE_PERMISSIONS=bypassPermissions` | 対話的許可プロンプトをスキップ |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000` | 出力トークン上限を 10 万に引上げ |

### 10.4.5 オプション

| 変数 | 用途 |
|---|---|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub MCP サーバを使う場合 |
| `FILESYSTEM_DIRS` | `setup_mcp.sh` で filesystem MCP に渡すディレクトリ（既定 `.`） |

---

## 10.5 `outputs/` の規約と再開状態

### 10.5.1 標準レイアウト

```
outputs/
├── TARGET_INFO.json                     # ← 必須設定
├── BUG_BOUNTY_SCOPE.json                # ← 必須設定
├── 01a_STATE.json                       # フェーズ 01a 出力
├── 01b_PARTIAL_W*B*_*.json              # フェーズ 01b 部分結果
├── 01b_SUBGRAPH_INDEX.json              # 02c が生成する索引
├── 01e_PARTIAL_W*B*_*.json              # フェーズ 01e
├── 02c_PARTIAL_W*B*_*.json              # フェーズ 02c
├── 03_PARTIAL_W*B*_*.json               # フェーズ 03
├── 04_PARTIAL_W*B*_*.json               # フェーズ 04
├── graphs/                              # フェーズ 01b の .mmd ファイル
│   └── W{worker}B{batch}_{ts}/{spec}/
└── logs/
    └── {phase}_W{worker}B{batch}_{ts}.jsonl
```

### 10.5.2 命名規約

| パターン | 意味 |
|---|---|
| `outputs/{phase}_PARTIAL_W{worker}B{batch}_{timestamp}.json` | フェーズ部分結果 |
| `outputs/{phase}_QUEUE_{worker_id}.json` | ワーカ用キューファイル |
| `outputs/logs/{phase}_W{worker}B{batch}_{timestamp}.jsonl` | stream-json ログ |

各フェーズは上流フェーズの **`PARTIAL_*.json` を glob パターン** で消費します（例：02c は `outputs/01e_PARTIAL_*.json` を読む）。

### 10.5.3 `SPECA_OUTPUT_DIR` で位置を変更

`scripts/orchestrator/config.py` の `resolve_pattern()` ですべての `outputs/...` パスがランタイム解決されます：

```python
def resolve_pattern(pattern: str) -> str:
    if pattern.startswith("outputs/"):
        return str(get_output_root()) + pattern[7:]
    ...
```

`SPECA_OUTPUT_DIR=/tmp/my-audit/outputs` を設定すると、すべての `outputs/...` がそのパスに切り替わります。

これは：

- **CI 上で複数の監査を分離した場所に書く**
- **テストでは tmp ディレクトリに書く**
- **Web UI が `public/data/` から SPECA 実行結果を直接見たい**

といったケースで重要です。**新規コードでは絶対パスをハードコードせず、`get_output_root()` ／ `resolve_pattern()` を経由する** ことが CLAUDE.md にも明記されています。

### 10.5.4 PARTIAL ファイルが「再開状態」

第 5 章で扱った通り、SPECA は **専用の state ファイルを持たず**、`PARTIAL_*.json` 自体が再開ステートです：

```python
# 再開時：
processed_ids = set()
for partial_file in glob("outputs/{phase}_PARTIAL_*.json"):
    data = json.load(open(partial_file))
    # fast path
    if "metadata" in data and "processed_ids" in data["metadata"]:
        processed_ids.update(data["metadata"]["processed_ids"])
    # slow path
    else:
        for item in data.get(result_key, []):
            processed_ids.add(item[id_field])

# 残項目だけ処理
remaining = [item for item in all_items if item[id_field] not in processed_ids]
```

### 10.5.5 クリーンアップとドライラン

```bash
uv run python3 scripts/run_phase.py --phase 03 --cleanup-dry-run
```

これは「**不完全バッチ**」（途中で止まった結果ログだけ残って PARTIAL が無いもの）を検出し、削除候補を表示するドライランモード。`--cleanup` で実際に削除します。

---

## 10.6 トラブルシューティング指針

### 10.6.1 「フェーズ 01e が `sys.exit(1)` で止まる」

→ `outputs/BUG_BOUNTY_SCOPE.json` が無い／壊れている。最低限のフィールドを書いて再実行。

### 10.6.2 「フェーズ 03 が予算超過」

→ `PhaseConfig.max_budget_usd` を上げる（既定 200.0）。あるいは `--workers` を減らして並列度を下げる。

### 10.6.3 「ターン上限に達した」

→ 複雑なプロパティで 50 ターン上限に達することがある。`max_turns_per_batch` を増やすか、当該プロパティをスキップ。

### 10.6.4 「再開がうまくいかない」

→ PARTIAL ファイルが破損している可能性。`--cleanup-dry-run` で確認、必要なら `--force` で完全再実行。

### 10.6.5 「rate limit でサーキットブレーカが落ちる」

→ `--max-concurrent` を下げる。Anthropic の API レートリミット（10 RPM 等）に当たっている。

### 10.6.6 「02c で `not_found` が多すぎる」

→ ターゲットのソースコードが `target_workspace/` にクローンされているか確認。`TARGET_INFO.json` の commit が古すぎる場合もある。

---

## 10.7 ローカル実行 vs CI 実行

| 観点 | ローカル | CI（GitHub Actions） |
|---|---|---|
| 認証 | `ANTHROPIC_API_KEY` または `claude auth login` | `ANTHROPIC_API_KEY` シークレット |
| ランナ | ユーザのマシン | self-hosted（推奨） |
| 並列度 | `--workers 4 --max-concurrent 8` 等 | `--workers 4 --max-concurrent 64`（CI のほうが余裕） |
| ツール許可 | 対話プロンプトで都度承認 | `bypassPermissions` で一括承認 |
| 結果保存 | ローカル `outputs/` | audit ブランチへ commit、ログをアーティファクト化 |
| 通知 | TUI 内モーダル（speca-cli） | Discord Webhook（server/discord.py 経由） |

**論文発表級のフル監査は CI で**、開発・デバッグ・新規ターゲット試行は **ローカルで** が標準的な使い分けです。

---

## 10.8 章のまとめ

- **26 個** の GitHub Actions ワークフローがあり、フェーズ単位／ベンチマーク単位で `workflow_dispatch` 起動可能
- 各ワークフローは **アクターの allowlist** ＋ **self-hosted runner** ＋ **CI 専用環境変数** で構成
- 監査結果は **ブランチごと** に commit され、git 履歴に永続化
- 必須設定は 2 ファイル：**`BUG_BOUNTY_SCOPE.json`**（信頼モデル＋重要度）と **`TARGET_INFO.json`**（リポジトリ＋固定コミット）
- 環境変数は認証・仕様クロール・実行制御・CI 専用の 4 系統
- `outputs/` は **PARTIAL ファイル自体が再開状態** で、**`SPECA_OUTPUT_DIR`** で位置変更可能
- ローカル実行と CI 実行は補完関係：開発はローカル、本番監査は CI

次章では、ここまで扱ってきた SPECA の特徴を踏まえて、強み・限界・新規ターゲット適用ガイドをまとめます。

---

## 10.9 参考文献

- `.github/workflows/`（特に `full-audit.yml`、`03-audit-map.yml`、`benchmark-rq1-*.yml`、`rq2a-*.yml`）
- `scripts/run_phase.py`（CLI フラグ）
- `scripts/orchestrator/config.py`（`PhaseConfig` 全フィールド）
- `scripts/orchestrator/paths.py`（`SPECA_OUTPUT_DIR` 解決ロジック）
- README §「Configuration」「Environment Variables」「Running on GitHub Actions」
- `CLAUDE.md`（リポジトリ運用上の追加ガイド）
