# 興味プロファイル深掘り分析（更新版）

**スナップショット作成日:** 2026-06-09
**分析対象:** `bookmarks/bookmarks-2026-03-25.md` ～ `bookmarks/bookmarks-2026-06-03.md`（`.old` と `bookmarks-comment-*.md` は除外）、計 約 820 件のブックマーク
**前回スナップショット:** [`interest-profile-2026-05-26.md`](./interest-profile-2026-05-26.md)（〜 6/3 分は親ディレクトリから補完して同じ範囲を見ていたが、bookmarks/ 配下に揃ったので統一して再集計）
**新規追加期間:** 2026-05-27 ～ 2026-06-03（約 9 日間 / 60〜70 件相当）
**目的:** 前回プロファイルから何が変わったかを浮き彫りにし、Topics 生成の xsearch クエリと選別軸を更新する。

---

## 0. 前回スナップショット（5/26 基準）からの差分（Δ）

### 新登場・存在感が増した著者

- **@izutorishima** — 件数 +60%。「Opus 4.6 が日本語力 / EQ の到達点」「Mythos の脆弱性発見特化と汎用性のトレードオフ」など、**質的なモデル比較記事**で軸を形成
- **@npaka123** — ローカル LLM リリース年表 / ROBOMETER / DGX Spark 実検証 / Qwen3.8 評価などの**詳細記事化スタイル**で頻度上昇
- **メディア系の新規流入** — @nikkei、@nhk_news、@TechnoEdgeJP（Anthropic IPO、人工知能学会 NSX、医療 LLM など**政策・企業戦略ニュース**）
- **実装者の新規流入** — @azukiazusa9（Dynamic Workflow 試用）、@VinayKrKatiyar、@ClaudeCode_love（物理シミュレーション）
- **評価系の新規流入** — @itm_aiplus、@ArtificialAnlys、@MLBear2（マルチプラットフォーム AI ニュース）

### 関心が強まった軸（5 → 6 軸へ拡張）

1. **「モデルの特性別分業の複雑化」** ← 前回の「Qwen 圧倒」から、Opus 4.6（日本語・EQ）× Opus 4.8（コーディング）× GPT-5.5（論文）× Qwen3.7-Max（エージェント）× Mythos（脆弱性発見）の**5 モデル分業**へ
2. **Dynamic Workflows（マルチエージェント動的編成）** ← 5/28-29 に集中投稿。「並列マルチエージェントの実用化フェーズ」入り
3. **DeepSWE（汚染対策・Agent-as-Judge）** ← 「メディア値を疑う」段階から「**正しい測定方法を構築する**」段階へ深化
4. **セキュリティガイダンス × エージェント実装** ← Anthropic ゼロトラスト Playbook、Hook 設計、`security-guidance` プラグインなど**実装ガイドライン化**
5. **Mythos 級モデルの「特化」工業化の困難さ** ← 脆弱性発見能力だけ伸ばすと一般コーディング能力が落ちる、というアラインメントタックスの議論
6. **日本語医療 LLM・国産ファウンデーション戦略**（新カテゴリ）← さくら ＋ NEDO・東大、人工知能学会 NSX 構想

### 注目モデル名の入れ替わり

| 動き | モデル |
|---|---|
| **新登場・急上昇** | Claude Opus 4.8、Qwen3.7-Max / Plus、Microsoft MAI-Image-2.5 / MAI-Thinking-1、NVIDIA Cosmos 3、MiniMax M3 |
| **下降・相対化** | Gemini 3.5 Flash、Mistral 系、Claude Opus 4.7（4.8 登場で「従来型」に）、Gemma 4（前期の急上昇は沈静） |

### 縮小・停止した関心

- **TurboQuant 単体の技術深掘り** が言及低下。代わりに「**Qwen の MTP（Multi-Token Prediction）**」など、より高レベルな機能側で量子化を語る流れへ移行
- 「ローカル LLM の敷居・工夫」を語る記事は減り、「**モデル選定と分業**」を語る記事が増加

### 新しいカテゴリ／キーワード

- **Agent-as-Judge** ベンチマーク設計
- **マルチモーダルエージェント**（テキスト + 画像 + 音声を 1 モデルで）
- **GUI / CLI 統合エージェント**（Anthropic Managed Agents、Alibaba Qwen3.7-Plus、Microsoft Scout など）
- **日本語医療 LLM 共同開発**

---

## 1. ハイレベルな興味分類（更新版）

| カテゴリ | 概算件数 | 前回比 | 概要 |
|---|---|---|---|
| **Claude Code / Opus 4.8・4.6・Codex 環境構築と実運用** | 80〜85 件 | +15 | UX から「実務的フロー」へ。Opus 4.8 の「誠実さ」と「判断力」、Codex / Composer との三角分業、Dynamic Workflows |
| **ローカル LLM × Qwen3.7 系実用化** | 45〜50 件 | -30 | 引き続き高関心。個別の量子化テクニックより「Qwen3.7-Max/Plus のマルチモーダル・エージェント機能」へシフト |
| **Dynamic Workflows / マルチエージェント編成** | 35〜40 件 | **新軸 +20** | Claude Code の新機能、Hermes Desktop、個人開発者向け基盤 |
| **ベンチマーク・実測値懐疑（DeepSWE 等）** | 25〜30 件 | +10 | 「メディア値との乖離」から「方法論の検証」へ |
| **モデル間の言語能力 / EQ 差分** | 20〜25 件 | **新軸 +10** | Opus 4.6 が日本語力で 4.8 / GPT-5.5 を上回るという質的評価 |
| **セキュリティ × エージェント実装** | 18〜22 件 | +8 | Hook 設計、ゼロトラスト Playbook、`security-guidance`、Agent SDK 非同期パターン |
| **Microsoft AI 戦略（MAI / Copilot / Scout）** | 12〜15 件 | **新カテゴリ +10** | MAI-Image-2.5 / MAI-Thinking-1、WinUI 3 プラグイン、常駐型エージェント Scout |
| **医療・研究向け日本語 LLM** | 8〜10 件 | **新カテゴリ +5** | さくら ＋ NEDO・東大、医学倫理、膵がん新薬報道 |

---

## 2. 頻出著者トップ（全期間）＋ 直近 9 日間の動き

| 著者 | 全期間 | 5/27-6/3 | 特徴 |
|---|---|---|---|
| **@gosrum** | 41 | 5 | ローカル LLM 性能・Qwen 深掘り・Mac Studio 検証。引き続き主軸（新規投稿は安定期） |
| **@umiyuki_ai** | 36 | 2 | マルチモーダル / TTS / Qwen Omni / 中華 API 使い分け。Irodori-TTS v3 で音声合成へ関心維持 |
| **@oikon48** | 33 | 5 | Claude Code 変更点・DeepSWE・Dynamic Workflows。**Anthropic インサイダー視点**は最も安定 |
| **@gigazine** | 32 | 3 | MAI、DeepSWE、AI モデルの睡眠研究など。速報性は維持、件数は微減 |
| **@masahirochaen** | 19 | 2 | Opus Tips、Codex 実装検証、Opus 4.8「本物」検証 |
| **@izutorishima** | 17 | **8** | **新軸開拓**：Opus 4.8 vs 4.6 の言語力 / EQ、Mythos の脆弱性特化トレードオフ、医療 LLM |
| **@tetumemo** | 15 | 3 | Stanford Claude Code 講義、NotebookLM 裏技 |
| **@kinopee_ai** | 13 | 2 | Opus ベンチ比較、Devin 論、コスト分析 |
| **@npaka123** | 10 | **4** | **新出現：詳細記事化**スタイル。ローカル LLM 年表、ROBOMETER、DGX Spark |
| **@ai_database** | 11 | - | ローカル LLM ベンチ周辺（前期は多かった） |
| **@claudeai** | 19 | 1 | Anthropic 公式発表（Opus 4.8） |
| **@AnthropicAI** | 13 | - | 公式アナウンス（前期より減少） |

新規流入：@nikkei、@nhk_news、@TechnoEdgeJP、@azukiazusa9、@itm_aiplus、@ArtificialAnlys、@MLBear2、@VinayKrKatiyar、@ClaudeCode_love

---

## 3. 関心軸（カテゴリの裏にあるテーマ）

前回 5 軸を継続検証 + 1 軸追加。

### 3.1 「実装ノウハウ × コスト戦略」（継続・深化）

- Opus 4.8 Fast mode の「3 倍安く、SWE-Bench 88.6%」評価
- GPT-5.5 xhigh と Opus 4.8 の cost-benefit 比較
- Qwen3.7-Max vs Opus 4.8 の用途別分業
- **変化:** 単なる「安いローカル LLM」から「**モデル特性に応じた組み合わせ最適化**」へ

### 3.2 「長時間自律実行の可能性と限界」（実装フェーズに進展）

- **Dynamic Workflows の登場**で「並列マルチエージェント編成」が具体化
- エージェントのトークンコスト vs アウトカムの問題提起（@t_wada 等）
- Codex `/goal` で「race condition 自動修正」など長時間実行の成功事例
- **変化:** 理論的可能性 → **実務的制約と工夫**

### 3.3 「メディア値 vs 実測値の乖離」（方法論へ）

- **DeepSWE**（91 OSS / 113 Task、カンニング防止、Agent-as-Judge）
- Opus 4.8 CursorBench で「4.7・GPT-5.5 を下回る」体感投稿との一致
- Mythos 脆弱性発見特化の「工業化の困難さ」
- **変化:** 数字を疑う → **正しい測定方法を構築する**

### 3.4 「個人開発者向けローカル AI 生態系」（基盤完成度へ）

- Qwen3.7-Plus の GUI/CLI 統合エージェント
- Hermes Desktop、Nous Research のローカル実行基盤
- **変化:** 単なるモデルダウンロード → **エージェント基盤としての完成度**

### 3.5 「権限・セキュリティの自動化と人間信頼の緊張」（実装ガイドライン化）

- Anthropic「AI エージェント向けゼロトラスト Playbook」eBook
- Claude Code の `security-guidance` プラグイン、Hooks 設計
- `/fewer-permission-prompts` 運用熟成
- **変化:** 概念的な矛盾 → **実装ガイドラインへの昇華**

### 3.6 **新軸：「モデルの特性別分業の複雑化」**

- Opus 4.6（日本語・EQ・汲み取り） + Opus 4.8（コーディング） + GPT-5.5（論文） + Qwen3.7-Max（エージェント） + Mythos（脆弱性）
- 「単一モデル選定」から「目的別マルチモデル戦略」へ
- 特化 vs 汎用のアラインメントタックス論への関心

---

## 4. 反応するコンテンツ形式の比率

| 形式 | 前回 | 今期 | コメント |
|---|---|---|---|
| 実装ノウハウ・Tips・設定例 | 35% | 35% | 引き続き主軸（Dynamic Workflows・Security Hooks の記事増） |
| ベンチマーク・性能比較・失敗談 | 30% | **35%** | **DeepSWE による「正しい測定」への関心上昇**、体感との一致確認記事 |
| メディア速報 | 20% | 15% | 速報量は同じだが「**評価・批判・代替視点の併記**」が標準化 |
| 個人プロダクト・OSS 紹介 | 15% | 12% | Hermes Desktop / Nous Research 等の新基盤は注目、小規模 OSS 紹介は減少 |
| **言語能力・文化的差分の質的評価** | — | **新 +3〜5%** | @izutorishima、@masahirochaen による「Opus 4.8 vs 4.6 の言語力」など |

---

## 5. 注目している製品・OSS・モデル名（実名・更新版）

### モデル — 追加・昇格

Claude Opus 4.8（5/28 登場で即バズ）、Qwen3.7-Max / Qwen3.7-Plus、Microsoft MAI-Image-2.5、MAI-Thinking-1、NVIDIA Cosmos 3（T2I/I2V オープンウェイト 1 位）、Alibaba Qwen3.7-Plus（GUI/CLI 統合）、MiniMax M3

### モデル — 相対的に下降

Gemini 3.5 Flash、Mistral、Claude Opus 4.7、Gemma 4

### ツール / インフラ

Claude Code Dynamic Workflows、`security-guidance` プラグイン、Hermes Desktop、Nous Research インフラ、DGX Spark、Anthropic Managed Agents、Microsoft Scout（常駐型）

### ベンチマーク・評価フレームワーク

- **DeepSWE（新）** — 91 OSS / 113 Task、汚染対策、Agent-as-Judge
- CursorBench 3.1（Opus 4.8 評価）
- SWE-bench（方法論検証の深化）
- ts-bench（コーディングエージェント専門）

### 量子化 / 最適化

- **MTP（Multi-Token Prediction）** — Qwen3.6/3.7 で速度 2 倍化（RTX 5090 / Mac MLX-VLM）
- Pure Quant（16GB VRAM で Qwen3.6-27B 爆速化）
- TurboQuant（言及減）

---

## 6. AI 関連以外の興味

前回と同様の分野を継続。**追加・更新:**

- **医学・研究** — 膵がん新薬ダラクソンラシブ（1 年生存率 53.3% vs 18.8%）、**日本語医療 LLM 共同開発**（新）、医学会の異例スタンディングオベーション
- **OS・ハードウェア** — Mac Studio、RTX 5060 Ti、NVIDIA Cosmos、**Windows リモート操作（UAC・権限分離）**（新）
- **ハード雑** — カシオ ER-100 イヤホン、CFD SSD 入荷情報
- **法律・社会** — ストーカー規制、刑罰の奇妙さ、**人工知能学会会長 NSX 構想**（新）
- **文化・歴史** — 江戸期女性武芸者（仙台藩別式女）など

---

## 7. xsearch クエリ案（更新版 / 前回 9 本との対応）

### 維持・更新（前回 9 本のうち継続）

| # | クエリ | 状態 |
|---|---|---|
| 1 | `"Claude Code" Dynamic Workflows agent parallel subagent 2026` | **更新** — 「auto mode」から「Dynamic Workflows / 並列」へ |
| 2 | `Qwen3.7 Max Plus benchmark multimodal agent 2026` | **更新** — 3.6 系 → 3.7 系へ |
| 3 | （TurboQuant クエリ） | **廃止** — 言及低下、より高レベルへ |
| 4 | `DeepSWE benchmark SWE-bench contamination agent-as-judge` | **深掘り** — 方法論検証へ |
| 5 | `"Managed Agents" deployment serverless infrastructure 2026` | 継続 |
| 6 | `Opus 4.8 4.6 Japanese language capability EQ vs GPT-5.5` | **更新** — コスト分析から言語力・EQ 質的差分へ |
| 7 | `Qwen3.7 MTP local LLM agent performance 推論速度` | **更新** — MTP による高速化が新主流 |
| 8 | `"Claude Code" security-guidance zeroTrust hooks agent-mode` | 継続 |
| 9 | `"ai-topics" "deep research" methodology evaluation` | 継続（メタ評価） |

### 新規追加（3 本）

| # | クエリ | 狙い |
|---|---|---|
| 10 | `"Mythos" vulnerability specialization coding tradeoff alignment tax` | 特化と汎用のトレードオフ問題 |
| 11 | `Microsoft MAI-Image MAI-Thinking Scout multimodal reasoning 2026` | MS の新しいライバル戦略 |
| 12 | `"医療 LLM" "日本語" NEDO さくら foundation model` | 国内医療ファウンデーション LLM の動向 |

---

## 8. このユーザーの読み手像（更新）

**表面的なカテゴリ消費ではなく、「技術の実行可能性・コスト・トレードオフ」を重視**する姿勢は不変。さらに今期は次の方向に深化：

- 「数字を疑う」から「**正しい測定方法を構築する**」へ（DeepSWE）
- 「最強モデル選び」から「**モデル特性別の分業設計**」へ（5 モデル併用）
- 「概念的なセキュリティ懸念」から「**実装ガイドラインとしての Hook / Playbook**」へ
- 「ローカル LLM の敷居を下げる」から「**エージェント基盤としての完成度**」へ

### Topics 生成での運用方針（更新）

- SEO インフルエンサー型（"Every guru is lying" など）は引き続き除外
- 速報そのものより「**速報を踏まえた実務的評価**（コスト、Tips、運用知見）」を優先
- ベンチ高得点ニュースには必ず「**反対意見・脆弱性・代替ベンチ（DeepSWE）**」を併記
- ローカル LLM 系は「量子化・速度・GPU/Mac 別の具体値」で語っているものを優先
- **モデル分業を語っている記事**（Opus 4.6 vs 4.8、Qwen3.7-Max のエージェント性能比較など）を積極採用
- Dynamic Workflows / Managed Agents の**実装記事**は実行可能性に注目して採用
- 国内政策・医療 LLM など**日本語ソース固有のニュース**を意識的に拾う
- ハード／医学／法律系の硬派なニュースは、関心軸に当たっていれば AI と並べて拾う

---

## 9. 更新ポリシー

- このプロファイルは **2026-06-03 までのブックマーク**を基準としたスナップショット。
- 関心軸は数週間〜数ヶ月単位で変動する。新しいブックマークが累積して傾向がずれてきたら、同じ方法（カテゴリ集計 + 頻出著者 + 反応コンテンツ形式の比率算出 + 前回 Δ）でアップデートする。
- 次回更新時は別ファイル（`interest-profile-YYYY-MM-DD.md`）として保存し、過去版を残す。
- 前回版：[`interest-profile-2026-05-26.md`](./interest-profile-2026-05-26.md)
