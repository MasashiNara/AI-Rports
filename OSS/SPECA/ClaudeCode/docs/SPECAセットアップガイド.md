# SPECA セットアップガイド（Ubuntu 22.04 LTS 中心、ローカル実行版）

> 本ガイドは SPECA を **Ubuntu 22.04 LTS** 上にローカルセットアップして、`scripts/run_phase.py` でパイプラインを動かすところまでを案内する独立資料です。**Ubuntu 24.04 LTS** での差分は各章末に **「24.04 LTS の場合」** として付記しています。
>
> 関連：[概略と目次](概略と目次.md) ／ [LLM 選定ガイド](SPECA_LLM選定ガイド.md)
>
> 対象範囲：**ローカル実行のみ**。GitHub Actions CI 実行、`speca-cli`（M1 のみ実装）は本ガイドの対象外。

---

## 0. このガイドの構成

| パート | 内容 | 章 |
|---|---|---|
| **A. クイックスタート** | コマンド列を順に実行すれば動く | 第 1〜4 章 |
| **B. リファレンス** | 各コンポーネントの役割と設定値の意味 | 第 5〜10 章 |

エンジニアは A を上から流し、迷ったら B を辞書的に引く想定です。

> **重要事項（セキュリティ / プライバシー上の確認）**
> 本ガイドは、SPECA が **既定のローカル実行モードで Anthropic（Claude Code CLI 経由の inference）以外に外部送信しないこと** をリポジトリのコード上で確認した上で書かれています。詳細は **第 8 章「外部アクセスの実態と検証」** を参照してください。

---

# パート A. クイックスタート

# 第 1 章 動作要件

## 1.1 OS

- **Ubuntu 22.04 LTS**（本ガイドのメイン対象）
- **Ubuntu 24.04 LTS**（24.04 の場合の差分は章末に付記）
- 必要なら macOS（Apple Silicon / Intel）／WSL2 でも動作するが、本ガイドの対象外

## 1.2 必要なソフトウェア（最終形）

| ツール | バージョン | 用途 |
|---|---|---|
| Python | 3.11 以上 | パイプライン本体 |
| `uv` | 最新版 | Python パッケージ管理（`pip` の代替） |
| Node.js | 20 以上 | Claude Code CLI と一部 MCP サーバの実行環境 |
| `npm` | Node.js に付属 | パッケージ管理 |
| `git` | 任意 | 対象リポジトリの clone（フェーズ 03 で必要） |
| `@anthropic-ai/claude-code` | 最新版 | Anthropic 公式の **Claude Code CLI**。SPECA のワーカランタイム |
| `uvx`（`uv` に同梱） | — | MCP サーバを Python 製パッケージから即起動 |
| `npx`（npm に同梱） | — | MCP サーバを Node 製パッケージから即起動 |

## 1.3 必要なクレデンシャル

| 名前 | 必須／任意 | 用途 |
|---|---|---|
| **Anthropic API キー** または **Claude Code サブスクリプション認証** | **必須** | LLM inference。詳細は [LLM 選定ガイド](SPECA_LLM選定ガイド.md) |
| GitHub Personal Access Token | 任意 | GitHub MCP サーバを使う場合のみ。本ガイドのローカル実行では使わない |

## 1.4 ハードウェア要件（目安）

| リソース | 推奨 |
|---|---|
| メモリ | 8GB 以上（並列ワーカ数に応じて） |
| ディスク | 20GB 以上の空き（Python / Node 依存＋対象リポジトリ＋出力ログ） |
| ネットワーク | 安定したインターネット接続（Anthropic API・PyPI・npm へのアクセス） |
| GPU | **不要**（LLM inference は API 呼び出し） |

---

# 第 2 章 ベース環境のインストール

以下は新規 Ubuntu 22.04 LTS 環境を想定。各コマンドは **コピペで動く** よう書いています。

## 2.1 OS の更新と基本ツール

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential ca-certificates
```

> **24.04 LTS の場合**：同じコマンドで動作。差分なし。

## 2.2 Node.js 20.x のインストール

NodeSource の公式リポジトリを使います：

```bash
# NodeSource の Node.js 20.x セットアップスクリプト
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Node.js のインストール
sudo apt install -y nodejs

# 確認
node --version    # v20.x.x が表示される
npm --version     # 10.x.x 以上が表示される
```

> **24.04 LTS の場合**：22.04 LTS と同じコマンドで動作。
> ただし、24.04 LTS 標準リポジトリにも `nodejs` パッケージが入っており、`apt install nodejs` だけでも v18 が入ってしまう。本ガイドの NodeSource 経由なら明示的に v20 が入るので問題なし。

## 2.3 Python 3.11 以上の確認

Ubuntu 22.04 LTS の標準 Python は 3.10 のため、**3.11 を別途インストール** します：

```bash
# deadsnakes PPA を追加（22.04 標準には Python 3.11 が無いため）
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Python 3.11 のインストール
sudo apt install -y python3.11 python3.11-venv python3.11-dev

# 確認
python3.11 --version    # Python 3.11.x
```

> **24.04 LTS の場合**：標準 Python が **3.12** なので、PPA 不要。
>
> ```bash
> # 24.04 LTS 標準で十分（3.12 は >= 3.11 を満たす）
> sudo apt install -y python3 python3-venv python3-dev
> python3 --version   # Python 3.12.x
> ```
>
> 以後の手順で `python3.11` の代わりに `python3` を使ってください。`uv sync` は内部で `pyproject.toml` の `requires-python = ">=3.11"` を見て自動的に互換 Python を選びます。

## 2.4 `uv` のインストール

`uv` は Astral 社が提供する高速な Python パッケージマネージャです：

```bash
# 公式インストールスクリプト
curl -LsSf https://astral.sh/uv/install.sh | sh

# シェルを再起動するか PATH を反映
source $HOME/.local/bin/env   # uv が ~/.local/bin にインストールされる

# 確認
uv --version    # uv 0.x.x
uvx --version   # uvx 0.x.x（uv に付属）
```

> **24.04 LTS の場合**：差分なし。同じコマンドで動作。

## 2.5 Claude Code CLI のインストール

Anthropic 公式の `@anthropic-ai/claude-code` を **グローバル** にインストール：

```bash
sudo npm install -g @anthropic-ai/claude-code

# 確認
claude --version    # 2.x.x が表示される
```

> **権限警告**：`sudo npm install -g` は `/usr/lib/node_modules` に書き込みます。可能ならば `npm prefix` を `~/.npm-global` に変えて `sudo` 無しでインストールすることを推奨：
>
> ```bash
> mkdir -p ~/.npm-global
> npm config set prefix ~/.npm-global
> echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
> source ~/.bashrc
> npm install -g @anthropic-ai/claude-code   # sudo 不要
> ```

> **24.04 LTS の場合**：差分なし。

---

# 第 3 章 SPECA リポジトリのセットアップ

## 3.1 リポジトリのクローン

```bash
# 任意の作業ディレクトリへ
cd ~
git clone https://github.com/NyxFoundation/speca.git
cd speca
```

## 3.2 Python 依存のインストール

```bash
# pyproject.toml を読んで依存をインストールし、.venv を作成
uv sync
```

これで `~/speca/.venv/` 配下に：

- `aiofiles`、`fastapi`、`pydantic`、`tqdm`、`httpx`、`uvicorn[standard]`
- 開発用に `pytest`

がインストールされます（合計 60〜80 個程度のパッケージ）。

## 3.3 Claude Code の認証

ローカル実行で SPECA が Claude Code CLI を呼ぶ際、**認証情報は CLI 自体が管理** します。SPECA 側に API キーを書く必要はありません。

認証は次の **2 通り** から選びます。詳細・モデル選定は [LLM 選定ガイド](SPECA_LLM選定ガイド.md) を参照：

### 方法 A：Anthropic API キー（最もシンプル）

```bash
# Anthropic Console（console.anthropic.com）で作成した API キーをエクスポート
export ANTHROPIC_API_KEY="sk-ant-..."
# 永続化したい場合は ~/.bashrc に追記
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
```

### 方法 B：Claude Code サブスクリプションでログイン

```bash
# 対話的にブラウザログイン
claude

# 起動時にログインプロンプトが出る場合：
#   /login と入力
# Claude.ai でログインしてコードをコピーし、ターミナルに貼り付け
```

ログイン状態の確認：

```bash
claude /status
# Account Email や Login Method が表示されれば OK
```

> **24.04 LTS の場合**：差分なし。

## 3.4 MCP サーバの登録

SPECA は次のフェーズで **MCP サーバ** を介して外部ツールを呼びます：

| MCP サーバ | 使用フェーズ | 役割 |
|---|---|---|
| `fetch` | 01a, 01b | 仕様 URL の HTTP fetch（→ Markdown 変換） |
| `tree_sitter` | 02c | コードシンボル解析・AST クエリ |
| `filesystem` | 01b, 02c | ファイル書き込み（特に `.mmd` ファイル） |
| `serena`、`semgrep`、`github` | （補助） | スクリプトには登録されるがフェーズ 03/04 では未使用 |

```bash
# プロジェクトルートで実行
cd ~/speca
bash scripts/setup_mcp.sh

# 登録結果の確認
bash scripts/setup_mcp.sh --verify
```

実行内容：`claude mcp add` で各サーバを **`--scope project`**（このリポジトリ専用）として登録します。`uvx` ／ `npx` が初回起動時に MCP サーバを PyPI ／ npm から fetch（≈ 数十 MB）するため、初回は数分かかります。

> **重要：MCP `fetch` サーバについて**
> MCP `fetch` サーバはフェーズ 01a／01b で **ユーザが指定した URL（`SPEC_URLS`）** を取得するために使われます。任意の外部 URL にアクセスするので、社内ポリシー上問題が無いか確認してください。
>
> なお、フェーズ 02c／03／04 では MCP `fetch` は使われず、ローカル `target_workspace/` のみを参照します。

> **24.04 LTS の場合**：差分なし。`uvx` ／ `npx` の動作は同じ。

---

# 第 4 章 最初のラン（スモークテスト）

ここまでで前提が整いました。最小構成でフェーズ 01a を 1 回動かして、設定が正しいかを確認します。

## 4.1 出力ディレクトリの作成

```bash
cd ~/speca
mkdir -p outputs
```

## 4.2 フェーズ 01a だけ実行

```bash
# Ethereum EIP-7594 をシードに仕様クロール
SPEC_URLS="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7594.md" \
  uv run python3 scripts/run_phase.py --phase 01a
```

期待される動作：

1. `claude` が subprocess として起動
2. MCP `fetch` サーバが指定 URL の本文を取得
3. リンクを再帰的に辿って関連仕様を発見
4. `outputs/01a_STATE.json` に結果を書出
5. 標準出力に最後 5 行のサマリを表示

成功すると `outputs/01a_STATE.json` が作成され、中身は次のような JSON：

```json
{
  "start_url": "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7594.md",
  "found_specs": [
    { "url": "...", "title": "EIP-7594: PeerDAS - ...", "category": "EIP", ... },
    ...
  ],
  "metadata": { "total_specs": 28, ... }
}
```

## 4.3 トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| `claude: command not found` | Claude Code CLI 未インストール | §2.5 を再確認 |
| `uv: command not found` | `~/.local/bin` が PATH に無い | `source $HOME/.local/bin/env` |
| `Authentication failed` | API キー未設定または期限切れ | §3.3 を再確認 |
| `MCP server 'fetch' not found` | MCP サーバ未登録 | `bash scripts/setup_mcp.sh --verify` |
| `outputs/01a_STATE.json` が空 | 仕様 URL の指定ミスまたは fetch タイムアウト | URL を直接ブラウザで開いて 200 が返ることを確認 |
| 数十秒で終わってエラーも出ない | `--phase 01a` が依存 phase 無しで完了したケース。出力 JSON だけ確認 | `cat outputs/01a_STATE.json` |

ここまで成功すれば、ローカル環境は正常です。

---

# 第 5 章 エンドツーエンドラン（フル監査）

スモークテストが通ったら、実際の監査を回します。

## 5.1 必須ファイル 2 つの作成

エンドツーエンド実行には次の 2 ファイルが必須です：

### 5.1.1 `outputs/TARGET_INFO.json`

監査対象を pin します：

```bash
cat > outputs/TARGET_INFO.json << 'EOF'
{
  "name":     "go-ethereum",
  "repo":     "https://github.com/ethereum/go-ethereum",
  "commit":   "e8e9b8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8",
  "language": "go"
}
EOF
```

`commit` には実在するコミットハッシュ（短縮版でなく **フル SHA**）を入れます。最新の HEAD を取りたい場合：

```bash
COMMIT=$(git ls-remote https://github.com/ethereum/go-ethereum master | cut -f1)
# その値を JSON に入れる
```

### 5.1.2 `outputs/BUG_BOUNTY_SCOPE.json`

スコープと信頼モデルを定義します（最小例）：

```bash
cat > outputs/BUG_BOUNTY_SCOPE.json << 'EOF'
{
  "in_scope": {
    "components": ["core", "consensus", "p2p"],
    "scope_restriction": "ethereum execution layer only"
  },
  "out_of_scope": ["UI", "tests"],
  "conditional_scope": [],
  "trust_assumptions": {
    "p2p_input": {
      "trust_level": "UNTRUSTED",
      "rationale": "Anyone can send P2P messages"
    },
    "rpc_input": {
      "trust_level": "SEMI_TRUSTED",
      "rationale": "Authenticated but exposed"
    },
    "consensus_state": {
      "trust_level": "TRUSTED",
      "rationale": "Validated by consensus rules"
    }
  },
  "severity_classification": {
    "CRITICAL": "Loss of funds / consensus split / mass DoS",
    "HIGH":     "Affects network stability or significant resource",
    "MEDIUM":   "Affects single-client behavior",
    "LOW":      "Minor / informational"
  },
  "deployment_context": {
    "type": "single-implementation",
    "target_share": { "value": 0.5, "metric": "execution-share" }
  }
}
EOF
```

## 5.2 対象リポジトリのクローン

**ローカル実行ではユーザが手動でクローンします**。CI 上では `actions/checkout@v4` がやってくれますが、ローカルでは `target_workspace/` を自分で用意する必要があります：

```bash
# TARGET_INFO.json で指定した repo + commit を target_workspace/ に clone
git clone https://github.com/ethereum/go-ethereum target_workspace/
cd target_workspace
git checkout <full-sha>
cd ..
```

> **コード上の検証**：第 8 章 §8.3 で詳述しますが、SPECA の Python パイプラインは `target_workspace/` を **既存と仮定** して動きます。clone は実行しません。

## 5.3 フェーズ 04 まで通す

```bash
# フェーズ 04 をターゲットに、依存連鎖を自動解決
uv run python3 scripts/run_phase.py --target 04 --workers 2 --max-concurrent 8
```

`--workers 2 --max-concurrent 8` は控えめな設定。最初はこの値で動かして、API レートリミットに当たらないか・コストが想定内か確認してから上げてください。

実行時間とコストの目安（フェーズ 03 が支配的）：

| ターゲット規模 | 所要時間（フェーズ 03） | コスト（Sonnet 4.5） |
|---|---|---|
| 小（数千 LOC） | 数分 | $5〜15 |
| 中（数万 LOC） | 10〜20 分 | $30〜60 |
| 大（数十万 LOC） | 30〜60 分 | $60〜100 |

詳細は [LLM 選定ガイド](SPECA_LLM選定ガイド.md) §「コスト見積り」を参照。

## 5.4 実行が止まったら

途中で停止しても、PARTIAL ファイル群（`outputs/*_PARTIAL_*.json`）が残っていれば **同じコマンドで再開** できます：

```bash
# 同じコマンドを再実行 → 既処理は自動スキップ
uv run python3 scripts/run_phase.py --target 04 --workers 2 --max-concurrent 8
```

完全再実行したい場合は `--force` を付けます：

```bash
uv run python3 scripts/run_phase.py --phase 03 --force --workers 2 --max-concurrent 8
```

---

# パート B. リファレンス

# 第 6 章 各コンポーネントの役割と依存関係

## 6.1 全体像

```
┌──────────────────────────────────────────────────────────────────┐
│ ホスト OS（Ubuntu 22.04 / 24.04 LTS）                              │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ システムレベル                                             │    │
│  │  - apt 経由：python3.11、nodejs 20、git、curl              │    │
│  │  - Astral 公式：uv（~/.local/bin/uv）                      │    │
│  │  - npm グローバル：@anthropic-ai/claude-code              │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ ユーザレベル（~/speca）                                    │    │
│  │  - .venv/（uv が管理する Python 仮想環境）                 │    │
│  │  - outputs/（実行結果の永続化先）                          │    │
│  │  - target_workspace/（監査対象リポジトリのクローン）       │    │
│  │                                                            │    │
│  │  実行時に呼ばれる：                                        │    │
│  │   uv run python3 scripts/run_phase.py                      │    │
│  │     │                                                      │    │
│  │     ├── claude（subprocess）                              │    │
│  │     │     │                                                │    │
│  │     │     ├── Anthropic API（HTTPS）                      │    │
│  │     │     └── MCP servers（stdio）                        │    │
│  │     │            ├── uvx mcp-server-fetch                 │    │
│  │     │            ├── uvx mcp-server-tree-sitter           │    │
│  │     │            └── npx @modelcontextprotocol/server-fs  │    │
│  │     └── outputs/*.json への書き出し                        │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

## 6.2 ファイルシステム上の配置

| パス | 内容 |
|---|---|
| `/usr/bin/python3.11` | システム Python |
| `/usr/bin/node` | Node.js ランタイム |
| `~/.local/bin/uv`、`~/.local/bin/uvx` | uv／uvx |
| `/usr/lib/node_modules/@anthropic-ai/claude-code/` | Claude Code CLI |
| `~/.claude/` | Claude Code の設定・認証情報（API キーまたは OAuth トークン） |
| `~/.cache/uv/` | uv のパッケージキャッシュ |
| `~/.npm/`、`~/.npm-cache/` | npm のキャッシュ |
| `~/speca/.venv/` | SPECA 用の Python 仮想環境 |
| `~/speca/outputs/` | パイプラインの実行結果 |
| `~/speca/target_workspace/` | 監査対象リポジトリの clone（ユーザが用意） |

## 6.3 ストレージ消費の目安

| 項目 | サイズ |
|---|---|
| Python 依存（`.venv/`） | 200〜400 MB |
| Node 依存（Claude Code CLI） | 50〜80 MB |
| uvx で fetch される MCP サーバ群（初回のみ） | 100〜300 MB |
| Claude Code の cache | 数十 MB |
| 監査 1 ターゲットあたりの `outputs/` | 10〜500 MB（規模次第） |
| `target_workspace/` のクローン | 対象リポジトリ次第（go-ethereum で約 800 MB） |

合計で **2〜3 GB 程度** の空きを確保してください。

---

# 第 7 章 主要設定ファイル

## 7.1 `outputs/TARGET_INFO.json`（必須）

| フィールド | 必須 | 意味 |
|---|---|---|
| `name` | ○ | ターゲット識別名（出力命名等に使われる） |
| `repo` | ○ | git URL（HTTPS） |
| `commit` | ○ | フル SHA。**監査の再現性を保証** |
| `language` | ○ | 主言語：`rust` ／ `go` ／ `c` ／ `cpp` ／ `typescript` ／ `python` 等 |
| `target_layer` | △ | 機能レイヤ。例：`consensus` ／ `execution` |
| `out_of_scope_spec_layers` | △ | スコープ外レイヤのリスト。例：`["consensus"]` |

`target_layer` ／ `out_of_scope_spec_layers` を指定すると、フェーズ 02c が「ターゲットの責任範囲外のプロパティ」を **早期に out_of_scope** マークしてスキップできます。コスト削減効果あり。

## 7.2 `outputs/BUG_BOUNTY_SCOPE.json`（必須）

第 10 章「CI/CD と運用」と一部重複しますが、本ガイド完結のため再掲します：

### `in_scope`

```json
"in_scope": {
  "components": ["core", "consensus", ...],
  "scope_restriction": "<自由記述>"
}
```

### `out_of_scope`

```json
"out_of_scope": ["UI", "tests", "benchmarks"]
```

フェーズ 04 の Gate 3 で、ここに該当する所見は `DISPUTED_FP` 判定。

### `conditional_scope`

```json
"conditional_scope": ["network attacks requiring >50% stake", ...]
```

条件付きでスコープ内とする項目。

### `trust_assumptions`（フェーズ 04 で最重要）

```json
"trust_assumptions": {
  "<source_name>": {
    "trust_level": "UNTRUSTED" | "SEMI_TRUSTED" | "TRUSTED",
    "rationale": "<自由記述>"
  }
}
```

フェーズ 04 の **Gate 2** で：
- `TRUSTED` ／ `SEMI_TRUSTED` のみが攻撃経路 → `DISPUTED_FP`
- `UNTRUSTED` の経路が存在 → 通過

### `severity_classification`

```json
"severity_classification": {
  "CRITICAL": "<定義>",
  "HIGH":     "<定義>",
  "MEDIUM":   "<定義>",
  "LOW":      "<定義>"
}
```

フェーズ 01e の重要度割当、フェーズ 04 の重要度キャリブレーションで参照。

### `deployment_context`

```json
"deployment_context": {
  "type": "single-implementation" | "multi-implementation",
  "target_share": { "value": 0.31, "metric": "validator-share" }
}
```

`target_share.value` は 0〜1。フェーズ 04 で「単一実装バグの最大重要度」を上限する。例：シェア 5% で High → Medium に格下げ。

## 7.3 環境変数一覧（ローカル実行で関係するもの）

| 変数 | 必須 | 用途 |
|---|---|---|
| `ANTHROPIC_API_KEY` | （A 認証時） | API キー認証 |
| `SPEC_URLS` | フェーズ 01a 実行時 | カンマ区切りシード URL |
| `KEYWORDS` | 任意 | クロールキーワードフィルタ |
| `FORCE_EXECUTE=1` | — | 再開バイパス（`--force` で自動設定） |
| `SPECA_OUTPUT_DIR` | 任意 | `outputs/` のパスを変更（既定：`./outputs`） |
| `ORCHESTRATOR_RUNNER` | 任意 | `claude`（既定）または `api`（OpenRouter 経由）。**通常は設定しない** |
| `API_RUNNER_BASE_URL` | （上記が `api` の時） | OpenRouter 互換 API のベース URL |
| `API_RUNNER_API_KEY` | （上記が `api` の時） | 対応 API キー |
| `API_RUNNER_MODEL` | （上記が `api` の時） | モデル ID |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | 任意 | GitHub MCP サーバを使う場合 |
| `FILESYSTEM_DIRS` | 任意 | filesystem MCP に渡すディレクトリ（`setup_mcp.sh`、既定：`.`） |

ローカル実行では **基本的に `ANTHROPIC_API_KEY`（API 認証時）と `SPEC_URLS`（フェーズ 01a 実行時）** だけで十分です。

---

# 第 8 章 外部アクセスの実態と検証

ご質問の重要ポイント — **「Claude Code 以外の外部にアクセスしないか」** について、リポジトリのコードを実際に検証しました。

## 8.1 結論

> **既定のローカル実行モードで `scripts/run_phase.py` が起動した場合、`scripts/orchestrator/` は次の 4 種類の外部アクセス以外は行いません：**
>
> 1. **Anthropic API**（Claude Code CLI subprocess 経由）
> 2. **MCP `fetch` サーバ経由のユーザ指定 URL**（フェーズ 01a／01b のみ。`SPEC_URLS` で指定したもの）
> 3. **MCP サーバの初回 fetch**（uvx が PyPI、npx が npm からダウンロード。インストール時のみ）
> 4. **`uv sync` 時の PyPI**（インストール時のみ）

つまり、**inference は Anthropic のみ**。Discord、OpenRouter、GitHub などには **既定では送らない**。これは以下の検証で確認しました。

## 8.2 検証 1：HTTP/HTTPS 通信を行うコードのインベントリ

```bash
grep -rn "httpx\|requests\.get\|aiohttp" scripts/orchestrator/
```

検出されたファイル：

| ファイル | 用途 | 既定で動くか |
|---|---|---|
| `scripts/orchestrator/api_runner.py` | OpenRouter API への直接 inference | **No**（後述） |

**`api_runner.py` の起動条件**（`scripts/orchestrator/base.py` の 195〜215 行目を実コードで確認）：

```python
runner_type = os.environ.get("ORCHESTRATOR_RUNNER", "claude")
if runner_type == "api":
    self.runner = APIRunner(...)   # ← OpenRouter 経由
else:
    self.runner = ClaudeRunner(...) # ← Claude Code CLI 経由（既定）
```

つまり **`ORCHESTRATOR_RUNNER=api` を明示的に指定しない限り、`APIRunner` は構築すらされない**。既定の `ClaudeRunner` のみが起動し、Claude Code CLI subprocess を起動します。

## 8.3 検証 2：subprocess 経由の外部コマンド

```bash
grep -rn "subprocess\|Popen\|create_subprocess" scripts/orchestrator/
```

検出された外部コマンド呼び出し：

| 呼び出し元 | コマンド | 用途 |
|---|---|---|
| `runner.py:418` | `claude` CLI | LLM ワーカ起動（Anthropic アクセス） |
| `api_runner.py:208` | （外部 API ヘルパ） | `ORCHESTRATOR_RUNNER=api` 時のみ |

**`git clone` などのリポジトリ取得コマンドは Python パイプラインからは呼ばれていません**。`target_workspace/` はユーザ（またはローカル実行ではあなた、CI 上では `actions/checkout@v4`）が事前に用意する必要があります。これはコード上で確認できます。

## 8.4 検証 3：Discord Webhook の発火条件

`server/discord.py` には Discord Webhook URL がハードコードされていますが、これは **`server/` モジュール（FastAPI サーバ）経由のラン** でのみ呼ばれます。

```bash
grep -rn "send_phase_result\|discord" server/ scripts/
```

`server/orchestrator_bridge.py` がラン完了時に呼びます。**`scripts/run_phase.py` を直接実行するローカル実行経路では `server/` モジュールはロードされず、Discord 通知は送られません**。

## 8.5 検証 4：MCP `fetch` の挙動

`fetch` MCP サーバは **任意の URL を取得できる汎用ツール** ですが、SPECA のフェーズ別ツールフィルタ（`PhaseConfig.mcp_servers`）で次のようにスコープされています（`scripts/orchestrator/config.py`）：

| Phase | `mcp_servers` |
|---|---|
| 01a | `["fetch"]` |
| 01b | `["fetch", "filesystem"]` |
| 01e | `[]`（fetch 不可） |
| 02c | `["tree_sitter", "filesystem"]`（fetch 不可） |
| 03 | `[]`（fetch 不可） |
| 04 | `[]`（fetch 不可） |

**フェーズ 02c／03／04 は MCP `fetch` を使えないため、ターゲットコード解析中に予期せぬ URL アクセスは構造的に発生しません**。

## 8.6 検証 5：テレメトリ・analytics の有無

```bash
grep -rn "telemetry\|sentry\|posthog\|analytics\|mixpanel\|datadog" scripts/ server/
```

検出ヒット：**0 件**。SPECA はテレメトリを送りません。

## 8.7 既定モードでの外部アクセス図

```
[ローカルマシン]
  │
  │ ┌─ run_phase.py 起動 ─────┐
  │ │                          │
  │ │ ClaudeRunner             │ ─────HTTPS─────► [Anthropic API]
  │ │  └── claude CLI ─────────┤                  （inference）
  │ │                          │
  │ │ MCP fetch（01a/01b のみ）│ ─────HTTPS─────► [SPEC_URLS で指定した URL]
  │ │                          │
  │ │ MCP tree_sitter / fs     │ ──── ローカルのみ
  │ │                          │
  │ │ outputs/ への書き出し    │ ──── ローカルのみ
  │ └──────────────────────────┘
  │
  │ ※ Discord、OpenRouter、GitHub、テレメトリ：いずれも既定では発火しない
  └──────────────────────────────
```

## 8.8 注意点

「既定では」と限定しているのは、**次の場合に追加の外部アクセスが起きるため**です：

| 追加アクセス | 発火条件 |
|---|---|
| OpenRouter（inference） | `ORCHESTRATOR_RUNNER=api` を明示設定したとき |
| GitHub API | GitHub MCP サーバを使うとき（`setup_mcp.sh` で登録は試みるが、`GITHUB_PERSONAL_ACCESS_TOKEN` が無いと警告のみで動作しない。フェーズ 03/04 では使われない） |
| Discord | `server/` 経由のラン完了時（`uv run uvicorn server.app:app` 起動時のみ） |
| 任意の git ホスト | `target_workspace/` を **ユーザが** clone するときの一時的な git 通信 |
| PyPI / npm | 初回インストール時の `uv sync` ／ MCP サーバの初回起動時 |

つまり、**「`ANTHROPIC_API_KEY` を設定して `scripts/run_phase.py --phase 01a` を実行する」最小ケースでは、Anthropic ＋ ユーザ指定の仕様 URL 以外には繋がらない** ことがコード上で確認できます。

---

# 第 9 章 詳細な実行制御

## 9.1 `scripts/run_phase.py` の主要オプション

```bash
uv run python3 scripts/run_phase.py [OPTIONS]
```

| オプション | 既定 | 意味 |
|---|---|---|
| `--phase <id>` | — | 単一フェーズを実行（複数指定可） |
| `--target <id>` | — | 指定フェーズまでの依存連鎖を自動解決して全実行 |
| `--workers <n>` | 4 | ワーカ並列度 |
| `--max-concurrent <n>` | 8 | 同時 Claude 実行数 |
| `--force` | False | 再開ステートをバイパスして完全再実行 |
| `--cleanup-dry-run` | False | 不完全バッチの削除候補を表示（実削除はしない） |
| `--cleanup` | False | 不完全バッチを削除 |

### よく使うコマンド

```bash
# 単一フェーズ
uv run python3 scripts/run_phase.py --phase 01b

# 複数フェーズを順次実行
uv run python3 scripts/run_phase.py --phase 01a 01b 01e

# フェーズ 04 まで全部（依存解決）
uv run python3 scripts/run_phase.py --target 04 --workers 4

# 強制再実行（プロンプトを変更したとき等）
uv run python3 scripts/run_phase.py --phase 03 --force

# クリーンアップのドライラン
uv run python3 scripts/run_phase.py --phase 03 --cleanup-dry-run
```

## 9.2 並列度のチューニング

| 項目 | 影響 |
|---|---|
| `--workers` | キューを N 分割し、N 個のワーカで並列処理 |
| `--max-concurrent` | 同時に走る Claude プロセスの上限（asyncio セマフォ） |

経験則：

- **API レート制限を気にしない場合**：`--workers 4 --max-concurrent 32` 程度
- **Tier 1（既定）の API キー**：`--workers 2 --max-concurrent 4` から始める
- **Claude Code サブスクリプション認証**：レート制限が異なる。[LLM 選定ガイド](SPECA_LLM選定ガイド.md) §「サブスクリプション認証時のレート」を参照

## 9.3 予算上限の調整

各フェーズには `max_budget_usd` が設定されています（`scripts/orchestrator/config.py`）：

| Phase | 既定 |
|---|---|
| 02c | $20.0 |
| 03 | **$200.0** |
| 04 | $50.0（既定） |

予算超過時は `BudgetExceeded` 例外で停止します。引上げる場合は `config.py` の `PHASE_CONFIGS` を直接編集してください（環境変数は無し）。

---

# 第 10 章 アンインストール

## 10.1 SPECA のアンインストール

```bash
# プロジェクトディレクトリの削除
rm -rf ~/speca

# Claude Code に登録した MCP サーバの削除（プロジェクトスコープなので
# プロジェクトディレクトリの削除でも消えるが、明示的に削除する場合）
# （プロジェクトを開き直してから）
claude mcp list
claude mcp remove fetch
claude mcp remove tree_sitter
# … 他のサーバも同様
```

## 10.2 関連ツールのアンインストール（必要なら）

```bash
# Claude Code CLI
sudo npm uninstall -g @anthropic-ai/claude-code

# uv
rm -rf ~/.local/bin/uv ~/.local/bin/uvx ~/.cache/uv

# Node.js（NodeSource からインストールしたもの）
sudo apt remove -y nodejs
sudo rm /etc/apt/sources.list.d/nodesource.list

# Python 3.11（deadsnakes 経由）
sudo apt remove -y python3.11 python3.11-venv python3.11-dev
sudo add-apt-repository --remove ppa:deadsnakes/ppa
```

## 10.3 認証情報のクリーンアップ

```bash
# Claude Code CLI が保存した認証情報
rm -rf ~/.claude

# 環境変数（設定していた場合）
sed -i '/ANTHROPIC_API_KEY/d' ~/.bashrc
```

---

# 付録 A. よくあるトラブル一覧

| 症状 | 原因 | 対処 |
|---|---|---|
| `ModuleNotFoundError: No module named 'aiofiles'` | `uv sync` を実行していない | プロジェクトルートで `uv sync` |
| `claude` 実行で「Authentication required」 | 認証情報が無い／期限切れ | `claude /login` または `export ANTHROPIC_API_KEY=...` |
| Phase 01e で `sys.exit(1)` | `outputs/BUG_BOUNTY_SCOPE.json` が無い／JSON 不正 | §5.1.2 を再確認。`python3 -c "import json; json.load(open('outputs/BUG_BOUNTY_SCOPE.json'))"` で検証 |
| Phase 02c で `out_of_scope` ばかり | `target_workspace/` が空、または `language` フィールドが間違っている | §5.2 で clone を確認 |
| Phase 03 で「target_workspace/ not found」 | 対象リポジトリが clone されていない | §5.2 で clone |
| `BudgetExceeded` で停止 | `max_budget_usd` 超過 | `--workers` を下げる、または `config.py` で予算上限を上げる |
| サーキットブレーカで停止 | 連続失敗 | ログ（`outputs/logs/*.jsonl`）を確認。原因特定後 `--force` 不要、そのまま再実行で再開 |
| MCP server registration failed | `uvx` ／ `npx` が無いか PATH 通っていない | §2.4／§2.2 を再確認 |
| `npm install -g` で permission denied | `/usr/lib/node_modules` への書込み権限なし | §2.5 の prefix 変更で `~/.npm-global` を使う |
| `uv: command not found` | `~/.local/bin` が PATH に無い | `source $HOME/.local/bin/env` を実行、または `~/.bashrc` に追記 |
| Phase 03 が極端に遅い | 並列度・対象規模・モデル選択 | [LLM 選定ガイド](SPECA_LLM選定ガイド.md) §「実行時間の目安」 |

---

# 付録 B. Ubuntu 22.04 LTS と 24.04 LTS の差分まとめ

| 項目 | 22.04 LTS | 24.04 LTS |
|---|---|---|
| 標準 Python | 3.10 → 3.11 を deadsnakes PPA で追加 | 3.12（要件 ≥3.11 を満たす） |
| Node.js v20 取得 | NodeSource | NodeSource（標準でも v18 あり、v20 は NodeSource 経由推奨） |
| `uv` インストール | 公式スクリプト | 同左（差分なし） |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` | 同左 |
| `setup_mcp.sh` | 動作 | 同左 |
| `uv sync` | 動作 | 同左 |

**実質的な違いは Python 3.11 を別途入れるかどうかだけ**で、それ以外は同じ手順で動作します。

---

# 付録 C. 関連リンク

| リソース | URL |
|---|---|
| SPECA リポジトリ | https://github.com/NyxFoundation/speca |
| 論文 | https://arxiv.org/abs/2604.26495 |
| Claude Code CLI ドキュメント | https://docs.anthropic.com/en/docs/claude-code |
| `uv` ドキュメント | https://docs.astral.sh/uv/ |
| Anthropic Console（API キー作成） | https://console.anthropic.com/ |
| 第 10 章「CI/CD と運用」 | [SPECA詳細解説日本語版_第10章.md](SPECA詳細解説日本語版_第10章.md) |
| LLM 選定ガイド | [SPECA_LLM選定ガイド.md](SPECA_LLM選定ガイド.md) |
