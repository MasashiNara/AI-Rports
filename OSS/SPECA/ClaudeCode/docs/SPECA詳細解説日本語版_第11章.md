# SPECA 詳細解説（日本語版） — 第 11 章 まとめと適用ガイド

> 関連：[概略と目次](概略と目次.md) ／ [前：第 10 章 CI/CD と運用](SPECA詳細解説日本語版_第10章.md)

最終章として、ここまで扱ってきた SPECA の **強み・限界**、**新規ターゲットへの適用手順**、**研究・改善のフロンティア**、**推奨される運用体制** をまとめます。

---

## 11.1 SPECA の強み（再整理）

### 強み 1：コード駆動ツールが構造的に届かない領域に到達する

**最大の強み**。仕様に書かれている数学的・論理的な不変条件が実装に正しく反映されているかを検査でき、コードパターンとしては怪しさのない仕様起因バグを検出できます。

**実例（第 9 章 §9.2.5 より再掲）：**

- **c-kzg-4844 の Fiat-Shamir チャレンジハッシュバグ** — KZG バッチ検証における選択的偽造を可能にする暗号学的不変条件違反
- 366 件の専門家提出物に **無かった** バグを発見し、開発者の修正コミットで確認

### 強み 2：マルチ実装シナリオでの均一性とスケール

同じ仕様を実装する N 個のクライアントに、**同一プロパティ集合** を均一に適用できます。

- **Ethereum 10 クライアント** で実証済（RQ1）
- 実装間で「監査の厳しさが違う」というブレが構造的に発生しない
- 仕様分析コストが N で割られて償却される

### 強み 3：誤検知の説明可能性

FP が **3 つの根本原因に分解可能**（信頼境界誤解 50% / コード読解誤り 37.5% / 仕様解釈誤り 12.5%）。各原因はパイプラインの特定フェーズに紐付き、改善ターゲットが明確です。

### 強み 4：プロブナンス（来歴の追跡）

すべての所見が `所見 → プロパティ → サブグラフ → 仕様セクション → INV-* ラベル` の連鎖を持ちます。レビュー時に「これは本当に仕様要件か？」を確認するコストが低い。

### 強み 5：再現性とコスト効率

- 監査結果は git ブランチに commit され、永続化される
- バグあたりコストは **約 $1.69**（RQ2、Sonnet 4.5）
- フェーズごとに `--workflow_dispatch` で個別実行可能

### 強み 6：ハーネスの再利用性

`scripts/orchestrator/` は新フェーズ追加コストが低い設計。新ドメイン・新モデル・新監査スタイルへの拡張が、ハーネスを触らずに可能です。

### 強み 7：「証明試行」の構造化推論

「バグを探せ」ではなく「プロパティを証明せよ」というプロンプト設計が、推論の終了条件と所見の根拠を構造的に明確化します。88% FP からの劇的改善が実証。

---

## 11.2 SPECA の限界

### 限界 1：仕様駆動システム以外には適用が難しい

SPECA の前提は **「仕様文書がある」** ことです。次のようなターゲットには適用が困難です：

| ターゲット | 困難な理由 |
|---|---|
| プロプライエタリな業務システム | 仕様書が無い／断片的 |
| 仕様が文書化されていない OSS | プロパティの根拠を作れない |
| 仕様がコメント／README に散在しているもの | 仕様抽出のコストが大きい |
| 仕様がアプリ／ロジック層では曖昧 | 一般 Web アプリ等。STRIDE は適用できるが、特定の数式制約は無い |

逆に、SPECA が威力を発揮するのは：

- **暗号ライブラリ**（KZG／BLS／secp256k1 等）
- **コンセンサスプロトコル実装**（Ethereum クライアント等）
- **フォーマル仕様のあるシステムプログラム**（コンパイラの仕様、JVM の仕様等）
- **RFC が定義するネットワークプロトコル実装**

### 限界 2：Automated-Only での再現率の限界

RQ1 では Automated-Only（フェーズ 1〜3 を完全自動）で **53%（8/15 H/M/L）** の再現率にとどまり、Expert-Augmented（7 件のマニュアルプロパティ追加）で **100%** に到達しました。

未到達の 47% は：

- **数学的ドメイン知識**（KZG ／ BLS12-381 のエッジケース）
- **複数仕様の相互参照**（custody groups の境界、フォーク遷移）

を要するクラスで、現状の自動化では捕捉できないものです。

### 限界 3：プロパティ種別の偏り

| 種別 | precision |
|---|---|
| Invariant | 75% |
| Precondition | 100% |
| **Postcondition** | 50% |
| **Assumption** | 0% |

Postcondition と Assumption の生成精度が低く、現状はほぼ Invariant 主導です。これは「研究フロンティア」として論文も明記しています（§11.3）。

### 限界 4：絶対コスト

`$1.69 / バグ` は人手監査と比べれば桁違いに安いですが、**個人が無料で気軽に使えるレベル** ではありません。

### 限界 5：モデル精度依存

「Property Adherence Effect」（第 9 章 §9.3.6）が示すとおり、**モデル能力が下がるとプロパティスコープからのドリフトが増える** ため、低性能モデルでは品質が下がります。

### 限界 6：仕様クロールの限界

フェーズ 01a は仕様サイトをクロールしますが：

- ペイウォール後の仕様（IEEE／ISO 等）
- PDF 主体の仕様（OCR 不要だが構造抽出が困難）
- 仕様が日本語など英語以外

への対応は限定的です。

### 限界 7：Claude Code への依存

ワーカランタイムが Claude Code（Anthropic 提供）に強く依存しています。他社モデル（GPT、Gemini、ローカル LLM）への切替は **非ゴール** として明示されており、ベンダーリスクがあります。

---

## 11.3 新規ターゲットへの適用手順（チェックリスト）

新しいターゲット領域・コードベースに SPECA を適用したい場合の手順です。**SPECA の強みは「ドメイン非依存」設計** にあるため、コード変更ほぼ無しで新ターゲットに適用できます。

### ステップ 1：適用可能性の判定

下記がすべて Yes なら、SPECA は適合します：

- [ ] ターゲットを律する **仕様文書** が公開されている（Web URL、または GitHub の `.md` 等）
- [ ] 仕様が **手続き／関数／状態遷移** の形で記述されている
- [ ] ターゲットの **ソースコードが取得可能**（OSS または社内アクセス）
- [ ] **対象コミット** が固定できる
- [ ] Claude Code CLI への **API アクセス** がある（API キーまたはサブスクリプション）

### ステップ 2：`outputs/TARGET_INFO.json` 作成

```json
{
  "name":     "<your-target>",
  "repo":     "https://github.com/<owner>/<repo>",
  "commit":   "<full-sha>",
  "language": "rust|go|c|cpp|typescript|javascript|python|...",
  "target_layer": "<optional>",
  "out_of_scope_spec_layers": ["<optional list>"]
}
```

### ステップ 3：`outputs/BUG_BOUNTY_SCOPE.json` 作成

```json
{
  "in_scope": {
    "components": ["<core_module1>", "<core_module2>"],
    "scope_restriction": "<optional restriction>"
  },
  "out_of_scope": ["<excluded_topic1>", "<excluded_topic2>"],
  "conditional_scope": ["<optional>"],

  "trust_assumptions": {
    "<external_input_source>": {
      "trust_level": "UNTRUSTED",
      "rationale": "Anyone can submit this"
    },
    "<internal_state>": {
      "trust_level": "TRUSTED",
      "rationale": "Validated by consensus"
    }
  },

  "severity_classification": {
    "CRITICAL": "<your definition>",
    "HIGH":     "<your definition>",
    "MEDIUM":   "<your definition>",
    "LOW":      "<your definition>"
  },

  "deployment_context": {
    "type": "single-implementation|multi-implementation",
    "target_share": { "value": 1.0, "metric": "deployment-share" }
  }
}
```

### ステップ 4：仕様 URL の特定

```bash
# シード URL を環境変数で渡してフェーズ 01a を実行
SPEC_URLS="https://your.spec.site/main.md,https://other.url/" \
  uv run python3 scripts/run_phase.py --phase 01a
```

`outputs/01a_STATE.json` に発見された仕様一覧が出るので、必要に応じて手動で取捨選択できます。

### ステップ 5：エンドツーエンド実行（小規模で）

```bash
uv run python3 scripts/run_phase.py --target 04 --workers 2 --max-concurrent 8
```

`--workers` と `--max-concurrent` を **小さく** から始め、API レートリミットに当たらないか確認しながら拡大します。

### ステップ 6：結果の検証

- `outputs/04_PARTIAL_*.json` を読み、**CONFIRMED_VULNERABILITY** の所見を中心にレビュー
- フェーズ 03 の `proof_trace` と `attack_scenario` を確認
- 既知の修正コミットがあれば対応する所見が含まれるか確認

### ステップ 7：マニュアルプロパティの注入（任意）

Automated-Only での再現率が不足する場合、`outputs/01e_PARTIAL_extra.json` のような追加 PARTIAL に **手書きのプロパティ** を加えます。論文では：

- 暗号学的不変条件
- プロトコルライフサイクル規則

の 2 領域でマニュアルプロパティが効果を発揮しました。

### ステップ 8：CI 化

監査が安定したら、`.github/workflows/full-audit.yml` を参考にして CI 化します。専用ブランチに監査結果を commit し、PR で人間レビューに回す運用が標準です。

---

## 11.4 研究・改善のフロンティア

論文と本資料の分析から見える、SPECA の今後の改善ターゲット：

### フロンティア 1：Postcondition／Assumption の生成精度

Invariant（precision 75%）と Precondition（100%）は十分だが、Postcondition（50%）と Assumption（0%）の生成精度が低い。**プロパティ語彙の質を上げる** ことが、Automated-Only の再現率向上の最大レバーです。

### フロンティア 2：信頼境界の誤解（FP 50%）の削減

最大の FP 原因。`BUG_BOUNTY_SCOPE.json` の `trust_assumptions` をより詳細に・自動的に整備するメカニズムが研究フロンティア。

### フロンティア 3：マニュアルプロパティの自動化

論文で「数学的ドメイン知識または複数仕様の相互参照」が必要としているクラスを、自動化する研究。

### フロンティア 4：仕様クロールの強化

PDF 仕様・ペイウォール仕様・非英語仕様への対応。

### フロンティア 5：「Property Adherence Effect」の活用

> モデルが改善されるほど、**プロパティが指示することを正確に監査** するようになる。
>
> プロパティ生成（フェーズ 1〜3）が **検出カバレッジを律速する**。

これは「将来のモデル改善が SPECA の再現率に直接寄与しない」ことを意味します。**プロパティ生成の改善が長期的な研究方向** です。

### フロンティア 6：Web UI の実装

`web/WEB_APP_DESIGN.md` で計画されている Next.js SSG が未実装。学会 Artifact Evaluation の観点からも、ベンチマーク結果の動的可視化は重要です。

### フロンティア 7：speca-cli の M2 以降

現状 M1（スケルトン）まで。ロードマップ通り進めば **`npx speca-cli` で完結する監査体験** が実現します。新規採用障壁の最大の緩和策。

---

## 11.5 推奨される運用体制

### 11.5.1 個人・小規模利用

- **ローカル実行** が中心
- `speca-cli`（M2 以降）でセットアップを簡略化
- API は **Claude Code サブスクリプション**（speca-cli 経由）
- フェーズ 03 の予算上限を $50 程度から始め、徐々に上げる

### 11.5.2 中規模（チーム監査）

- **CI 化**（GitHub Actions self-hosted runner）
- audit ブランチごとにターゲット 1 つずつ commit
- 監査結果を **PR レビュー** に乗せる
- マニュアルプロパティはチーム共有資産として管理

### 11.5.3 大規模（複数実装の継続監査）

- 各クライアント／実装に **専用ブランチ**
- マニュアルプロパティを **仕様コーパス単位で 1 度書く**（N 実装で再利用）
- フェーズ 1〜3 を別ジョブで先行実行、フェーズ 4〜6 は実装ごとに並列
- Discord 通知（`server/discord.py`）でラン完了を共有
- ベンチマーク評価（`benchmarks/rq1/cli.py`）で再現率・FP を追跡

### 11.5.4 学術利用（論文・Artifact Evaluation）

- リポジトリ同梱の `benchmarks/results/rq1/` ／ `rq2a/` を再現素材として利用
- Web UI（実装後）で動的可視化
- 監査ブランチを論文付録として参照

---

## 11.6 全 11 章で扱った要点（まとめのまとめ）

| 章 | 核心 |
|---|---|
| 0 はじめに | SPECA は **コード駆動から仕様駆動へ反転** した監査ツール |
| 1 全体像とコンセプト | 6 フェーズ／2 ステージ、**「証明試行」が中核**、3 つの能力（仕様依存検出／クロス実装比較／FP 根本原因分解） |
| 2 リポジトリ構成 | Python パイプライン中心＋ CLI ／サーバ／ Web UI 設計／ベンチマーク／ CI の衛星構成 |
| 3 パイプライン詳細 | 各フェーズの目的・入出力・内部処理。フェーズ 03 の **Map → Prove → Stress-Test** が中核 |
| 4 マニュアルフェーズ | PoC 生成（言語自動判定）／バグバウンティレポート（プラットフォーム別）／フルレポート |
| 5 オーケストレータ詳細 | 抽象基底＋4 具象クラス、サーキットブレーカ・コスト追跡・再開を **PARTIAL ファイルで支える** |
| 6 スキル・プロンプト・MCP | スキル形式 vs インライン形式の使い分け。3 種の MCP サーバ（fetch／tree_sitter／filesystem） |
| 7 CLI（speca-cli） | TUI で SPECA への採用障壁を下げる。**Claude Code サブスクリプション認証**、**vendor 戦略** |
| 8 サーバと Web UI | FastAPI でローカル API 提供、SSE 進捗、Discord 通知。Web UI は Next.js SSG 設計（未実装） |
| 9 実績とベンチマーク | **Sherlock H/M/L 100%、4 件の独自発見、RepoAudit 88.9%、$1.69/バグ** |
| 10 CI/CD と運用 | 26 ワークフロー、必須 2 ファイル、`SPECA_OUTPUT_DIR`、PARTIAL ファイルが再開状態 |
| 11 まとめ（本章） | 強み 7／限界 7、適用チェックリスト、研究フロンティア 7、運用体制 4 段階 |

---

## 11.7 結語

SPECA は **「コードからではなく仕様から監査せよ」** という設計判断 1 つから派生して、検出能力・説明性・スケーラビリティ・コスト効率のすべてで定性的に新しい性質を獲得した、興味深いセキュリティ監査フレームワークです。

特筆すべきは、論文に書かれた数字の背後に **動作するコード／実行可能な CI／再現可能なアーティファクト** がすべて揃っていることです。これは学術的主張と実装の整合性が高いプロジェクトの典型で、今後の研究と実用の双方で発展余地があります。

仕様駆動システムを開発・監査する組織にとって、SPECA は「**自社で運用する監査ハーネス**」のリファレンス実装として、参照する価値が十分あります。OSS コミュニティとしても、新ドメインへの拡張と Web UI 実装が進めば、より広いユーザベースに到達するでしょう。

---

## 11.8 参考文献（全章共通）

- 論文：Kamba, Murakami, Sannai. *Beyond Code Reasoning: A Specification-Anchored Audit Framework for Expert-Augmented Security Verification.* arXiv:2604.26495, 2026.
- リポジトリ：[NyxFoundation/speca](https://github.com/NyxFoundation/speca)
- README、`docs/SPECA_CLI_SPEC.md`、`web/WEB_APP_DESIGN.md`、`benchmarks/README.md`
- 各フェーズプロンプト：`prompts/01a_crawl.md` ～ `prompts/06b_audit_report.md`
- オーケストレータ：`scripts/orchestrator/*.py`
- CI：`.github/workflows/*.yml`
