# SPECA 詳細解説（日本語版） — 第 6 章 スキル・プロンプト・MCP

> 関連：[概略と目次](概略と目次.md) ／ [前：第 5 章 オーケストレータ詳細](SPECA詳細解説日本語版_第5章.md) ／ [次：第 7 章 CLI](SPECA詳細解説日本語版_第7章.md)

オーケストレータ（第 5 章）が「フェーズの動かし方」を提供するなら、本章で扱う **スキル／プロンプト／MCP サーバ** は「LLM ワーカが何をするか」を定義します。

3 者は次の役割分担です：

| 要素 | 役割 | 場所 |
|---|---|---|
| **スキル** | Claude Code が **再利用可能な手続き** として登録するもの。フォークされた別コンテキストで実行 | `.claude/skills/<name>/SKILL.md` |
| **プロンプト** | フェーズワーカが受け取る **指示文書**。スキルを呼ぶか、ロジックを直接インライン化 | `prompts/*.md` |
| **MCP サーバ** | Claude Code から **外部ツール**（fetch、tree_sitter、filesystem）を呼ぶためのプロトコル | 外部プロセス（uvx／npx で起動） |

---

## 6.1 Claude Code のスキル機構

### 6.1.1 スキルとは何か

Claude Code の **スキル** は、`.claude/skills/<name>/SKILL.md` という Markdown ファイルで定義される **再利用可能な手続き** です。

スキルファイルは YAML フロントマターで以下を宣言します：

| フィールド | 意味 |
|---|---|
| `name` | スキル名（`/<name>` で呼び出せるようになる） |
| `description` | スキルの説明 |
| `allowed-tools` | スキルが使ってよいツールのホワイトリスト |
| `context: fork` | **別コンテキスト** で実行（呼び出し元の履歴を持ち込まない） |

「`context: fork`」が重要で、スキルが呼ばれるたびに **クリーンな会話履歴で動作** します。これにより、同じスキルを複数回呼び出しても挙動が安定します。

### 6.1.2 スキルとプロンプトの違い

| 観点 | スキル | プロンプト |
|---|---|---|
| 呼び出し方 | `/<name>` で呼ぶ | ワーカに直接渡す（`--prompt-path`） |
| コンテキスト | 別コンテキスト（fork） | ワーカ本体と同じコンテキスト |
| ツールアクセス | `allowed-tools` で限定 | ワーカの `tools_filter` に従う |
| 何度呼べるか | 何度でも | 1 ワーカ＝ 1 プロンプト |

### 6.1.3 スキルを使うか、インライン化するか

SPECA はこの選択を **フェーズごとに使い分けて** います：

| Phase | 形式 | 理由 |
|---|---|---|
| `01a` | スキル `/spec-discovery` | 仕様クロールという独立した手続き／何度呼んでも安定 |
| `01b` | スキル `/subgraph-extractor` | 1 仕様 = 1 スキル呼び出しで処理単位がきれい |
| `01e` | **インライン** | 信頼モデル分析と STRIDE 推論を **同じコンテキスト** で連続実行したいため |
| `02c` | **インライン** | バッチごとのリポジトリオリエンテーションを 1 回で済ませたいため |
| `03` | **インライン** | 3 サブフェーズを 1 つのワーカ内で連続させて文脈を保ちたいため |
| `04` | **インライン** | 3 ゲートを 1 ワーカ内で順次実行 |

> **要点**：スキルは「独立した・繰り返し呼ばれる」処理に向く。**「フェーズ内の連続的な推論」はインライン化** することで、コンテキストフォークのオーバーヘッドを避ける、というのが SPECA の判断です。

---

## 6.2 SPECA で使用しているスキル

現在のリポジトリには 2 つのスキルだけが残っています（フェーズ 01a／01b 用）。

### 6.2.1 `/spec-discovery`（フェーズ 01a 用）

**ファイル**：`.claude/skills/spec-discovery/SKILL.md`

```yaml
---
name: spec-discovery
description: Crawl and discover specification documents from a given URL.
allowed-tools: mcp__fetch__fetch, browser_navigate, browser_scroll, browser_click, browser_view, write
context: fork
---
```

**マインドセット**：「綿密な Web Researcher。シード URL から関連する技術仕様文書を網羅的に発見せよ」。

**手続き**：

1. **初回 fetch**：`mcp__fetch__fetch` でシード URL の本文を Markdown として取得
2. **リンク抽出**：「Specification」「Whitepaper」「Yellow Paper」「Architecture」「Protocol」「Technical Details」「Docs」などのキーワードに合致するリンクを抽出
3. **再帰的 fetch**：見つかったリンクを **2〜3 階層まで** 再帰的に辿る
4. **ブラウザフォールバック**：`mcp__fetch__fetch` が失敗（403／空レスポンス／JS 要必須）した場合のみ、`browser_*` ツールにフォールバック
5. **収集と重複排除**：仕様らしき URL を集めて重複排除
6. **JSON 出力**：

```json
{
  "found_specs": [
    {"url": "...", "title": "...", "category": "EIP|consensus-specs|...", ...}
  ]
}
```

**設計判断**：

- **`mcp__fetch__fetch` を主、ブラウザを副**：Markdown を直接返す `fetch` は LLM にとって読みやすく、トークン効率も良い。ブラウザは JS-rendered ページのフォールバック専用
- **再帰深さの上限**：2〜3 階層に制限し、無限クロールを防ぐ
- **ホワイトリスト型キーワード**：「仕様らしさ」を判定する明示的キーワードで誤検出を抑制

### 6.2.2 `/subgraph-extractor`（フェーズ 01b 用）

**ファイル**：`.claude/skills/subgraph-extractor/SKILL.md`

```yaml
---
name: subgraph-extractor
description: Extract program graphs from a single specification document following Nielson & Nielson's formal definition.
allowed-tools: read, write, mcp__fetch__fetch, mcp__filesystem__write_text_file,
               mcp__tree_sitter__get_symbols, mcp__tree_sitter__run_query
context: fork
---
```

**マインドセット**：「Formal Methods Specialist。Nielson & Nielson のプログラムグラフ定義に従って、単一仕様文書を変換せよ」。

**スコープ**：1 呼び出し = 1 仕様 URL。1 仕様から複数のプログラムグラフ（手続きごとに 1 つ）が生まれることが多い。

**手続き**：

1. **仕様文書の読み込み**：`local_path` があればそこから、なければ `url` を `mcp__fetch__fetch` で取得
2. **機能単位の識別**：
   - 関数定義
   - 状態遷移記述
   - プロトコルフェーズ
   - バリデーションフロー
3. 各機能単位を **プログラムグラフ** に変換
4. **拡張版 Mermaid 形式** で出力：YAML フロントマター（タイトル・参照仕様・ID）＋ `stateDiagram-v2` 本体 ＋ `note right of` ブロックの不変条件
5. **PARTIAL JSON** にファイルへのポインタを集約

**設計判断**：

- **「呼び出し元がバッチング・集約を担う」**：このスキルは 1 つの URL だけを扱い、フェーズ 01b ワーカが複数 URL に対して反復呼び出しする
- **拡張版 Mermaid（YAML frontmatter + invariant notes）**：標準 Mermaid に「メタ情報層」を足したもの。グラフ構造（機械処理向け）と仕様要件（人間／後段 LLM 向け）を分離

---

## 6.3 「インライン化」されたプロンプト群

第 3 章で個別に詳述しましたが、フェーズ 01e／02c／03／04 はスキルではなく、**ワーカプロンプトの中に直接ロジックを埋め込んで** 動作します。

### 6.3.1 インライン化のメリット

| メリット | 説明 |
|---|---|
| **コンテキストフォーク無し** | スキル呼び出しごとに別コンテキストを開かない |
| **キャッシュ効率の向上** | 同じプロンプト本体を複数バッチで使い回せる（プロンプトキャッシュが効く） |
| **連続的推論の保持** | サブフェーズ間で「直前の理解」がそのまま残る |
| **デバッグ容易** | プロンプト 1 ファイルで挙動が決まる |

### 6.3.2 インライン化のデメリット（と対処）

| デメリット | 対処 |
|---|---|
| プロンプトが長大化 | XML タグ（`<task>`, `<phase_a>`, `<phase_b>`...）で構造化 |
| 異なるフェーズでロジック重複 | フェーズが本質的に異なる処理を行うため、共通化のメリットが薄い |
| 変更が大きな影響を与える | スキーマ（`schemas.py`）と一緒に変更することを CONTRIBUTING で明記 |

### 6.3.3 プロンプトの構造化

各インラインプロンプトには共通の構造があります：

```xml
<task>
  <goal>...</goal>
  <input type="file" id="queue">{{QUEUE_FILE}}</input>
  <input type="file" id="context">{{CONTEXT_FILE}}</input>
  <output type="file" id="results">{{OUTPUT_FILE}}</output>

  <critical_requirements>
    1. ...
    2. ...
  </critical_requirements>

  <mindset>
    You are a [role]. ...
  </mindset>

  <instructions>
    1. ...
    2. ...
  </instructions>

  <phase_a title="...">...</phase_a>
  <phase_b title="...">...</phase_b>

  <output>
    <format>JSON</format>
    <stdout>...</stdout>
    <final_line>Output File: {{OUTPUT_FILE}}</final_line>
  </output>
</task>
```

`<critical_requirements>` ブロックには **「これを守らないと致命的エラー」** という強制ルールが書かれます。例：

> "FAILURE TO WRITE THE JSON FILE IS A CRITICAL ERROR."

これは LLM が「ちょっと省略しよう」と判断するのを防ぐための明文化です。

---

## 6.4 MCP サーバ（Model Context Protocol）

### 6.4.1 MCP とは

**MCP（Model Context Protocol）** は、Claude Code から **外部ツール** を呼び出すためのプロトコルです。各 MCP サーバは独立したプロセスで動作し、Claude Code が `stdio` 経由で対話します。

### 6.4.2 SPECA で使う 3 つの MCP サーバ

`scripts/setup_mcp.sh` で登録される 3 つ：

| MCP サーバ | コマンド | 使用フェーズ | 用途 |
|---|---|---|---|
| `tree_sitter` | `uvx mcp-server-tree-sitter` | 02c | コードシンボル解析（`get_symbols`、`run_query`） |
| `filesystem` | `npx -y @modelcontextprotocol/server-filesystem` | 01b、02c | ファイル書き込み（特に `.mmd` ファイル） |
| `fetch` | `uvx mcp-server-fetch` | 01a | URL → Markdown 変換取得 |

### 6.4.3 登録コマンド

`setup_mcp.sh` は内部で次のような `claude mcp add` を実行します：

```bash
claude mcp add --scope project --transport stdio \
  fetch -- uvx mcp-server-fetch

claude mcp add --scope project --transport stdio \
  tree_sitter -- uvx mcp-server-tree-sitter

claude mcp add --scope project --transport stdio \
  filesystem -- npx -y @modelcontextprotocol/server-filesystem ${FILESYSTEM_DIRS}
```

### 6.4.4 フェーズ 03／04 が MCP を使わない理由

フェーズ 03（監査）と 04（レビュー）は MCP サーバを **一切使いません**。`tools_filter=["Read", "Write", "Grep", "Glob"]` という形で **Claude Code 組込みツールのみ** に限定されています。

理由：

1. **再現性**：MCP サーバはバージョン依存があり、`tree_sitter` のシンボル解析結果は将来的に変わる可能性がある。組込み Read/Grep/Glob は Claude Code 自体が保証する
2. **コンテキスト軽量化**：MCP のレスポンスは `tool_result` ブロックとして履歴に残る。重い結果が累積するとコンテキストを圧迫する
3. **バッチサイズ 1 との整合**：1 プロパティを丁寧に検証するフェーズで、複雑な MCP 状態遷移は不要

### 6.4.5 02c が MCP を使う理由

逆に、02c は `tree_sitter` を **積極的に使います**：

```python
# 02c の典型的なツール呼び出しパターン
mcp__tree_sitter__get_symbols(path="beacon-chain/")
  → 利用可能なシンボル一覧を取得
mcp__tree_sitter__run_query(query="(function_declaration name: (identifier) @name)")
  → AST クエリで定義位置を特定
```

これにより、Grep ベースの「文字列検索」より精度の高い **構文解析ベースの位置解決** が可能になります。`grep_fallback` は文字列検索の保険です。

### 6.4.6 MCP の追加例（GitHub MCP）

`setup_mcp.sh` には **GitHub MCP サーバ** の登録もコメントアウトで残っています（過去に Phase 02 が使用）：

```bash
# Phase 02 (checklist-specialist) -> github
claude mcp add --scope project --transport stdio \
  --env "GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN" \
  github -- npx -y @modelcontextprotocol/server-github
```

新規ターゲットで GitHub Issue を読みながら監査したい等のユースケースで再有効化できます。

---

## 6.5 プロンプト・スキル・MCP の協調動作

ある 1 つのフェーズ実行で 3 者がどう協調するか、フェーズ 02c を例に：

```
[ワーカ起動]
  ↓
ClaudeRunner が claude CLI を起動
  --prompt-path prompts/02c_codelocation_worker.md
  --mcp-servers tree_sitter,filesystem
  --tools Read,Write,Grep,Glob,mcp__tree_sitter__*,mcp__filesystem__*
  ↓
ワーカコンテキスト（Sonnet）
  ├── プロンプトを受け取り（インライン化されているのでスキル無し）
  ├── outputs/TARGET_INFO.json を Read
  ├── outputs/01b_SUBGRAPH_INDEX.json を Read
  ├── target_workspace/*/ を Glob
  ├── プロパティごとに：
  │     ├── Grep（文字列検索）
  │     ├── mcp__tree_sitter__get_symbols（構文解析）
  │     └── mcp__tree_sitter__run_query（AST クエリ）
  └── 結果を outputs/02c_PARTIAL_W{w}B{b}_*.json に Write
```

### スキルが使われる場合（フェーズ 01b）

```
[ワーカ起動]
  ↓
ClaudeRunner が claude CLI を起動
  --prompt-path prompts/01b_extract_worker.md
  ↓
ワーカコンテキスト（Opus）
  ├── プロンプトを受け取る
  └── バッチ内の URL ごとに：
       └── /subgraph-extractor を呼ぶ
              ↓
              [スキルコンテキスト（fork）]
              ├── url を取得（mcp__fetch__fetch）
              ├── プログラムグラフを抽出
              ├── .mmd を mcp__filesystem__write_text_file で書き出し
              └── JSON を返す
              ↑
       ← 戻る
       
  └── 集約結果を outputs/01b_PARTIAL_*.json に Write
```

スキル呼び出しごとに **クリーンな会話履歴** で動作するのが見えます。

---

## 6.6 `tools_filter` と `mcp_servers` の関係

`PhaseConfig` には 2 つの関連フィールドがあります：

```python
mcp_servers=["tree_sitter", "filesystem"]   # MCP サーバの登録
tools_filter=["Read", "Write", "Grep", "Glob"]  # 組込みツールのフィルタ
```

両者の効果：

| 設定 | 結果 |
|---|---|
| `mcp_servers=[]`、`tools_filter=なし` | 組込みツールすべて利用可、MCP なし |
| `mcp_servers=["tree_sitter"]`、`tools_filter=なし` | 組込みツールすべて＋ tree_sitter |
| `mcp_servers=[]`、`tools_filter=["Read","Grep"]` | Read／Grep のみ |
| `mcp_servers=["tree_sitter"]`、`tools_filter=["Read","Grep"]` | Read／Grep + tree_sitter MCP |

### フェーズ別の典型構成

| Phase | mcp_servers | tools_filter | 意図 |
|---|---|---|---|
| `01a` | `["fetch"]` | （標準） | クロール |
| `01b` | `["fetch", "filesystem"]` | （標準） | 仕様取得＋`.mmd` 書込み |
| `01e` | `[]` | （標準） | コードを見ないので最小構成 |
| `02c` | `["tree_sitter", "filesystem"]` | （標準） | コード位置解析 |
| `03` | `[]` | `["Read","Write","Grep","Glob"]` | **再現性最優先** |
| `04` | `[]` | `["Read","Write","Grep","Glob"]` | 同上 |

---

## 6.7 章のまとめ

- **スキル**は再利用可能な独立手続き、**プロンプト**はフェーズワーカの指示文書、**MCP** は外部ツールアクセス。3 者の役割分担が明確
- SPECA はフェーズの性質に応じて **スキル形式** と **インライン形式** を使い分けている
  - 01a／01b は独立した手続きなのでスキル
  - 01e／02c／03／04 は連続的推論を保ちたいのでインライン
- インラインプロンプトは XML タグで構造化され、`<critical_requirements>` で LLM の省略を防ぐ
- MCP サーバは 3 種類（fetch／tree_sitter／filesystem）。**フェーズ 03／04 はあえて MCP を使わない**（再現性とコンテキスト軽量化）
- `tools_filter` と `mcp_servers` の組み合わせで、フェーズごとの **ツールアクセス境界** を厳密に管理

次章では、ここまでの「Python 中心」の世界からターミナルフロントエンドに視点を移し、TypeScript で書かれた CLI（speca-cli）を解説します。

---

## 6.8 参考文献

- `.claude/skills/spec-discovery/SKILL.md`
- `.claude/skills/subgraph-extractor/SKILL.md`
- `prompts/*.md`（特に `01e_prop_worker.md`、`02c_codelocation_worker.md`、`03_auditmap_worker_inline.md`、`04_review_worker.md`）
- `scripts/setup_mcp.sh`
- `scripts/orchestrator/config.py`（`PhaseConfig.mcp_servers`、`tools_filter`）
- README §「MCP Servers」
