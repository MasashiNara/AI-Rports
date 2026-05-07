# SPECA 詳細解説（日本語版） — 第 5 章 オーケストレータ詳細

> 関連：[概略と目次](概略と目次.md) ／ [前：第 4 章 マニュアルフェーズ](SPECA詳細解説日本語版_第4章.md) ／ [次：第 6 章 スキル・プロンプト・MCP](SPECA詳細解説日本語版_第6章.md)

第 3 章で扱った 6 つのフェーズを **動かしている** のがオーケストレータ（`scripts/orchestrator/`）です。本章では、その内部構造と「なぜそうなっているか」を解説します。

論文では監査ハーネス（Audit Harness）と呼ばれており、**フェーズの追加・並列ワーカ管理・トークン制御・再開・予算強制** を、新しいフェーズコードを書かずに享受できる設計になっています。

---

## 5.1 全体アーキテクチャ

オーケストレータの依存関係：

```
                    BaseOrchestrator (abstract)
                           │
                           │ uses
        ┌──────────────────┼──────────────────────┐
        │                  │                      │
        ▼                  ▼                      ▼
   PhaseConfig        ClaudeRunner           ResultCollector
   (Pydantic)              │                      │
        │                  │                      │
   PHASE_CONFIGS           ├── CircuitBreaker    └── Pydantic schemas
                           ├── LogAnomalyDetector       (cross-phase contracts)
                           ├── LogWatcher
                           └── CostTracker
                                  │
                                  └── BudgetExceeded
                                  
        QueueManager           BatchStrategy            ResumeManager
        (split queues          (TokenBased /            (scan PARTIALs
         per worker)            CountBased /             for processed_ids)
                                Hybrid)
```

クラス階層：

```
BaseOrchestrator (abstract)
├── Phase01Orchestrator    # 01a / 01b / 01e
├── Phase02cOrchestrator
├── Phase03Orchestrator
└── Phase04Orchestrator
```

ファイル別の責務：

| ファイル | 行数（参考） | 責務 |
|---|---|---|
| `base.py` | 1266 | 抽象基底＋4 つの具象クラス |
| `runner.py` | 1080 | Claude CLI 呼び出し＋サーキットブレーカ＋ログ異常検知 |
| `watchdog.py` | 633 | リアルタイムログ監視＋コスト追跡＋予算強制 |
| `schemas.py` | 689 | フェーズ間データ契約（Pydantic） |
| `resume.py` | 315 | 再開管理（PARTIAL ファイル走査） |
| `config.py` | 300 | `PhaseConfig` と `PHASE_CONFIGS` |
| `collector.py` | 194 | 結果コレクタ（PARTIAL JSON 書き出し） |
| `batch.py` | 181 | バッチ戦略 |
| `queue.py` | 64 | キュー分割（ワーカごと） |
| `paths.py` | 19 | `outputs/` ルート解決（`SPECA_OUTPUT_DIR` 対応） |
| `factory.py` | 47 | `create_orchestrator(phase_id, ...)` |
| `api_runner.py` | 698 | API 直叩き版ランナ（CLI 経由でない代替経路） |

---

## 5.2 `BaseOrchestrator` のライフサイクル

`BaseOrchestrator.run()` の標準的な処理ステップ：

```
1. 入力ファイルの読み込み（input_patterns で glob）
        │
        ▼
2. Pydantic スキーマで検証（warning だけ、ブロックしない）
        │
        ▼
3. ResumeManager で「処理済み ID」を抽出して残項目をフィルタ
        │
        ▼
4. （フェーズ固有）コンテキスト付与（trust assumption の併合等）
        │
        ▼
5. BatchStrategy でバッチ生成
        │
        ▼
6. QueueManager でワーカごとにキュー分割（{phase}_QUEUE_{worker}.json）
        │
        ▼
7. asyncio タスクで並列ワーカ起動
        │  （ワーカごとに max_concurrent でセマフォ制限）
        ▼
8. ClaudeRunner.run() を各バッチで呼び出し
        │  ├── stream-json ログをリアルタイム解析（LogWatcher）
        │  ├── ターン消費・トークン使用量を記録（CostTracker）
        │  └── 異常検知でリトライ／回路ブレーカ
        ▼
9. ResultCollector が PARTIAL JSON を即時保存
        │
        ▼
10. 全バッチ終了後、サーキットブレーカ統計とコスト合計を表示
```

### 重要：「lenient validation」原則

ステップ 2 と 9 の Pydantic 検証は **エラーで停止せず、stderr に warning を出すだけ** です。

```python
def _log_validation_warning(filepath, ve, *, prefix=""):
    print(f"⚠️  Schema validation warning for {filepath}: {ve.error_count()} error(s)",
          file=sys.stderr)
    for err in ve.errors():
        print(f"    {err['loc']}: {err['msg']}", file=sys.stderr)
```

理由：**部分結果を残すことが最優先**。1 件のスキーマ不一致で 99 件の正常な結果まで失われると、再開コストが大きすぎるため。

---

## 5.3 バッチ戦略

`BatchStrategy` の実装は 4 種類（`batch.py`）：

| 戦略 | 用途 |
|---|---|
| `TokenBasedBatch` | 「合計トークン数」が `max_tokens`（既定 190K）に収まるよう分割 |
| `CountBasedBatch` | 単純な件数分割（既定 10／フェーズ 03/04 では 1） |
| `ByteBasedBatch` | 参照ファイルのバイト数で分割（`subgraph_file` 等の外部ファイルがあるとき） |
| `HybridBatch` | 上記 3 つを組み合わせて「最も制約的な結果」を採用 |

### TokenBasedBatch のトークン推定

```python
def estimate_tokens(self, text: str) -> int:
    return len(text) // 4
```

**4 文字 ≒ 1 トークン** という古典的な近似。`json.dumps(item)` した結果に対してこれを適用します。Claude のコンテキストウィンドウに対し **`base_tokens=5000` をプロンプト本体・指示部のオーバーヘッド** として確保した上で、残り `max_tokens - base_tokens` にバッチ内アイテムが収まるよう構築します。

### フェーズ別の選択

| Phase | strategy | max_size／max_tokens |
|---|---|---|
| `01a` | count | 1（初期フェーズ） |
| `01b` | count | 2 |
| `01e` | count | 1 |
| `02c` | count | 50 |
| `03` | count | **1**（プロパティ間文脈混入回避） |
| `04` | count | **1** |

フェーズ 03／04 が `max_batch_size=1` なのは「**プロパティ間で会話履歴・キャッシュが共有されると、誤判定を引き起こす**」という経験的な学びからの選択です。

---

## 5.4 `ClaudeRunner` とサーキットブレーカ

`ClaudeRunner.run(batch)` の中身は概ね次の通り：

1. バッチをワーカ用 JSON（`{phase}_QUEUE_*.json`）に書き出す
2. `claude` CLI を **subprocess** として起動：
   - `--prompt-path <prompt.md>` ── プロンプト指定
   - `--stream-json` ── イベントを 1 行 JSON で stdout に出力
   - 環境変数で `WORKER_ID`、`BATCH_INDEX`、`QUEUE_FILE`、`OUTPUT_FILE` 等を渡す
3. stdout を `outputs/logs/{phase}_W{w}B{b}_{ts}.jsonl` にリダイレクト
4. **`LogWatcher`** が JSONL を 1 行ずつ async でパース：
   - `usage` イベントからトークン消費を記録
   - `tool_use` イベントを数えて異常閾値（既定 200 件超）で「looping」フラグ
   - `error` イベントから rate limit／context overflow／timeout／usage limit を検出
5. プロセス終了後、出力 JSON を読んで結果を返す
6. 失敗時は **指数バックオフでリトライ**（最大 3 回）

### サーキットブレーカ

`CircuitBreaker` は **すべてのワーカで共有される** カウンタ群：

| カウンタ | 既定閾値（フェーズ 03） | 越えたら |
|---|---|---|
| `consecutive_failures` | 5 | 即座にトリップ（`circuit_breaker_threshold`） |
| `total_retries` | 20 | トリップ（`max_total_retries`） |
| `empty_results` | 15 | トリップ（`max_empty_results`） |

トリップ時は `CircuitBreakerTripped` を投げ、**全ワーカが順次停止** します。

### 「共有」設計の意味

> 全ワーカで 1 つのサーキットブレーカを共有する設計は、**システム性の問題**（プロンプトのバグ、API 障害、スキーマドリフト）を素早く検出するためです。
>
> もし各ワーカが独立にカウンタを持っていたら、4 ワーカ × 5 連続失敗 = 20 失敗を待たないとトリップしません。共有なら 5 失敗で即停止できます。

### 失敗の分類

`runner.py` には次の特殊例外があります：

- **`CircuitBreakerTripped`**：閾値超過で即停止
- **`MaxTurnsExhausted`**：`max_turns_per_batch` に達した。**リトライしても無意味**（決定論的）なので「empty_results」カウンタには加算しない
- **`BudgetExceeded`**：予算超過（`watchdog.py` 側）

### LogAnomalyDetector

ログ走査用のヒューリスティクスベース検知器。`stream-json` の各行を JSON としてパースし、**構造的なエラーフィールドだけ** を見ます（`tool_result` の `text` 内容はスキャンしません）：

| パターン | 正規表現 |
|---|---|
| `rate_limit_error` | `rate.?limit\|429\|too many requests` |
| `context_overflow` | `context.?length\|token.?limit\|maximum.?context` |
| `api_error` | `APIError\|InternalServerError\|ServiceUnavailable\|overloaded` |
| `timeout_error` | `timed?\s*out\|deadline exceeded\|ETIMEDOUT` |
| `usage_limit` | `out of (?:extra )?usage\|usage.?limit\|resets? \w+ \d+` |

`usage_limit` は **fatal**（リトライ無意味）として扱われ、即サーキットブレーカをトリップさせます。

**「コンテンツをスキャンしない」設計の意味**：監査対象に "rate limit" や "timeout" などの単語が含まれている場合（例：プロトコル仕様の説明）、誤検知を起こします。**構造フィールドのみ** を見ることで、ターゲットドメイン非依存性を保っています。

---

## 5.5 ログウォッチャと予算制御

### LogWatcher

`watchdog.py` の `LogWatcher` は async タスクとして起動され、ログファイルを **追記モードで tail** しながらイベントを処理します：

- `usage` 系イベント → `CostTracker.record_usage()` でトークン消費を反映
- `error` 系イベント → 異常パターンマッチング
- `tool_use` の累計が閾値超 → 「looping」フラグ

### CostTracker と価格モデル

```python
_DEFAULT_PRICING = {
    "input_per_million": 3.00,         # $3.00 / 1M input tokens
    "output_per_million": 15.00,       # $15.00 / 1M output tokens
    "cache_read_multiplier": 0.10,     # input price の 10%
    "cache_creation_multiplier": 1.25, # input price の 125%（5 分階層）
}
```

これは Claude Sonnet を想定した既定値。Opus を使うフェーズ 01a／01b／01e ではコンストラクタで上書きされます。

### バッチごとの計算

```python
input_cost          = (input_tokens / 1M) * input_price_per_million
cache_read_cost     = (cache_read_tokens / 1M) * input_price * cache_read_multiplier
cache_creation_cost = (cache_creation_tokens / 1M) * input_price * cache_creation_multiplier
output_cost         = (output_tokens / 1M) * output_price_per_million

batch_cost = input_cost + cache_read_cost + cache_creation_cost + output_cost
```

累計コストが `max_budget_usd` を超えると **`BudgetExceeded`** を raise。これはランナレベル（subprocess を起動する手前）で起きるため、**「runaway なプロンプトが予算を一気に焼き尽くす」事態を防げます**。

### per-batch 履歴

CostTracker は各バッチの履歴を記録します：

```python
{
    "batch": 12,
    "worker_id": 2,
    "batch_index": 5,
    "input_tokens": 12000,
    "cache_read_tokens": 80000,    # キャッシュヒット
    "cache_creation_tokens": 5000, # キャッシュ作成
    "output_tokens": 3500,
    "num_turns": 18,
    "batch_cost_usd": 0.0853,
    "cumulative_cost_usd": 0.9412
}
```

これにより「キャッシュヒット率が低いワーカ」「ターン数が異常に多いバッチ」のような診断が可能になります。

### 予算上限のフェーズ別設定

| Phase | `max_budget_usd` |
|---|---|
| `02c` | 20.0 |
| `03` | **200.0**（最高コスト） |
| `04` | （既定 50.0） |

フェーズ 03 が突出して高いのは、3 サブフェーズ × プロパティごとの完全コード読み込み × Stress-Test が重く、所見数百件 × 数ドル／件 になりうるためです。

---

## 5.6 再開（Resume）と部分結果保存

### `ResumeManager`

```python
class ResumeManager:
    def get_processed_ids(self) -> set[str]:
        # 1. {phase}_PARTIAL_*.json を glob
        # 2. 各 PARTIAL の metadata.processed_ids を優先（fast path）
        # 3. なければ result_key 配下の id_field を抽出（slow path）
```

### 設計のポイント

- **PARTIAL ファイルが「再開状態」そのもの**：再開のためだけの専用 state ファイルは持たない。「成果物そのものから再開状態を再構成」できる
- **ID フィールドはフェーズごとに違う**（`PhaseConfig.item_id_field`）：
  - 01a：`url`
  - 01b：`source_url`
  - 01e：`file_path`
  - 02c／03／04：`property_id`
- **fast path／slow path の二段構え**：`metadata.processed_ids` があれば即座に集合化、なければ全件走査

### `--force` オプション

```bash
uv run python3 scripts/run_phase.py --phase 03 --force --workers 4
```

`--force` は環境変数 `FORCE_EXECUTE=1` を立て、PARTIAL ファイルの走査をスキップします。完全再実行が必要な場合（プロンプトを大きく変えた等）に使います。

### `--cleanup-dry-run`

```bash
uv run python3 scripts/run_phase.py --phase 03 --cleanup-dry-run
```

不完全バッチ（途中で止まったランで残ったログのみで PARTIAL が無いもの）を検出し、削除候補を表示します。

---

## 5.7 結果コレクタとスキーマ検証

`ResultCollector` は次を担います：

1. ワーカが書き出した `{phase}_PARTIAL_*.json` を読み込み
2. 各 result item を Pydantic で検証（warning のみ）
3. `output_fields` が指定されている場合、フィールドフィルタを適用して **PARTIAL を圧縮**

### `output_fields` フィルタ

例：フェーズ 01e は次のフィールドだけを残します（`config.py` より）：

```python
output_fields=["property_id", "text", "type", "assertion", "severity",
               "covers", "reachability", "bug_bounty_eligible", "exploitability"]
```

これにより、ワーカが豊富な情報を出力していても、PARTIAL JSON は **後段で必要なフィールドだけ** に絞られます。トークン削減の重要な仕組みです。

### `context_fields` （02c・03 のみ）

逆方向のフィルタ。**前段から後段に渡すコンテキスト** をフィールドレベルで絞ります：

```python
# Phase 03 が Phase 02c から受け取るフィールド
context_fields=["property_id", "text", "type", "assertion", "severity",
                "covers", "reachability", "exploitability",
                "code_scope", "code_excerpt"]
```

「02c 側で計算したが 03 では不要なフィールド」（例：内部メトリクス）を伝播しないことで、Phase 03 のコンテキスト消費を抑えています。

---

## 5.8 セキュリティ：パストラバーサル防御

`base.py` には興味深い防御機構があります：

```python
def _is_safe_output_path(file_path: str) -> bool:
    """LLM 出力 JSON の file_path/subgraph_file を opening する前に
    outputs/ ディレクトリ内に解決されることを確認する"""
    try:
        outputs_dir = get_output_root().resolve()
        resolved = Path(file_path).resolve()
        return resolved.is_relative_to(outputs_dir)
    except (ValueError, OSError):
        return False
```

**LLM が出力した JSON 中に `../../../../etc/passwd` のようなパスが含まれた場合に、それを開かないための防御** です。LLM の出力を機械的に処理する以上、これは正しい設計です。

`tests/test_sec_c02_path_traversal.py` というテストファイル名からも、セキュリティテストが組み込まれていることが伺えます。

---

## 5.9 抽象基底＋具象オーケストレータ

`BaseOrchestrator` は抽象クラスで、フェーズごとに具象クラスがあります：

```python
class Phase01Orchestrator(BaseOrchestrator):
    """01a, 01b, 01e に対応"""
    # オーバーライド：入力読み込み（01a は SPEC_URLS 環境変数）

class Phase02cOrchestrator(BaseOrchestrator):
    # オーバーライド：BUG_BOUNTY_SCOPE.json 検証、SUBGRAPH_INDEX 構築

class Phase03Orchestrator(BaseOrchestrator):
    # オーバーライド：TARGET_INFO.json から target_workspace/ 自動 clone

class Phase04Orchestrator(BaseOrchestrator):
    # オーバーライド：BUG_BOUNTY_SCOPE.json／TARGET_INFO.json の preload
```

各具象クラスは **入力の準備** と **コンテキスト付与** だけを担当し、**バッチ生成・並列実行・サーキットブレーカ・コスト追跡・PARTIAL 保存** はすべて基底クラスに任せます。

---

## 5.10 設計判断のまとめ

| 設計判断 | 理由 |
|---|---|
| サーキットブレーカは全ワーカで共有 | システム性問題の早期検出 |
| 検証は warning のみ・部分結果を残す | 1 件の失敗で全結果を失わない |
| PARTIAL ファイルが再開状態 | 専用 state ファイルを持たないので壊れにくい |
| 予算強制をランナレベルに組み込み | 個別フェーズで「予算超えてるかも」と気にしなくて良い |
| ログ異常検知は構造フィールドのみ | ターゲットドメインの単語に誤反応しない |
| パストラバーサル防御 | LLM 出力を機械処理する以上必要 |
| `output_fields` ／ `context_fields` フィルタ | トークン削減の構造的手段 |

これらが組み合わさって、**「複数ワーカで並列実行できて、途中で落ちても再開でき、暴走しても予算で止まる、フェーズ追加コストが構造的に低い」** ハーネスが成立しています。

---

## 5.11 章のまとめ

- オーケストレータは抽象基底＋4 つの具象クラスで構成。フェーズ追加は **`PHASE_CONFIGS` への登録＋プロンプト追加＋スキーマ追加** の 3 点で完了
- バッチ戦略は 4 種類（Token／Count／Byte／Hybrid）。フェーズの性質に応じて選択
- サーキットブレーカは全ワーカ共有で、3 種類の閾値（連続失敗／総リトライ／空結果）でトリップ
- `CostTracker` がフェーズ別予算を強制。Sonnet／Opus の価格を使い分けてバッチごとに記録
- 再開は専用 state ファイルではなく **PARTIAL ファイル走査** で実現。壊れにくい
- LLM 出力からのファイルパスは **パストラバーサル防御** を通してから open

次章では、これら全フェーズが動作する **プロンプト・スキル・MCP サーバ** の三位一体について解説します。

---

## 5.12 参考文献

- `scripts/orchestrator/base.py` ／ `runner.py` ／ `watchdog.py` ／ `batch.py` ／ `resume.py` ／ `collector.py` ／ `schemas.py`
- README §「The Audit Harness」
- `tests/test_sec_c02_path_traversal.py`、`tests/test_watchdog_cache_tokens.py`
