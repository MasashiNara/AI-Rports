# 興味プロファイル深掘り分析

**スナップショット作成日:** 2026-06-09
**分析対象:** `bookmarks/bookmarks-2026-03-25.md` ～ `bookmarks/bookmarks-2026-05-26.md`（および親ディレクトリの `bookmarks-2026-05-27.md` ～ `bookmarks-2026-06-03.md`）、計 約 757 件のブックマーク
**目的:** Topics 生成の際に、表層的なカテゴリ分類（Claude / OpenAI / Models / Security…）では取りこぼしが多いというフィードバックを受け、**ブックマークの裏にある関心軸・価値観・スタンス**を抽出して xsearch クエリ設計と URL 選別に使う。
**初出:** `Topics/topics-2026-06-02.{md,html}` 生成時に使用。

---

## 1. ハイレベルな興味分類（カテゴリ）

| カテゴリ | 概算件数 | 概要 |
|---|---|---|
| **Claude Code・Opus 環境構築と UX** | 65〜70件 | auto mode、permissions、effort level、slash commands の機能活用。実装ノウハウより UI/インタラクション設計に関心 |
| **ローカル LLM・Qwen 系実用化** | 約 80件 | メモリ効率（quantization、TurboQuant）、推論速度、Mac/GPU での動作検証。「Mac 32GB+ でフロンティアモデルより快適」という実務的価値判断 |
| **エージェント・マルチエージェント・ハーネス** | 40+件 | Code as Agent Harness、Managed Agents、ワークフロー設計。「long-running agent」パラダイムへの深い理解 |
| **ベンチマーク・言語横断評価** | 35+件 | SWE-bench、MRCR v2、NanoGPT-Bench、ts-bench。「実ベンチでの一貫性」vs「メディア値」の乖離に気づく視点 |
| **セキュリティ・脆弱性・権限周辺** | 25+件 | API key 自動探索、ShadowPrompt 脆弱性、auto-mode の暴走。「自動化の危険性」への現実的な対応 |

---

## 2. 頻出著者トップと特徴

| 著者 | 件数 | 特徴 |
|---|---|---|
| **@gosrum** | 41 | ローカル LLM 性能評価・Qwen 深掘り・Mac Studio で推論速度検証。「低パラメータの圧倒的性能」を繰り返し発信 |
| **@umiyuki_ai** | 37 | マルチモーダル AI・TTS・Qwen Omni・「ローカル & 中華 API 使い分け」。実装ファーストで速度感優先 |
| **@oikon48** | 34 | Claude Code 変更点・implementation-notes・Devin Auto-Triage。Anthropic 動向とツール進化を追う「インサイダー視点」 |
| **@gigazine** | 32 | テックニュース集約（DeepL、Google I/O、Mistral TTS）。速報性と実装紹介のバランス |
| **@masahirochaen** | 19 | Opus Tips スレッド、コスト戦略（`/ultrareview` $5-20）、実務的な使い分け |
| **@izutorishima** | 17 | 「Opus 4.6 日本語力・EQ」vs「Opus 4.8 コーディング偏重」など文化的観点、モデル差分の質的評価 |

---

## 3. 関心軸（カテゴリの裏にあるテーマ）

カテゴリ分けでは見えない、**「なぜこれをブックマークしたか」の動機**。

### 3.1 「実装ノウハウ × コスト戦略」

tips / 設定例よりも**「何をいくらで動かせるか」**への関心。Qwen3.6-35B（ローカル）vs Opus（API）の「仕事別分業」論が 10+件。

### 3.2 「長時間自律実行の可能性と限界」

long-running agent、Managed Agents、「2-3 時間では不足」という実タスク観。Mythos 脆弱性発見能力の非公開化も「**暴走防止**」の観点から注視している。

### 3.3 「メディア値 vs 実測値の乖離」

「Gemini 3.5 Flash は $1.5 価格でも Opus より精度低い」「SWE-bench 93.9% はループ脆弱性での水増し」という**懐疑的読解**。

### 3.4 「個人開発者向けローカル AI 生態系」

Mac Studio、RTX 4060 Ti での GGUF 量子化、LM Studio の MTP 対応。「クラウド囲い込み」への抵抗。

### 3.5 「権限・セキュリティの自動化と人間信頼の緊張」

auto-mode で「許可判断を Claude に委任」vs「.env にキー置くな」という相反する要求。ユーザーは**「自動化の便利さ」と「暴走防止」の両立**を求める。

---

## 4. 「反応する」コンテンツ形式の比率

| 形式 | 比率 | 例 |
|---|---|---|
| **実装ノウハウ・Tips・設定例** | 35% | Claude Code slash commands、Opus effort level、ローカル LLM のメモリ最適化「llama.cpp に TurboQuant 実装」など |
| **ベンチマーク・性能比較・失敗談** | 30% | 「SWE-bench 73.4% は脆弱性発見水増し」「Gemini Omni のキャラリファレンス不十分」という批判的検証 |
| **メディア速報** | 20% | Google I/O、Anthropic IPO、OpenAI 訴訟などだが、必ず**「実務への落とし込み」での評価**（「価格 3 倍に見合わず」など） |
| **個人プロダクト・OSS 紹介** | 15% | Antigravity 2.0、Stainless SDK、Unsloth ノートブック。ただし「使ってみた」ローカル検証付き |

---

## 5. 注目している製品・OSS・モデル名（実名）

**モデル**
Claude Opus 4.7 / 4.8 / Mythos、Qwen 3.6-27B / 35B / 3.7-Max、GPT-5.5、Gemini 3.5 Flash / Omni、Gemma 4、Mistral、Kimi K2、Composer 2.5

**ツール / インフラ**
Claude Code 2.1.111+、Cursor、Devin Auto-Triage、Antigravity 2.0、Managed Agents、Hermes Agent、Gemini Spark、DGX Spark、Mac Studio M2 Ultra

**量子化 / 最適化**
TurboQuant、Unsloth、GGUF、llama.cpp、1-bit Bonsai、MTP（Multi-Token Prediction）

**評価フレームワーク**
SWE-bench、MRCR v2、NanoGPT-Bench、ts-bench、CursorBench 3.1

---

## 6. AI 関連以外の興味

- **OS・ハードウェア** — Mac Studio、RTX 4060 Ti、RTX 5060 Ti、M5 Air、MacBook Neo、NVIDIA Cosmos
- **生活・技術系** — 焼肉の煙対策（卓上換気扇 AirHood2）、段ボール製ドローン、カシオのイヤホン ER-100、PC パーツ情報（SSD 入荷情報）
- **法律・社会** — 著作権（同人誌 vs 海賊版）、ストーカー規制法、刑罰の奇妙さ、医学倫理（膵がん臨床試験）
- **医学・健康** — ワクチン疫学、若者突然死研究、医療費改正、医学会の異例対応

---

## 7. xsearch クエリ案（関心軸ベース、カテゴリ超越）

通常のカテゴリベース（"Claude Code latest"、"local LLM benchmarks" など）だけだと取りこぼしが多いため、上の関心軸を直接埋め込んだクエリ案：

1. `"Claude Code" auto mode agent workflow 2026` — 長時間エージェント実装
2. `Qwen 3.6 35B local LLM benchmark RTX Mac` — ローカル LLM の実用化検証
3. `"TurboQuant" "Llama.cpp" quantization memory efficient` — 推論最適化の技術深掘り
4. `SWE-bench "Mythos" vulnerability safety tradeoff` — メディア値 vs 実測値
5. `"Managed Agents" infrastructure serverless deployment` — エージェント本番運用
6. `Opus 4.8 cost analysis Japanese capability vs GPT-5.5` — モデル間の文化的・言語的差分
7. `ローカル LLM Qwen 推論速度 メモリ効率 実運用` — 日本語個人開発者向け実装
8. `"Claude Code" /fewer-permission-prompts security auto-mode risk` — 権限・セキュリティの緊張
9. `"ai-topics" "deep research" methodology evaluation` — メタ的に「どうクエリ設計すべきか」

---

## 8. まとめ — このユーザーの読み手像

**表面的なカテゴリ消費ではなく、「技術の実行可能性・コスト・トレードオフ」を重視**。メディア煽りより**実測値と失敗事例**に反応する、極めて実務的で批判的な目利き。

Topics 生成では：

- SEO インフルエンサー型の煽り post（"Every guru is lying"、@JulianGoldieSEO 系）は採用を抑える
- 速報そのものより、**速報を踏まえた実務的評価**（コスト、Tips、運用知見）を優先する
- ベンチマーク高得点ニュースには必ず**反対意見・脆弱性・代替ベンチ**を併記する
- ローカル LLM 系は**量子化・速度・GPU/Mac 別**の具体値で語っているものを優先
- 個人開発者の Tips（Tips スレッド、否定形プロンプト、コスト戦略）は積極採用
- ハード／医学／法律系の硬派なニュースは、関心軸に当たっていれば AI と並べて拾う

---

## 9. 更新ポリシー

- このプロファイルは **2026-05-26 までのブックマーク**を基準とした**スナップショット**。
- 関心軸は数週間〜数ヶ月単位で変動する可能性がある。
- 新しいブックマークが累積して傾向がずれてきたら、同じ方法（カテゴリ集計 + 頻出著者 + 反応コンテンツ形式の比率算出）でアップデートし、ファイル名のスナップショット日付を更新する。
- 次回更新時は別ファイル（`interest-profile-YYYY-MM-DD.md`）として保存し、過去版を残す。
