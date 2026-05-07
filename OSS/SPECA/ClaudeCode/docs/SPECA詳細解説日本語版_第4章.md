# SPECA 詳細解説（日本語版） — 第 4 章 マニュアルフェーズ（PoC・レポート生成）

> 関連：[概略と目次](概略と目次.md) ／ [前：第 3 章 パイプライン詳細](SPECA詳細解説日本語版_第3章.md) ／ [次：第 5 章 オーケストレータ詳細](SPECA詳細解説日本語版_第5章.md)

第 3 章で扱った 6 つの自動フェーズ（`01a` → `04`）は、CI／CD で並列・自動的に動かすことを想定していました。一方、本章で扱う **マニュアルフェーズ** は、特定の所見に絞って **個別に手で動かす** ためのプロンプトです。

| Phase | 名称 | 役割 | 自動化 |
|---|---|---|---|
| 05 | PoC 生成 | 監査所見ごとに最小限の Proof-of-Concept テストを生成 | **手動**（特定の所見に対して個別実行） |
| 06 | バグバウンティレポート | プラットフォーム別テンプレートで報告書を生成 | **手動** |
| 06b | フルセキュリティレポート | 監査全体を網羅した出版可能レポート | **手動** |

これらは、`scripts/run_phase.py` のオーケストレータ管轄外で、Claude Code のスラッシュコマンドとして直接呼び出します。

---

## 4.1 フェーズ 05：PoC 生成（Proof-of-Concept Generation）

| 項目 | 内容 |
|---|---|
| **プロンプト** | `prompts/05_poc.md` |
| **使い方** | `/05_poc TYPE=unit VULN_ID=... OUTPUT_PATH=...` |

### 4.1.1 目的

フェーズ 03／04 で確認された脆弱性に対して、**プロジェクト固有の言語・テストフレームワーク** で最小の Proof-of-Concept テストを自動生成します。**バグが存在する状態でだけテストが通り、修正されると失敗する** ことが要件です。

### 4.1.2 引数

| 引数 | 値域 | 意味 |
|---|---|---|
| `TYPE` | `unit` ／ `it` ／ `e2e` | テストの粒度 |
| `VULN_ID` | `audit_items[].id` | 対象とする脆弱性 ID |
| `OUTPUT_PATH` | パス | 生成テストファイルの保存先 |

### 4.1.3 内部処理

1. **`outputs/03_AUDITMAP.json` を読み込み**、`audit_items[].id == $VULN_ID` のエントリを特定
2. 当該エントリから次を抽出：
   - `VULN_SNIPPET` ← `audit_items[].snippet`
   - `TARGET_FILE` ← `audit_items[].file` ＋ 行番号
   - `VULN_TITLE` ← 説明文の冒頭
   - `TITLE_SLUG` ← lowercase snake_case（≤ 40 文字）
3. **言語・テストフレームワークの自動判定**：プロジェクトのファイルから言語（Rust／Solidity／Go／TypeScript/...）と既存テスト構造を判別
4. **`TYPE` 別の生成方針**：
   - `unit`：モジュール／クレート単位の最小テストハーネスを使う
   - `it`（integration）：既存の integration テストの隣に配置し、`EXISTING_POC_FILES` の helper を再利用
   - `e2e`：CLI／API／コントラクトデプロイ／ワークフロースクリプトなど最上位の executable を使用
5. **PoC コードの生成**：
   - 既存テストやフィクスチャを **再利用**（再実装しない）
   - 外部バイナリ／ネットワーク依存は禁止（プロジェクトで標準のもの以外）
   - 120 LoC 以下を目安
6. **自己修復ループ**：最大 4 回まで、テストを動かして「pass しないか」「false positive を抑える guard assertion を含むか」を検証して修正

### 4.1.4 設計判断

- **言語仮定をしない**：「Rust だろう」と決め打ちせず、リポジトリのファイル構造から推論。これにより Solidity／Rust／Go／C/C++／TypeScript いずれにも適用可能
- **「ガード assertion」**：単に動くテストではなく、「修正後に意図通り fail することを確認する手段」を組み込む
- **既存資産の再利用**：fixtures、mocks を新規実装せず既存のものを使う（コードベースのスタイル一致）
- **`/serena` MCP の利用**：プロンプト中で「`/serena` を使ってトークン効率を最大化せよ」と明示。コード参照の効率化のため

### 4.1.5 想定ユースケース

```bash
# Phase 04 の出力で `CONFIRMED_VULNERABILITY` だった所見に対して
/05_poc TYPE="unit" VULN_ID="03523523" \
  OUTPUT_PATH="crates/net/network/src/transactions/poc_reentrancy.rs"
```

実行後は、当該テストが **バグの存在を再現する** 状態で commit され、開発者が修正するとテストが fail に転じる、という形で「PoC が修正状態の真偽判定器」として機能します。

---

## 4.2 フェーズ 06：バグバウンティレポート（Bug-Bounty Report）

| 項目 | 内容 |
|---|---|
| **プロンプト** | `prompts/06_report.md` |
| **使い方** | `/06_report VULN_ID=... REPORT_TYPE=ETHEREUM` |

### 4.2.1 目的

特定の脆弱性に対して、**バグバウンティプラットフォーム別のテンプレート** に従った Markdown 報告書を自動生成します。

### 4.2.2 対応プラットフォーム

| `REPORT_TYPE` | プラットフォーム |
|---|---|
| `CANTINA` | Cantina |
| `CODE4RENA` | Code4rena |
| `ETHEREUM` | Ethereum Foundation バウンティ |
| `IMMUNEFI` | Immunefi |
| `SHERLOCK` | Sherlock |

各プラットフォームは `docs/report_templates/{REPORT_TYPE}.md` に Markdown テンプレートを持ち、プロンプトはそれを **プレースホルダ埋め込み** で完成させます。

### 4.2.3 内部処理

1. **`03_AUDITMAP.json` から脆弱性データを抽出**
   - `SNIPPET` ／ `SRC_FILE` ／ `SRC_FUNCTION` ／ `UT_PATH` ／ `IT_PATH` ／ `VULN_TITLE` 等
2. **テンプレート解決**：`docs/report_templates/{REPORT_TYPE}.md` を読み込み
3. **プレースホルダ埋め込み**：
   - 全てのプレースホルダを埋める
   - 見出し順序とスタイル要求を保持
4. **PoC コードの埋め込み**：
   - Unit test → `{{UT_PATH}}` の中身を verbatim 引用
   - Integration test → `{{IT_PATH}}` がある場合は併記
   - **実行コマンドを明示**：`security-agent/` のような内部パスは削除し、テスト実行コマンドだけを残す
5. **Severity 推論**：`$SEVERITY` が未指定なら `01_BOUNTY_GUIDELINE.md` から導出

### 4.2.4 出力先と命名規約

```
security-agent/outputs/report_{TITLE_SLUG}.md
```

`report_{TITLE_SLUG}.md` 全体を 55 文字以内に収める制約。長すぎるタイトルは slug 段階で切り詰める。

### 4.2.5 設計判断

- **内部識別子の漏洩防止**：報告書には `security-agent/` などのリポジトリ内パス、内部 ID（`AP`、`SR`、`NORMATIVE_ID`、`@audit`、`@audit-ok`）を残さない。**公開時に neutral wording のみ** が露出するよう徹底
- **テンプレート方式**：プラットフォーム固有のフィールド要件（severity scale、報告フォーマット）に追従するため、各プラットフォームごとに別 Markdown テンプレートを管理

---

## 4.3 フェーズ 06b：フルセキュリティレポート（Full Audit Report）

| 項目 | 内容 |
|---|---|
| **プロンプト** | `prompts/06b_audit_report.md` |
| **使い方** | `/07_audit_report OUTPUT_PATH=outputs/AUDIT_REPORT.md` |

### 4.3.1 目的

監査全体を網羅した **出版可能** なセキュリティアセスメントレポートを生成します。バグバウンティ報告とは異なり、所見だけでなく：

- スコープと前提
- システム概観
- 方法論
- 仕様トレーサビリティ
- 所見分類
- 所見サマリ（重要度別件数）
- 詳細所見
- 再検証
- 運用上の推奨事項

までを含む包括的な文書です。

### 4.3.2 必須セクション

プロンプトで強制される必須セクション：

| セクション | 内容 |
|---|---|
| 0. Cover Page & Document Control | タイトル、版、日付、分類、スコープ要約、ブランチ・コミット、監査期間、監査者、免責 |
| 1. Executive Summary | 総合評価（Ready／Conditional／Blocked）、トップ重要度所見（最大 5）、修正状況スナップショット、推奨事項 |
| 2. Scope | 監査対象、対象外、適用された前提 |
| 3. System Overview | システム概観 |
| 4. Methodology | SPECA の方法論 |
| 5. Specification Traceability | 仕様要件と所見のマッピング |
| 6. Finding Classification | Vulnerability ／ Spec-Gap ／ Design Decision の分類 |
| 7. Findings Summary | 全所見の表形式サマリ |
| 8. Detailed Findings | 所見ごとの詳細（コード抜粋、修正状況、影響） |
| 9. Re-Verification | 修正後の再検証結果 |
| 10. Operational Recommendations | 運用上の推奨事項 |
| 11. Appendix | 補助資料 |

### 4.3.3 重要：「リポジトリ内部名の禁止」原則

プロンプトには非常に強い制約があります：

> **Repository-Internal Names Are Forbidden**
>
> Never include the repository name (`security-agent`), directory paths, filenames, class names, spec IDs, vulnerability IDs, or commit hashes directly from the repo outputs.

代わりに：

- `VULN-007` → `Finding-03` または `Critical Finding 3` のような **連番ラベル** に置換
- `contracts/src/ShieldedTransfer.sol` → "Shielded Transfer Contract" のような **記述名** に置換
- コード抜粋が必要な箇所では識別子をリネーム（`VerifierRoutine` ／ `MerkleUpdater` 等のプレースホルダ）

これにより、監査レポートが **コードベース固有名に依存せず単独で読める** 文書になります。学会や顧客への提出時に重要な性質です。

### 4.3.4 入力データソース

| データソース | 用途 |
|---|---|
| `outputs/01_SPEC.json` ／ `01_PROP.json` | 要件、不変条件、信頼前提、アクター役割 |
| `.git/HEAD` ／ `git log` | コミット情報、監査期間 |
| `outputs/03_AUDITMAP.json` | 全所見（severity、category、対象コンポーネント、修正状況） |
| `outputs/03b_FUZZING_RESULTS.json` | ファズテスト結果（あれば） |
| `outputs/02_CHECKLIST.json` | 監査チェックリスト（未着手・未解決項目の特定） |
| `outputs/` 配下の補助ファイル | 修正サマリ、確認ログ |

### 4.3.5 設計判断

- **「報告書だけ読めば文脈が分かる」を要求**：パスや ID を見せない代わりに、ナラティブ（叙述）テキストでコンポーネントを説明する
- **学会 Artifact Evaluation の取得を意識**：論文付随の監査ケーススタディとしても提出可能なフォーマット
- **再ラベリングの内部マップ**：レポート内では `Finding-01` を使うが、内部的には元の `VULN-*` ID へのマッピングを保持して整合性を担保

---

## 4.4 マニュアルフェーズの位置づけ

自動 6 フェーズが **「監査の本体」** だとすれば、マニュアルフェーズは **「監査結果を成果物に変換するレイヤ」** です：

```
[自動 6 フェーズ]                      [マニュアルフェーズ]
仕様 → サブグラフ                  ↘
   → プロパティ                       ↘
   → コード位置 → 監査                 ─►  /05_poc        → PoC テスト
   → レビュー (CONFIRMED_*)            ─►  /06_report     → バグバウンティ報告書
                                        ─►  /07_audit_report → 包括的監査レポート
```

### なぜマニュアル実行なのか

- **すべての所見を PoC 化／レポート化する必要はない**：開発者・依頼主が「どれを優先するか」を判断する余地を残している
- **生成物がコードベース／報告書プラットフォームに直接書かれる**：コミット・送信は人間判断であるべき
- **コストの観点**：Phase 03 の数百〜数千所見すべてに PoC を生成すると非現実的なコストになる

### マニュアルフェーズと CI

CI／CD 上では `01a` → `04` までを `full-audit.yml` で自動実行し、その後の PoC／レポート化は **PR レビュー後に人間がトリガー** する運用が想定されています。

---

## 4.5 章のまとめ

- マニュアルフェーズは「監査結果を成果物に変換」する層であり、自動パイプラインとは異なる責任を持つ
- フェーズ 05（PoC 生成）は **言語自動判定＋自己修復ループ** を持つことで、Rust／Solidity／Go／C/C++ いずれにも対応
- フェーズ 06（バグバウンティ報告書）は **プラットフォーム別 Markdown テンプレート** を埋め込む構造で、5 大プラットフォームに対応
- フェーズ 06b（フルレポート）は **「リポジトリ内部名の禁止」** という強い制約を持つ、出版可能レベルのドキュメント生成
- いずれも「生成物を人間がレビューしてから commit／提出する」ことを前提にした手動操作

次章では、これら全フェーズを支えている **オーケストレータ** の内部構造を解説します。

---

## 4.6 参考文献

- `prompts/05_poc.md`
- `prompts/06_report.md`
- `prompts/06b_audit_report.md`
- `docs/report_templates/`（Cantina／Code4rena／Ethereum／Immunefi／Sherlock 各テンプレート）
