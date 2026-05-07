# SPECA 詳細解説（日本語版） — 第 8 章 サーバと Web UI 設計

> 関連：[概略と目次](概略と目次.md) ／ [前：第 7 章 CLI](SPECA詳細解説日本語版_第7章.md) ／ [次：第 9 章 実績とベンチマーク](SPECA詳細解説日本語版_第9章.md)

第 7 章で扱った CLI（`speca-cli`）は **ターミナル** からの操作を提供します。本章では、もう一つのフロントエンド系統である：

- **FastAPI サーバ**（`server/`）：ローカル実行用 HTTP API（実装済）
- **Web UI 設計提案**（`web/`）：ベンチマーク結果可視化のための Next.js SSG（**設計提案のみ、実装は未着手**）

を解説します。両者は SPECA をブラウザベースで動かす／可視化することを念頭にした構成です。

---

## 8.1 FastAPI サーバ（`server/`）— 概観

### 8.1.1 立ち位置

`server/app.py` は **ローカル実行用** の FastAPI アプリケーションです。Python オーケストレータを **HTTP API として外部公開** する役割を持ちます。

| 利用シーン | 想定フロー |
|---|---|
| Web UI 開発 | ブラウザ（Vite 開発サーバ＝5173 番）から `http://localhost:8000/api/...` を叩く |
| CLI／TUI からのリモート起動 | TUI が API 経由でフェーズを起動・進捗購読 |
| 単発スクリプト | `curl` でフェーズを dispatch、`/progress` を SSE 購読 |

第 7 章の `speca-cli` は **subprocess** として Python オーケストレータを起動するモデル、本章の FastAPI サーバは **HTTP API** として公開するモデル。両者は併用可能です。

### 8.1.2 起動方法

```bash
uv run uvicorn server.app:app --reload --port 8000
```

CORS は `http://localhost:5173`（Vite 既定ポート）に向けて開かれており、ローカル Web UI からの呼び出しを想定しています：

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 8.1.3 構成

```
server/
├── app.py                     # FastAPI 本体（CORS + lifespan）
├── routes/
│   ├── phases.py              # /api/phases       — フェーズ一覧・起動
│   └── runs.py                # /api/runs         — ラン状態・進捗 SSE・キャンセル
├── run_manager.py             # In-memory ラン管理（シングルユーザ）
├── orchestrator_bridge.py     # 既存 orchestrator パッケージとの橋渡し
├── progress.py                # ProgressBus 抽象（pub/sub）
├── discord.py                 # Discord Webhook 通知
└── models.py                  # API モデル（Pydantic）
```

---

## 8.2 ルーティング体系

### 8.2.1 `/api/phases`

| メソッド | パス | 役割 |
|---|---|---|
| GET | `/api/phases/` | 全フェーズ一覧（`PHASE_CONFIGS` から）を `phase_id`／`name`／`description`／`depends_on`／`max_budget_usd` で返却 |
| POST | `/api/phases/dispatch` | フェーズを起動。`PhaseDispatchRequest` を受けて `RunManager.create_run()` し、`launch_phase()` で非同期起動 |

### 8.2.2 `/api/runs`

| メソッド | パス | 役割 |
|---|---|---|
| GET | `/api/runs/` | 全ラン履歴（新しい順） |
| GET | `/api/runs/{run_id}` | 単一ランの状態と結果 |
| GET | `/api/runs/{run_id}/progress` | **SSE（Server-Sent Events）** でリアルタイム進捗ストリーム |
| POST | `/api/runs/{run_id}/cancel` | ランをキャンセル |

### 8.2.3 SSE 進捗ストリームの設計

`/api/runs/{run_id}/progress` は SSE エンドポイントで、ProgressBus から購読したイベントを 1 つずつ HTTP ストリームで返します：

```python
async def event_generator():
    try:
        while True:
            try:
                event = await asyncio.wait_for(queue.get(), timeout=30.0)
            except asyncio.TimeoutError:
                yield ": keepalive\n\n"   # 30 秒ごとに keepalive
                continue
            if event is None:
                yield "event: done\ndata: {}\n\n"
                break
            yield (
                f"event: {event.type.value}\n"
                f"data: {json.dumps(event.data)}\n\n"
            )
    finally:
        run.bus.unsubscribe(queue)
```

特徴：

- **keepalive**：30 秒ごとに `:` 始まりの空行を送ってコネクションを維持
- **完了通知**：`None` を受け取ったら `event: done` で終了
- **キャンセル安全**：finally で確実に unsubscribe
- **ヘッダ**：`X-Accel-Buffering: no` で Nginx／プロキシ越しのバッファリング無効化

これにより、ブラウザは `EventSource` で SPECA のフェーズ進捗を **ライブ** で受け取れます。

---

## 8.3 `RunManager`：ラン管理

### 8.3.1 設計方針

```python
class RunManager:
    """Manages active and completed runs. Single-user, in-memory."""
```

ドキュメント文字列の通り、**シングルユーザ・メモリ内** が前提。これは：

- 永続化は **既存の `outputs/` ディレクトリ** が担う（PARTIAL ファイル）
- 並行ラン制限：同時に 1 つだけ
- プロセス再起動でメモリ上のラン履歴は失われる（過去結果は `outputs/` から再構築可能）

シングルユーザ前提なので、認証・マルチテナント・DB 永続化は持ちません。「**ローカルツール**」を貫く設計判断です。

### 8.3.2 ラン状態

```python
class RunStatus(str, Enum):
    QUEUED    = "queued"
    RUNNING   = "running"
    COMPLETED = "completed"
    FAILED    = "failed"
    CANCELLED = "cancelled"
```

`RunInfo` には：
- `run_id`（8 文字 UUID）
- `phase_id`
- `status`
- `created_at` ／ `completed_at`
- `inputs`（dispatch リクエストの内容）
- `bus`（`ProgressBus`）
- `task`（`asyncio.Task`）
- `error` ／ `result`

### 8.3.3 並行ラン防止

```python
def create_run(self, phase_id, inputs):
    if self._active_run_id:
        active = self._runs.get(self._active_run_id)
        if active and active.status == RunStatus.RUNNING:
            raise RuntimeError("A run is already active")
    ...
```

既にラン中なら **HTTP 409 Conflict** を返します（`routes/phases.py` でハンドリング）。

---

## 8.4 `orchestrator_bridge.py`：オーケストレータとの橋渡し

`server/` モジュールは **`scripts/orchestrator/` を直接 import** して使います（`server/__init__.py` で `scripts/` を `sys.path` に追加）。

`orchestrator_bridge.launch_phase(run, manager)` は：

1. 別タスクとして orchestrator の実行を起動
2. 進捗イベントを `run.bus` に流す
3. 完了時に `manager.mark_complete()` を呼ぶ
4. （設定されていれば）Discord 通知を送る

**Python オーケストレータをそのまま再利用** することがここでも徹底されています。

---

## 8.5 Discord Webhook 通知（`server/discord.py`）

ラン完了時に **Discord チャネルへ** 通知を送る機能が組み込まれています。

### 8.5.1 通知内容

| フィールド | 内容 |
|---|---|
| タイトル | `Phase {ID} -- 完了` ／ `失敗` ／ `キャンセル` |
| ステータス | `completed` ／ `failed` ／ `cancelled` |
| 所要時間 | `Xm Ys` 形式 |
| 結果件数 | `result.total_results` |
| コスト | `$X.XX`（`result.cost.total_cost_usd`） |
| 予算消化率 | `XX.X%`（`result.cost.budget_utilization_pct`） |
| エラー | （失敗時のみ）先頭 200 文字 |
| フッタ | `run_id: XXXXXXXX` |

色分け：成功（緑）／失敗（赤）／キャンセル（灰）。

### 8.5.2 設計判断

```python
async def send_phase_result(run: RunInfo) -> None:
    try:
        ...
    except Exception:
        logger.warning("Failed to send Discord notification", exc_info=True)
```

- **通知失敗は warning にとどめ、never raise**：通知の都合でランが失敗扱いになることを防ぐ
- **タイムアウト 10 秒**：Discord が応答しなくても素早く諦める
- **httpx 非同期クライアント**：他のサーバ処理をブロックしない

### 8.5.3 Webhook URL のハードコード

ファイル内に Webhook URL がハードコードされていますが、これは **ローカル専用** の前提です。配布版や本格運用では環境変数化が望ましく、上流で対処されると思われます。

---

## 8.6 Web UI 設計提案（`web/WEB_APP_DESIGN.md`）

### 8.6.1 立ち位置（重要）

`web/` ディレクトリは現状 **設計提案のみ** で、実装は未着手です。`WEB_APP_DESIGN.md` という設計文書が 1 つあるだけ。

設計の動機（ドキュメントから引用）：

> SPECA の出力は JSON + Markdown のみ。以下の課題がある:
>
> - 査読者が PARTIAL JSON を手動で確認する必要がある
> - 3 フェーズ監査の推論過程が JSON に埋もれている
> - パイプラインのデモが困難（CLI 依存）
> - RQ1/RQ2 の結果が静的で動的フィルタリング不可
> - Mermaid `.mmd` がレンダリングされていない
>
> 学会 Artifact Evaluation での「Available / Functional / Reproduced」バッジ取得を支援する。

### 8.6.2 アーキテクチャ：Next.js SSG

**Next.js 14（App Router）の SSG（Static Site Generation）モード** を採用予定。選定理由：

1. **GitHub Pages ／ Vercel で無料ホスティング** — 査読者がワンクリックでアクセス可能
2. **バックエンド不要** — 既存の JSON 出力を `public/data/` に配置するだけ
3. **既存パイプラインへの影響ゼロ**
4. **`npm run build` で静的ファイル一式を ZIP 提出可能**
5. **プロフェッショナルな外観** — 学会向け配布物として遜色ない

### 8.6.3 ディレクトリ構成案

```
speca/
├── web/                          # 新規（既存に影響なし）
│   ├── package.json
│   ├── next.config.js
│   ├── public/data/              # パイプライン出力 JSON コピー先
│   │   ├── rq1/  rq2/  audit/  graphs/
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx          # ランディング
│   │   │   ├── rq2/page.tsx      # RQ2 ダッシュボード
│   │   │   ├── rq1/page.tsx      # RQ1 エクスプローラー
│   │   │   ├── audit/page.tsx    # 監査トレイル閲覧
│   │   │   └── graphs/page.tsx   # プログラムグラフ
│   │   ├── components/
│   │   │   ├── charts/           # Recharts / D3
│   │   │   ├── tables/           # TanStack Table
│   │   │   ├── audit-trail/      # 3 フェーズ展開表示
│   │   │   └── code-viewer/      # シンタックスハイライト
│   │   └── lib/
│   │       ├── types.ts          # schemas.py から自動生成
│   │       └── data-loader.ts
│   └── scripts/
│       └── sync-data.sh          # outputs/ -> web/public/data/
└── （その他のディレクトリは変更なし）
```

### 8.6.4 ページ別機能

| ページ | 内容 |
|---|---|
| `/rq2` | ツール比較棒グラフ、CWE カバレッジヒートマップ、統計検定カード、データセット／ツール／CWE フィルタ |
| `/rq1` | クライアント選択タブ、Findings／Matched／Recall サマリー、マッチ／未マッチ Issue テーブル |
| `/audit` | 3 フェーズアコーディオン展開、コードスニペット（Shiki）、Severity／Classification フィルタ |
| `/graphs` | Mermaid.js グラフレンダリング、グラフ要素クリックで関連プロパティへジャンプ |

### 8.6.5 技術スタック（提案）

| カテゴリ | 選定 |
|---|---|
| フレームワーク | Next.js 14+（App Router、SSG） |
| 言語 | TypeScript |
| UI | shadcn/ui ＋ Tailwind CSS |
| チャート | Recharts ＋ D3.js |
| テーブル | TanStack Table |
| コードビューア | Shiki |
| グラフレンダリング | Mermaid.js |
| ビルド | `next build && next export` |
| ホスティング | Vercel（第一候補）／ GitHub Pages |
| CI | GitHub Actions（`sync-data.sh` → `npm run build` → デプロイ） |

### 8.6.6 データフロー

```
outputs/                  ──sync-data.sh──▶ web/public/data/
benchmarks/results/        ─────────────▶  web/public/data/
```

- Web アプリは **読み取り専用ビュー**
- 既存コードベースへの変更は **一切不要**
- TypeScript の型定義は `pydantic-to-ts` で `schemas.py` から自動生成（第 7 章で `speca-cli` 用に挙げた JSON Schema export と整合する）

### 8.6.7 既存コードへの影響：ゼロ

設計文書に明記されているとおり、影響範囲は最小：

| 変更が必要 | `.gitignore`（`web/node_modules/`、`web/.next/`、`web/out/` 追加）／`.github/workflows/`（デプロイワークフロー新規追加） |
|---|---|
| 変更不要 | `scripts/orchestrator/`、`scripts/run_phase.py`、`prompts/`、`.claude/skills/`、`benchmarks/`、`tests/`、`outputs/` |

### 8.6.8 主要なユースケース：ベンチマーク結果の動的可視化

Web UI の最大の価値は **ベンチマーク結果（RQ1／RQ2）を動的フィルタリング可能なダッシュボード** にすることです。

論文に載っている数字は静的な PNG／表で、「重要度別の所見だけ見たい」「特定クライアントだけ見たい」といったインタラクティブな探索ができません。Web UI ではこれが TanStack Table と Recharts の組み合わせで自然にできるようになります。

学会発表時に「**ブラウザで `https://speca.dev/rq2` を開いてフィルタ操作してもらう**」というデモが可能になり、論文評価（Artifact Evaluation）で有利に働きます。

---

## 8.7 サーバと CLI の比較

| 観点 | FastAPI サーバ | speca-cli |
|---|---|---|
| 起動方法 | `uvicorn server.app:app` | `npx speca-cli` |
| インタラクション | HTTP API（ブラウザ／クライアントから） | TUI（ターミナル） |
| Python 呼び出し | 同一プロセス内 import | subprocess |
| 進捗購読 | SSE | stream-json |
| 並行ラン | 1 つに制限 | 1 つに制限（`outputs/` のロックで） |
| 認証 | なし（ローカル前提） | Claude Code OAuth |
| 通知 | Discord Webhook | TUI 内モーダル |
| 永続化 | `outputs/` のみ | `outputs/` + `.speca/session.json` |
| 想定ユーザ | Web UI フロントエンド開発者 | エンドユーザ |

両者は **競合ではなく補完関係**：CLI は対話用、サーバはリモート起動／可視化用。

---

## 8.8 章のまとめ

- **FastAPI サーバ**は SPECA をローカル HTTP API として公開するシンプルな実装。シングルユーザ・メモリ内で、`outputs/` を真理元として持つ
- 進捗はすべて **SSE** で配信。30 秒ごとの keepalive、`X-Accel-Buffering: no` などプロキシ越しでも動く配慮
- **Discord Webhook 通知** がラン完了時に組み込まれている。失敗を握り潰す（never raise）設計
- **Web UI** は現状設計提案のみ。Next.js SSG で **既存コードベースへの影響ゼロ** を原則に、`outputs/` を読み取り専用で可視化
- Web UI の主目的は **ベンチマーク結果の動的可視化** と **学会 Artifact Evaluation の支援**
- サーバと CLI は補完関係：CLI は対話、サーバはリモート起動・可視化

次章では、SPECA がどのような実績を上げたのか、ベンチマーク結果を中心に解説します。本資料の中でも特にマネージャー層に重要なパートです。

---

## 8.9 参考文献

- `server/app.py`、`server/run_manager.py`、`server/routes/runs.py`、`server/routes/phases.py`、`server/discord.py`
- `web/WEB_APP_DESIGN.md`
- `server/orchestrator_bridge.py`（オーケストレータとの橋渡し）
