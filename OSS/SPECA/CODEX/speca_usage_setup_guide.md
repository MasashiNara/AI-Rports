# SPECA ダウンロード・インストール・セットアップ手順

この手順書は、SPECA をローカル環境で動かすための基本手順をまとめたものです。対象は、Python パイプラインを直接実行する安定ルートです。

## 1. SPECA とは

SPECA は、仕様書を起点にして監査観点を作り、対象コードがその性質を満たしているかを検証する監査パイプラインです。

大まかな流れ:

1. 仕様書を探索する
2. 仕様を処理の流れと条件に分解する
3. セキュリティ上の性質を生成する
4. 性質に対応するコード位置を探す
5. 性質ごとに監査する
6. 候補脆弱性をレビューする

## 2. 前提環境

必要なもの:

- Python 3.11 以上
- `uv`
- Node.js 20 以上
- `git`
- Claude Code CLI
- Claude Code のログイン済みセッション、または `ANTHROPIC_API_KEY`

確認コマンド:

```bash
python3 --version
uv --version
node --version
git --version
claude --version
```

`uv` がない場合:

```bash
pip install uv
```

Claude Code CLI がない場合:

```bash
npm install -g @anthropic-ai/claude-code
```

Claude Code の認証確認:

```bash
claude auth status
```

API キーを使う場合:

```bash
export ANTHROPIC_API_KEY="your_api_key_here"
```

## 3. ダウンロード

新しく取得する場合:

```bash
git clone https://github.com/NyxFoundation/speca.git
cd speca
```

このワークスペースでは、すでに `speca/` ディレクトリがあるため、以下で作業します。

```bash
cd /mnt/projects/SPECA/speca
```

## 4. インストール

Python 依存関係をインストールします。

```bash
uv sync
```

開発用テストも使う場合は、このままで `pytest` も利用できます。

```bash
uv run python3 -m pytest tests/ -v --tb=short
```

## 5. MCP サーバーのセットアップ

SPECA は一部フェーズで MCP サーバーを使います。

登録:

```bash
bash scripts/setup_mcp.sh
```

確認:

```bash
bash scripts/setup_mcp.sh --verify
```

主に使われる MCP サーバー:

| MCP サーバー | 用途 |
|---|---|
| `fetch` | 仕様URLの取得 |
| `filesystem` | 仕様や出力ファイルの読み書き |
| `tree_sitter` | コード位置解決 |

## 6. 監査前に準備するファイル

本格的に監査を進める前に、`outputs/` 配下に2つのJSONを用意します。

```text
outputs/BUG_BOUNTY_SCOPE.json
outputs/TARGET_INFO.json
```

### 6.1 `outputs/BUG_BOUNTY_SCOPE.json`

Phase 01e と Phase 04 で使います。対象範囲、対象外、重大度基準などを定義します。

最小例:

```json
{
  "program_name": "Example Program",
  "program_url": "https://example.com/bug-bounty",
  "in_scope_components": [
    "consensus implementation",
    "p2p validation logic"
  ],
  "out_of_scope_components": [
    "test code",
    "documentation only"
  ],
  "scope_notes": [
    "Only externally reachable issues are in scope",
    "Trusted operator actions are out of scope"
  ],
  "severity_classification": {
    "CRITICAL": "Consensus split or loss of funds",
    "HIGH": "Remote denial of service or safety violation",
    "MEDIUM": "Limited impact security issue",
    "LOW": "Minor hardening issue"
  }
}
```

### 6.2 `outputs/TARGET_INFO.json`

Phase 02c、Phase 03、Phase 04 で使います。監査対象リポジトリとコミットを固定します。

最小例:

```json
{
  "target_repo": "https://github.com/example/project",
  "target_ref_type": "commit",
  "target_ref_label": "main",
  "target_commit": "0123456789abcdef0123456789abcdef01234567",
  "target_commit_short": "0123456"
}
```

最低限 `target_repo` は必要です。再現性のため、`target_commit` も固定することを推奨します。

## 7. まず単体フェーズで動作確認する

仕様探索だけを実行して、環境が動くか確認します。

```bash
SPEC_URLS="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7594.md" \
uv run python3 scripts/run_phase.py --phase 01a
```

出力例:

```text
outputs/01a_STATE.json
```

`SPEC_URLS` はカンマ区切りで複数指定できます。

```bash
SPEC_URLS="https://docs.example.com/spec1,https://docs.example.com/spec2" \
uv run python3 scripts/run_phase.py --phase 01a
```

キーワードを追加する場合:

```bash
KEYWORDS="ethereum,consensus,p2p" \
SPEC_URLS="https://ethereum.github.io/consensus-specs/" \
uv run python3 scripts/run_phase.py --phase 01a
```

## 8. フェーズ別に実行する

大きな監査では、各フェーズを分けて実行すると確認しやすくなります。

### Phase 01a: 仕様探索

```bash
SPEC_URLS="<仕様URL>" \
uv run python3 scripts/run_phase.py --phase 01a
```

主な出力:

```text
outputs/01a_STATE.json
```

### Phase 01b: サブグラフ抽出

```bash
uv run python3 scripts/run_phase.py --phase 01b --workers 4
```

主な出力:

```text
outputs/01b_PARTIAL_*.json
outputs/graphs/
```

### Phase 01e: セキュリティ性質生成

```bash
uv run python3 scripts/run_phase.py --phase 01e --workers 4
```

必要な入力:

```text
outputs/BUG_BOUNTY_SCOPE.json
```

主な出力:

```text
outputs/01e_PARTIAL_*.json
```

### Phase 02c: コード位置の事前解決

```bash
uv run python3 scripts/run_phase.py --phase 02c --workers 4 --max-concurrent 64
```

必要な入力:

```text
outputs/TARGET_INFO.json
```

主な出力:

```text
outputs/02c_PARTIAL_*.json
```

### Phase 03: 性質ごとの監査

```bash
uv run python3 scripts/run_phase.py --phase 03 --workers 4 --max-concurrent 64
```

主な出力:

```text
outputs/03_PARTIAL_*.json
```

### Phase 04: レビュー

```bash
uv run python3 scripts/run_phase.py --phase 04 --workers 4 --max-concurrent 64
```

主な出力:

```text
outputs/04_PARTIAL_*.json
```

## 9. まとめて実行する

Phase 04 まで一気に実行する場合:

```bash
uv run python3 scripts/run_phase.py --target 04 --workers 4 --max-concurrent 64
```

この実行前に、少なくとも以下を用意してください。

```text
outputs/BUG_BOUNTY_SCOPE.json
outputs/TARGET_INFO.json
```

## 10. 再実行・再開

SPECA は部分出力を保存するため、途中で失敗しても再開しやすい構成です。

通常の再開:

```bash
uv run python3 scripts/run_phase.py --phase 03 --workers 4 --max-concurrent 64
```

強制再実行:

```bash
uv run python3 scripts/run_phase.py --phase 03 --force --workers 4 --max-concurrent 64
```

未完了バッチの確認:

```bash
uv run python3 scripts/run_phase.py --phase 03 --cleanup-dry-run
```

## 11. 出力の見方

主な出力先:

```text
outputs/
```

代表的な出力:

| 出力 | 意味 |
|---|---|
| `01a_STATE.json` | 発見した仕様URLや仕様情報 |
| `01b_PARTIAL_*.json` | 仕様から抽出した処理構造 |
| `01e_PARTIAL_*.json` | 生成されたセキュリティ性質 |
| `02c_PARTIAL_*.json` | 性質に対応するコード位置 |
| `03_PARTIAL_*.json` | 性質ごとの監査結果 |
| `04_PARTIAL_*.json` | レビュー後の候補・判定 |

確認時の観点:

- どの仕様から来た性質か
- どのコードパスに対応しているか
- 証明がどこで崩れたか
- 攻撃シナリオが具体的か
- スコープ内か
- 人間のレビューで確認できるか

## 12. Web UI を使う場合

Web UI が必要な場合は、`web/` 配下を使います。

```bash
cd web
npm install
npm run dev
```

起動後、表示されたローカルURLをブラウザで開きます。

注意:

- Web UI は出力閲覧や操作補助用です
- パイプライン本体は `scripts/run_phase.py` で動きます

## 13. よくあるトラブル

### `claude` が見つからない

Claude Code CLI をインストールします。

```bash
npm install -g @anthropic-ai/claude-code
```

### Claude 認証で失敗する

Claude Code セッションを確認します。

```bash
claude auth status
```

または API キーを設定します。

```bash
export ANTHROPIC_API_KEY="your_api_key_here"
```

### MCP サーバーが見つからない

再登録して検証します。

```bash
bash scripts/setup_mcp.sh
bash scripts/setup_mcp.sh --verify
```

### Phase 01e が止まる

`outputs/BUG_BOUNTY_SCOPE.json` があるか確認します。

```bash
ls outputs/BUG_BOUNTY_SCOPE.json
```

### Phase 02c / 03 が止まる

`outputs/TARGET_INFO.json` があるか確認します。

```bash
ls outputs/TARGET_INFO.json
```

また、対象リポジトリとコミットが取得可能か確認します。

```bash
git ls-remote <target_repo_url>
```

### 途中で失敗した

まず同じフェーズを再実行します。

```bash
uv run python3 scripts/run_phase.py --phase <phase_id> --workers 4 --max-concurrent 64
```

状態を無視して再実行する場合:

```bash
uv run python3 scripts/run_phase.py --phase <phase_id> --force --workers 4 --max-concurrent 64
```

## 14. 最小実行まとめ

初回セットアップ:

```bash
git clone https://github.com/NyxFoundation/speca.git
cd speca
npm install -g @anthropic-ai/claude-code
uv sync
bash scripts/setup_mcp.sh
bash scripts/setup_mcp.sh --verify
```

仕様探索のスモークテスト:

```bash
SPEC_URLS="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7594.md" \
uv run python3 scripts/run_phase.py --phase 01a
```

本格実行:

```bash
# 先に outputs/BUG_BOUNTY_SCOPE.json と outputs/TARGET_INFO.json を作る
uv run python3 scripts/run_phase.py --target 04 --workers 4 --max-concurrent 64
```

テスト:

```bash
uv run python3 -m pytest tests/ -v --tb=short
```

