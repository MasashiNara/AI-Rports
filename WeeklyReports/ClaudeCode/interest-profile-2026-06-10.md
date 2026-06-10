# 興味プロファイル interest-profile-2026-06-10

**分析対象**: `bookmarks/` および直下の `bookmarks-2026-03-25.md` 〜 `bookmarks-2026-06-10.md`（計 **848 件**、2026-03-25〜2026-06-10）
**用途**: 毎日の X (Twitter) 検索で「このユーザーが好きそう／ブックマークしそうなツイート」を自動ピックアップするための、**深い関心軸＋判定基準**。カテゴリ分類だけでは取りこぼすため、「なぜ刺さるのか（動機・角度・嗜好）」まで言語化している。

---

## 0. このユーザーを一言で

**「動かす側」の AI エンジニア。** 単なる AI ニュース消費者ではなく、(1) AI コーディングエージェントを**自分の運用設計（ワークフロー・分業・自動化）**として突き詰め、(2) ローカル LLM を**自分の手元で速く動かす工学**として追い、(3) モデルやベンチに対して**懐疑と検証の目**を持ち、(4) AI 時代のソフトウェアエンジニアリングと職業を**メタに省察する**——という 4 つの軸が中心。表面的な「○○がリリースされた」より、**「どういう仕組みで」「実際に動かすとどうか」「それは本当か」「人間の仕事はどう変わるか」**に強く反応する。

**嗜好の指紋（これが揃うほど刺さる）**：
- **機構・内部実装の解説**（"how it works"）＞ 単なる発表（"it launched"）
- **実践者のフィールドノート**（実際に回して tok/s・エラー率・ハマりどころを報告）
- **懐疑・批判・幻滅の解毒**（ベンチマックス疑い、性能低下報告、ハイプ冷却）
- **メタ・省察**（AI 活用の認識論、職人性、職業論）
- **日本語性能・日本の産業**への目配り

---

## 1. 関心軸（深掘り）

### 軸A：AI コーディングエージェントの「運用設計・メタワークフロー」★最重要
製品を使うこと自体ではなく、**どう組織し、どう自律させ、どう人間が監督に回るか**に執着。
- **役割分業パターン**：「Opus が設計・要件 → Codex/GPT が実装 → Opus がレビュー」の三段運用、設計＝Opus max / 検証＝Opus xhigh / 実装＝Sonnet の分業。モデルを"チーム"として編成する話。
- **自律実行の仕組み**：`/goal`・Dynamic Workflows・サブエージェント編成・**敵対的サブエージェントにレビューさせる**・auto mode・Routines（cron/GitHub トリガー）・「上司AIが下僕AIに完了判定までやらせる」。
- **人間＝監督者へのシフト**：Boris Cherny のアーキテクチャ（3 エージェント＋3 指示書＋1 パイプライン）、「監督から方向づけへ」、制約でなく文脈を渡す、ゴールと検証手段を与える。
- **運用 Tips の現場知**：進捗が見えない問題を TODO＋報告ルールで解消、Skill 化で同じエッジケースを繰り返さない、CLAUDE.md/AGENTS.md の扱い、権限プロンプト削減、grep 直探索 (DCI) ＞ ベクトル RAG。
- 反応する発信者：bcherny, oikon48, masahirochaen, suna_gaku, fladdict, tetumemo, izutorishima, gosrum, t_wada, 公式(claudeai/ClaudeDevs/AnthropicAI)。

### 軸B：ローカル LLM を「速く・安く動かす」工学 ★最重要
**効率化のメカニズム**そのものが好物。スペックと実測値に強く反応。
- **量子化・推論高速化技術**：TurboQuant / RotorQuant、1-bit・Ternary Bonsai、Pure Quant、MTP（複数トークン同時予測）、KV キャッシュ量子化、投機的デコード(DFlash)、TileRT、エキスパートの動的 GPU コピー（LuceSpark）、ngram-mod。
- **ハードウェア構成と実測**：DGX Spark、RTX 5090/4070/4060 Ti、Mac Studio M2 Ultra、**AMD 2 枚挿し VRAM 48GB**、Ryzen AI Max（192GB で 300B 実行）、Skymizer/HTX（240W で 700B）。**tok/s・prefill/decode・PPL・VRAM 要件**の数字に必ず反応。
- **オープンモデル（特に中国勢）の追跡**：Qwen 3.5〜3.7（Max/Plus/27B/35B-A3B）、DeepSeek V4、Kimi K2.x、MiMo（Xiaomi）、MiniMax M2.7/M3、GLM、ERNIE、Gemma 4。「結局どれが強い？」「どうせベンチマックス、Reddit が騒ぐまで待ち」という**実力見極めの態度**込み。
- **ツール**：llama.cpp、Unsloth、LM Studio、opencode、ts-bench（CLI Tool Call うまさ評価）。
- 反応する発信者：umiyuki_ai, gosrum, ai_hakase_, kis, karaage0703, nemumusitocha, npaka123, UnslothAI, 2022_technology。

### 軸C：モデルリリース追跡＋「ベンチマーク懐疑」 ★最重要
新モデルは全部押さえるが、**鵜呑みにしない**のが本質。
- フロンティア全社を網羅：Claude(Opus 4.7/4.8, Fable 5/Mythos 5)、GPT-5.5/5.6、Gemini 3.5(Flash/Omni/Spark)、Qwen/DeepSeek/Kimi 等。
- **懐疑のレンズ**：「ベンチマックスしただけでは」、**ベンチ汚染**（SWE-bench は訓練できる＝汚染、DeepSWE/FrontierCode はコード品質も見る）、ベンチと実タスクの乖離、**性能低下の現場報告**（Notion が Claude 停止、Opus 4.8 で "tool call could not be parsed" 頻発、Opus 精度急落説）。
- リリース解説で頼る発信者：itnavi2022, masahirochaen, MLBear2, oikon48, kinopee_ai, umiyuki_ai。**朝のニュースまとめ**（MLBear2, tetumemo）も定番。

### 軸D：Anthropic / Claude の「企業・戦略・思想」 ★重要
ほぼ"ファン兼アナリスト"。製品だけでなく会社と哲学を追う。
- **戦略・事業**：IPO 申請、Project Glasswing、Managed Agents → プラットフォーム企業への転換、価格/クレジット体系、提携（日立 10 万人育成、SpaceX/Colossus）、独自チップ検討、早期黒字化＝AIバブル説への反論。
- **安全・思想**：Mythos の安全策（危険クエリを Opus にフォールバック）、AI 憲法と MSM、**RSI（再帰的自己改善）ブログ**（社内マージの 80% が Claude、52 倍高速化）、解釈可能性（NLA、感情ベクトル、ピノキオ次元）、AI 人格を哲学者・聖職者と議論。
- **"エモい"側面**にも反応（「夢を見る＝/compact」「逆質問された」EQ 観察など）。

### 軸E：AI 時代のソフトウェアエンジニアリング論・職業論 ★重要
リフレクティブな技術者の顔。**craft と epistemics**。
- t_wada 系：AI 時代の TDD、変更最小化バイアスの由来、品質・後方互換。
- **認識論的警鐘**：「認知的降伏が理解負債を生む」「危険なのは AI の誤答でなく人間が評価する練習をしなくなること」「Claude Code で概念理解 17% 低下」「AI 使いこなしが形式知化できない＝魔法・ニュータイプ的デバイド」。
- コードレビューは AI に任せるべき論、AI 査読で粗悪論文を desk reject、シニアの暗黙知がうまく伝わらない問題。

### 軸F：セキュリティ（サプライチェーン攻撃・脆弱性・AI 特有リスク） ★重要
実務的な防御者意識。
- **サプライチェーン攻撃**：npm/PyPI（axios, Shai-Hulud, Trivy/Cisco 流出, WordPress バックドア）、npm の段階的リリース対策。
- **CVE / ゼロデイ**：NGINX(CVE-2026-42945), 7-Zip, Adobe Reader, Linux カーネル Copy Fail。
- **AI 特有リスク**：プロンプトインジェクション（ShadowPrompt, 不可視文字）、Claude Code の deny ルール突破、auto mode が secrets を勝手に探索、Claude Code/Codex に機密を入れる是非、Mythos の脆弱性発見能力。
- 反応する発信者：yousukezan が筆頭。AnthropicAI のセキュリティ検証、security-guidance プラグイン。

### 軸G：AI インフラ・半導体・テック産業マクロ ☆中
- 光通信(IOWN/APN)、**エージェント化で CPU 需要増**（GPU:CPU 比 8:1→1:1、メモリ/ストレージ逼迫、Intel 株高、Kioxia）、AI アクセラレータ(Skymizer)、量子コンピュータ(Majorana 2, 東芝疑似量子)、耐量子暗号。
- AI 企業の規模感（時価総額 vs 売上、3 大 AI IPO 同週進行）。

### 軸H：医療・健康・科学ニュース ☆中（一貫した副関心）
- **がん・新薬**：膵がん新薬の歴史的ブレイクスルー（スタンディングオベーション）、GLP-1/マンジャロ、高額療養費制度改正。
- **疫学・批判的態度**：コロナワクチンと若年死の無関連研究、テストステロンと寿命、脳の老化、新型コウモリコロナの性状解析。
- 知念実希人 (MIKITO_777) の医療現場・医療リテラシー発信が定番。
- 物理・基礎科学（反陽子輸送、木製トランジスタ、カーボンナノチューブ電線、古代昆虫巨大化）。

### 軸I：日本のテック・産業・政策・主権 ☆中
- さくらインターネット（ガバメントクラウド、AI Engine、医療 LLM 共同開発）、GENIAC/NEDO、人工知能学会「日本は同じ失敗を繰り返す」NSX 構想、ELYZA（法令検索特化）、NII コーパス、日本語 TTS（sarashina, Irodori-TTS, Aratako）、富士フイルム再生医療、段ボールドローン、日立。
- 「日本語性能」へのこだわり（Gemma 4 の日本語、LiquidAI 1B-JP、日本語 OCR yomitoku）。

### 軸J：個人開発・自作ツール・UX 発明 ☆中
- AI ローマ字日本語変換 IME 自作、AITuberKit、自作リアルタイム翻訳 CLI、Hermes Agent で $24K スタック置換、Obsidian+AI コンテキスト管理、単一 HTML 成果物。「自分で気の利いたものを作った」系。

### 軸K：表現の自由・オタク文化・社会論 ☆中（オピニオン枠）
- 反検閲・反規制が基調：ポリコレ/検閲、BL とフェミニズム理論の矛盾、海賊版 vs 同人、表現規制、「美少女は性別でなく概念」、オタク迫害史、セックスワーカー規制、創作と児童安全。
- 時事・政治は時々（近親婚と自由意思、南京教育、クリミア、国会議員ボーナス論）。**議論・論考の質**で拾う。

### 軸L：画像・動画・音声・3D 生成 ☆中（ニュース寄り）
- GPT-Image2/Nano Banana、Gemini Omni / NVIDIA Cosmos 3（Mixture-of-Transformers）、TTS（VibeVoice, ElevenLabs 値下げ）、3D 生成（TRELLIS.2, Apple LiTo）、リアルタイム翻訳。テキスト/コーディングより一段ライトな"押さえておく"枠。

---

## 2. よくブックマークする発信者（優先巡回リスト）

| 階層 | アカウント | 主な守備範囲 |
|---|---|---|
| **最優先** | umiyuki_ai, gosrum | ローカル LLM 技術解説・実測、懐疑的論評、中国モデル |
| **最優先** | oikon48 | Claude Code 変更点・新機能の一次解説 |
| **最優先** | izutorishima | モデル評・日本語/EQ・nerf 論・懐疑 |
| 高 | masahirochaen, itnavi2022, MLBear2, tetumemo | リリース解説・朝のニュースまとめ |
| 高 | ai_hakase_, kis, nemumusitocha, npaka123, karaage0703, UnslothAI | ローカル LLM・量子化・ハード実測 |
| 高 | claudeai, AnthropicAI, ClaudeDevs, bcherny, nukonuko | Anthropic 一次情報・運用 Tips |
| 高 | ai_database | LLM 認知・記憶・エージェント研究の論文紹介 |
| 中 | t_wada, kinopee_ai, omarsar0, suna_gaku, fladdict, super_bonochin | SE 論・ベンチ評価・ハーネス研究・実践 Tips |
| 中 | yousukezan | セキュリティ・脆弱性・サプライチェーン |
| 中 | MIKITO_777(知念実希人) | 医療・健康リテラシー |
| 中 | pc_watch, gigazine, impress_watch, itmedia_news, akibablog | テックニュース（機構・実測寄りを優先） |
| 中 | russianblue2009, kunihirotanaka | 日本の深掘り技術・産業 |

> これらの**新規投稿は無条件で候補**に入れてよい。ただし軸との適合（下の判定）でランク付けする。

---

## 3. ピックアップ判定（downstream の検索・選別ルール）

### 強い「拾う」シグナル（＋）
- **機構・内部実装の解説**：「どう動くか」「なぜ速い/安いか」を図解・分解している。
- **実測値つきフィールドノート**：tok/s, prefill/decode, VRAM, PPL, エラー率, コスト, 完了時間。実際に回した報告。
- **エージェント運用設計**：role 分業、/goal、Dynamic Workflows、subagent、敵対的レビュー、skill 化、auto/permission 設計。
- **懐疑・検証・幻滅の解毒**：ベンチマックス疑い、ベンチ汚染、性能低下の再現報告、ハイプ冷却、「実タスクではどうか」。
- **モデル/ツールの新着**（特に Claude/Anthropic、Qwen/DeepSeek/Kimi/MiMo/MiniMax/Gemma、Claude Code/Codex/Gemini CLI）。
- **AI×職業/認識論の省察**、**日本語性能/日本の AI 産業**、**サプライチェーン/CVE/AI セキュリティ**。
- **医療新薬・健康科学の確かな話題**、**効率化・自作ツールの発明**。

### 「落とす」シグナル（−）
- 純粋なサブスク誘導・アフィ・SEO インフルエンサー型の煽り（「これ知らないとヤバい」式）。
- 中身のない速報の二次拡散（機構も実測も論評もない単なる "出た" だけ）。
- 一般的すぎるビジネス自己啓発、スピリチュアル、芸能・スポーツゴシップ。
- 政治・社会論のうち、**論考の質が低い**罵倒・党派的バズだけのもの（軸K は"質の高い論考"のみ）。
- 暗号資産の値動き煽り（ただし計算機資源/51%攻撃のような**CS 的論点**は可）。

### 検索キーワード種（JP/EN 混在で投げる）
- コーディング運用：`Claude Code` `Codex` `/goal` `Dynamic Workflow` `subagent` `auto mode` `Opus 4.8` `Fable 5` `Mythos` `敵対的レビュー` `skill化` `ハーネス` `agent harness`
- ローカル LLM：`ローカルLLM` `量子化` `MTP` `GGUF` `llama.cpp` `tok/s` `VRAM` `DGX Spark` `RTX 5090` `Mac Studio` `Qwen3.7` `DeepSeek V4` `Kimi K2` `MiMo` `MiniMax` `Gemma 4` `Unsloth`
- 懐疑/検証：`ベンチマックス` `SWE-bench` `DeepSWE` `FrontierCode` `性能低下` `ベンチ汚染` `実タスク`
- Anthropic 戦略：`Anthropic` `Project Glasswing` `RSI` `Managed Agents` `IPO` `AI憲法`
- SE 論：`AI時代` `TDD` `理解負債` `認知的降伏` `コードレビュー AI`
- セキュリティ：`サプライチェーン` `npm` `CVE` `プロンプトインジェクション` `脆弱性`
- 日本/医療/科学：`さくらインターネット` `GENIAC` `日本語LLM` `膵がん` `新薬` `高額療養費` `知念実希人`

---

## 4. アンチパターン補足（カテゴリ分析で取りこぼした理由）
- 「LLM」「AI ニュース」という**広いカテゴリで引くと、本人が冷ややかに見ている"ただの発表"や"煽り"まで大量に入り**、逆に本当に刺さる**「機構解説／実測／懐疑／運用設計／省察」という"角度"**が埋もれる。
- このプロファイルでは**トピック（何の話か）×アングル（どの角度か）×ソース（誰か）**の 3 軸で評価することを推奨。トピックが一致しても**アングルが"単なる速報・煽り"なら減点**、トピックがやや外れても**アングルが"機構・実測・懐疑・省察"で、かつ優先発信者なら加点**。
- 医療・表現規制・日本産業のような**副関心は見落としやすい**が、一貫してブックマークされている。AI 一色で絞らないこと。

---

_次回更新ルール: `bookmarks-yyyy-mm-dd.md` にこの日付(2026-06-10)より新しいものが出たら、それらを追加分析して新しい日付の interest-profile を作成する。_
