はい。ここでは **日本の「2025年度」＝2025年4月〜2026年3月** として、生成AIの主要トピックを整理します。

## 総括

2025年度の生成AIは、単なる「文章・画像を作るAI」から、**業務を実行するAI、ソフトウェア開発を進めるAI、検索・ブラウザ・業務アプリに組み込まれるAI**へ移行した年度でした。OpenAIはGPT-5を、実務クエリ・コーディング・指示追従・幻覚低減を重視したモデルとして位置づけ、AnthropicはClaude Sonnet 4.5をコーディング、複雑なエージェント、コンピュータ操作に強いモデルとして発表しました。GoogleもAI ModeやVeo 3などを通じ、検索・動画・音声・アプリ体験に生成AIを深く組み込みました。([OpenAI][1])

## 1. 「モデル性能競争」から「実務性能競争」へ

2025年度のモデル競争は、単にベンチマークの点数を競う段階から、**長文処理、コーディング、推論、ツール利用、幻覚低減、業務での信頼性**を競う段階に移りました。OpenAIはGPT-5 APIでエージェント型タスク、コーディング、長文コンテキストを強調し、AnthropicもClaude Sonnet 4.5でSWE-benchや長時間タスク、コンピュータ操作能力を前面に出しました。つまり、モデルの評価軸が「何を知っているか」から「どこまで仕事を任せられるか」に移ったと言えます。([OpenAI][2])

## 2. AIエージェントが本格トピック化

2025年度最大のキーワードの一つは **AIエージェント** です。ChatGPT agentのように、AIがブラウザ、コード、コネクタ、ファイル、スプレッドシートなどを使いながら、調査・整理・資料作成・定型業務を進める方向が強まりました。OpenAIはAgentKitやApps SDKも発表し、会話AIを「外部サービスや社内ツールを動かす操作基盤」に近づけました。([OpenAI][3])

ただし、エージェントは過熱感もありました。Gartnerは、2025年時点では企業アプリ内のエージェント搭載はまだ限定的で、同時に「agent washing」、つまり実態以上にエージェントと称するマーケティングが増えていると指摘しています。また、コスト・価値の不明確さ・リスク管理不足により、多くのエージェントAIプロジェクトが中止される可能性にも言及しています。([ガートナー][4])

## 3. コーディングAIが「補助」から「開発プロセスの中核」へ

生成AIの実用分野として、2025年度に特に進んだのがソフトウェア開発です。コード補完だけでなく、仕様理解、実装、テスト、デバッグ、リファクタリング、Pull Request作成、エラー調査まで支援する流れが強まりました。GPT-5やClaude Sonnet 4.5はいずれもコーディング・エージェント用途を強く訴求しており、AIコーディングは「エンジニアの横にいる補助ツール」から「開発ワークフローに組み込む実行主体」へ近づきました。([OpenAI][2])

## 4. 動画・音声・マルチモーダル生成の実用化

2025年度は、テキスト生成だけでなく、**画像、音声、動画、画面操作を統合するマルチモーダルAI**が大きく進みました。GoogleのVeo 3は動画と音声の生成を組み合わせ、OpenAIのSora 2も動画・音声・物理的な一貫性を重視した生成モデルとして発表されました。これにより、広告、教育、映画制作、商品説明、社内研修、ゲーム、SNSコンテンツ制作などで、生成AIの活用範囲が広がりました。([blog.google][5])

## 5. 検索・ブラウザ・アプリ体験のAI化

2025年度は、AIが単独のチャット画面に閉じず、検索やアプリ体験に入り込む動きも加速しました。GoogleはAI Modeを米国で展開し、検索結果を単なるリンク一覧ではなく、推論・マルチモーダル・追加質問を含む体験へ変えようとしました。OpenAIもChatGPT内アプリやApps SDKを打ち出し、ChatGPTを外部サービス利用の入口にする方向を示しました。([blog.google][6])

この流れは、Webサイト運営やSEOにも影響します。ユーザーが検索結果ページをクリックする前にAI要約で答えを得る場面が増えるため、企業は「検索で上位表示される」だけでなく、**AIに引用・参照されやすい情報設計**を意識する必要が出てきました。

## 6. オープンウェイト・小型モデル・主権AIの重要性

2025年度は、巨大クローズドモデルだけでなく、オープンウェイトや小型モデルの存在感も増しました。MetaはLlama 4 ScoutとMaverickを、ネイティブマルチモーダルかつMoE構造のオープンウェイトモデルとして発表しました。AlibabaのQwen3も、複数のDense/MoEモデルを含むオープンソース系モデル群として発表され、推論モードと非推論モードを切り替える設計が注目されました。([Meta AI][7])

また、2025年1月に発表されたDeepSeek-R1は年度開始直前の出来事ですが、2025年度全体に影響した重要トピックです。強化学習により推論能力を高め、数学・コーディング・STEM領域で高い性能を示したことから、「高性能モデルは必ずしも米国大手だけのものではない」「推論モデルをどう安く動かすか」という議論を加速させました。([arXiv][8])

## 7. 企業導入は拡大。ただし成果創出はまだ途上

企業での生成AI利用は広がりましたが、2025年度の論点は「使っているか」ではなく、**利益・生産性・品質改善につながっているか**に移りました。McKinseyの2025年調査では、回答企業の88%が少なくとも一つの業務機能でAIを使っている一方、全社的にスケールできている企業は一部にとどまり、エージェントAIも実験段階が多いとされています。成果を出している企業は、単なるツール導入ではなく、ワークフロー再設計、経営層の関与、人間による検証、データ・技術基盤、KPI設計を組み合わせていました。([McKinsey & Company][9])

このため、2025年度の企業AI活用では、PoC疲れ、ROI測定、AIガバナンス、社内データ連携、RAG、評価基盤、権限管理、ログ監査、人間の承認フローが重要テーマになりました。

## 8. 生成AIリスクは「幻覚」から「業務・法務・セキュリティ」へ拡大

生成AIのリスク論点も広がりました。McKinsey調査では、AI利用企業の過半が何らかのネガティブな影響を経験しており、特に不正確な出力が大きな要因になっています。さらに、AIエージェントが外部ツールや社内システムを操作するようになると、プロンプトインジェクション、権限過多、誤操作、機密情報漏えい、監査不能性が実務上のリスクになります。OpenAIもエージェント機能の発表において、確認・監督・安全対策の必要性を説明しています。([McKinsey & Company][9])

## 9. 著作権・学習データをめぐる訴訟とルール形成

2025年度は、生成AIと著作権の関係も重要テーマでした。米国では、AnthropicやMetaをめぐる訴訟で、AI学習におけるフェアユース、海賊版データの扱い、原告側の立証責任などが争点になりました。Anthropic関連では、訓練利用について一部フェアユース判断が示される一方、海賊版書籍の保管・利用に関する問題も残り、最終的には大規模な和解が報じられました。([Reuters][10])

この分野はまだ確定していません。企業にとっては、生成AIで作った成果物の権利、学習データの適法性、社外秘情報の入力、顧客データ利用、契約上の補償範囲を確認することが不可欠になりました。

## 10. 規制・政策：EU、日本、米国で方向性が分岐

EUではAI Actの段階的適用が進み、2025年2月から禁止AI行為やAIリテラシー義務が、2025年8月から汎用AIモデル関連の義務などが適用段階に入りました。これは生成AI事業者だけでなく、AIを業務利用する企業にも影響します。([デジタル戦略][11])

日本では、AI関連法が2025年6月に公布・一部施行され、9月に全面施行されました。政府はAI戦略本部を設け、AIを「使う」「創る」「信頼性を高める」「AIと協働する」という方向性を示しています。日本の規制姿勢は、EU型の厳格規制というより、イノベーション促進とリスク対応の両立を志向する枠組みと見られます。([内閣府ホームページ][12])

米国では、2025年にAI Action Planが示され、イノベーション、AIインフラ、国際展開、人材育成を重視する方向が打ち出されました。また、データセンターやAIインフラの許認可迅速化、AI教育・AIリテラシーの推進も政策テーマになりました。([The White House][13])

## 11. AIインフラ、電力、半導体、データセンターが経営課題化

2025年度は、生成AIがソフトウェアだけでなく、**GPU、データセンター、電力、冷却、クラウドコスト**の問題としても扱われるようになりました。IDCは、AIインフラ支出が2025年第2四半期に前年同期比で大きく増加し、2029年にはさらに大規模化すると予測しています。Gartnerも、2026年のAI関連支出が大きく伸び、AIインフラが主要な支出項目になると見ています。([My IDC][14])

企業にとっては、生成AIを使うほどクラウド費用や推論コストが増えるため、モデル選定、キャッシュ、プロンプト最適化、小型モデル、オンプレミス・プライベートクラウド、利用制限、費用配賦が重要になりました。

## 2025年度のキーワード

2025年度の生成AIを一言でまとめるなら、次のようになります。

**「高性能な生成モデル」から、「業務を実行するAI基盤」への転換。**

重要キーワードは、**AIエージェント、コーディングAI、マルチモーダル生成、動画生成、AI検索、オープンウェイトモデル、主権AI、RAG、AIガバナンス、著作権、AIインフラ、ROI測定**です。

実務上は、生成AIを「便利なチャットツール」として導入するだけでは不十分になり、2025年度以降は、**業務プロセス、データ基盤、権限管理、評価指標、人間の承認フローまで含めて設計できる企業が成果を出す**局面に入ったと整理できます。

[1]: https://openai.com/index/introducing-gpt-5/ "Introducing GPT-5 | OpenAI"
[2]: https://openai.com/index/introducing-gpt-5-for-developers/ "Introducing GPT‑5 for developers | OpenAI"
[3]: https://openai.com/index/introducing-chatgpt-agent/ "Introducing ChatGPT agent: bridging research and action | OpenAI"
[4]: https://www.gartner.com/en/newsroom/press-releases/2025-08-26-gartner-predicts-40-percent-of-enterprise-apps-will-feature-task-specific-ai-agents-by-2026-up-from-less-than-5-percent-in-2025 "Gartner Predicts 40% of Enterprise Apps Will Feature Task-Specific AI Agents by 2026, Up from Less Than 5% in 2025"
[5]: https://blog.google/innovation-and-ai/products/google-io-2025-all-our-announcements/ "Google I/O 2025: 100 things Google announced"
[6]: https://blog.google/products-and-platforms/products/search/google-search-ai-mode-update/ "AI Mode in Google Search: Updates from Google I/O 2025"
[7]: https://ai.meta.com/blog/llama-4-multimodal-intelligence/ "The Llama 4 herd: The beginning of a new era of natively multimodal AI innovation"
[8]: https://arxiv.org/abs/2501.12948 "[2501.12948] DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning"
[9]: https://www.mckinsey.com/capabilities/quantumblack/our-insights/the-state-of-ai "The State of AI: Global Survey 2025 | McKinsey"
[10]: https://www.reuters.com/legal/litigation/anthropic-wins-key-ruling-ai-authors-copyright-lawsuit-2025-06-24/ "Anthropic wins key US ruling on AI training in authors' copyright lawsuit | Reuters"
[11]: https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai "AI Act | Shaping Europe’s digital future"
[12]: https://www8.cao.go.jp/cstp/ai/ai_act/ai_act.html "人工知能関連技術の研究開発及び活用の推進に関する法律（ＡＩ法） - 科学技術・イノベーション - 内閣府"
[13]: https://www.whitehouse.gov/releases/2025/07/white-house-unveils-americas-ai-action-plan/ "White House Unveils America's AI Action Plan – The White House"
[14]: https://my.idc.com/getdoc.jsp?containerId=prUS53894425 "Artificial Intelligence Infrastructure Spending to Reach $758Bn USD Mark by 2029, according to IDC"









はい。対象期間を **2026年4月1日〜2026年6月17日** に絞ると、この約2か月半は、生成AIが「モデル単体の性能競争」から、**エージェント、業務アプリ、検索、開発環境、動画・音声生成、インフラ、規制**へ一気に広がった時期と整理できます。

## 総括

この期間の生成AIトピックを一言で言うと、**「AIが答える」段階から、「AIが作業を実行し、企業システムや社会制度に組み込まれる」段階への移行**です。OpenAI、Anthropic、Googleはいずれも、単なるチャットモデルではなく、コーディング、業務自動化、検索、ファイル操作、アプリ生成、長時間タスクを担うAIエージェントを前面に出しました。一方で、AnthropicのFable 5 / Mythos 5をめぐる米政府のアクセス制限、G7での先端AIアクセス議論、xAIの画像生成をめぐるプライバシー問題など、リスクと規制も急速に現実問題化しました。([OpenAI][1])

## 1. OpenAI：GPT-5.5、記憶、企業導入、IPO準備

OpenAIは4月23日に **GPT-5.5** を発表し、4月24日にはAPI提供も開始しました。GPT-5.5は、より高い知能、コーディング、業務タスク、ツール利用、長文コンテキストを重視したモデルとして位置づけられ、APIでは100万トークンのコンテキスト、入力100万トークンあたり5ドル、出力100万トークンあたり30ドルという価格が示されました。([OpenAI][1])

5月末にはGPT-5.5 Instantの応答スタイル改善が行われ、6月にはChatGPTの記憶機能を強化する「Dreaming」が発表されました。これは、過去の会話から利用者の嗜好や文脈をより適切に反映するための記憶基盤の更新です。OpenAIはこの時期、モデルの性能だけでなく、**個人化されたAI体験**を強める方向に動いています。([OpenAI Help Center][2])

企業向けでは、ChatGPT Enterprise / Eduで **ChatGPT Sites** がプレビュー提供され、Codexを使って社内向けの軽量なJavaScript / TypeScriptアプリを作成・反復・デプロイできるようになりました。また、6月14日にはOpenAI Partner Networkを発表し、1億5000万ドルを投じて企業導入支援のエコシステムを拡大し、2026年末までに30万人の認定コンサルタント育成を目指すとしています。([OpenAI Help Center][3])

さらに6月8日、OpenAIは米SECに秘密裏にS-1を提出したことを公表しました。時期は未定としつつも、IPOの選択肢を持つための動きであり、生成AI企業が資本市場の中心テーマになっていることを示す出来事です。([OpenAI][4])

## 2. Anthropic：Claude Opus 4.7 / 4.8、Fable 5、そして規制ショック

Anthropicは4月16日に **Claude Opus 4.7** を発表しました。特に高度なソフトウェアエンジニアリング、長時間のエージェント作業、マルチモーダル理解、ファイルシステム型メモリ、指示追従を強化したモデルとして説明されています。価格はOpus 4.6と同じく入力100万トークンあたり5ドル、出力100万トークンあたり25ドルとされています。([Anthropic][5])

4月17日には、デザイン、プロトタイプ、スライド、1枚資料などをClaudeと共同制作できる **Claude Design** も発表されました。これは、生成AIが文章やコードだけでなく、ビジュアル資料制作にも入り込む流れを示しています。([Anthropic][6])

5月28日には **Claude Opus 4.8** が発表され、エージェントタスク、ブラウザ操作、法務・金融・文書分析、コード作成の信頼性が強調されました。特に「自分の不確実性を示す」「コード上の欠陥を見逃しにくい」といった、実務で重要な誠実性・検証性が前面に出ています。同時にClaude Codeでは、複数のサブエージェントを並列実行するDynamic Workflowsも発表されました。([Anthropic][7])

6月9日には **Claude Fable 5 / Mythos 5** が発表されましたが、6月12日に米政府の輸出管理指令を受け、AnthropicはFable 5とMythos 5へのアクセスを全顧客に対して停止しました。米政府は外国籍者によるアクセス制限を求め、Anthropicは「全顧客に対して無効化せざるを得ない」と説明しています。この出来事は、生成AIの規制がチップ輸出管理から、**モデルそのものへのアクセス管理**へ踏み込んだ象徴的事件です。([Anthropic][8])

Anthropicは同時期にインフラ面でも大きく動きました。4月6日にはGoogleおよびBroadcomとの複数ギガワット規模の次世代TPU契約を発表し、5月6日にはSpaceXのColossus 1データセンターの全計算容量、300MW超・22万基超のNVIDIA GPUへのアクセス契約を発表しました。5月28日には650億ドルのSeries H調達と、ポストマネー評価額9650億ドルも発表されています。([Anthropic][9])

## 3. Google：I/O 2026で「agentic Gemini era」を前面に

Googleは5月19日のGoogle I/O 2026で、**agentic Gemini era**、つまりエージェント型Geminiの時代を大きく打ち出しました。Googleの説明では、AIの焦点は「日常で使うプロダクトの中で価値を見せる」段階に移っています。([blog.google][10])

中核は **Gemini 3.5 Flash** です。これはGeminiアプリとGoogle SearchのAI Modeのデフォルトモデルとして全世界に提供され、Gemini API、Google AI Studio、Android Studio、Google Antigravity、Gemini Enterprise Agent Platformでも利用可能になりました。Googleは3.5 Flashを、エージェント、コーディング、企業ワークフロー、複数サブエージェントによる複雑タスクに向いたモデルとして位置づけています。([Google DeepMind][11])

Google検索でも大きな変化がありました。SearchのAI ModeはGemini 3.5 Flashへ更新され、検索ボックス自体もAI前提に再設計されました。これは、検索が「キーワードを入れてリンクを選ぶ体験」から、AIが調べ、推論し、場合によってはエージェントとして動く体験へ移ることを意味します。([blog.google][12])

企業向けには **Gemini Enterprise Agent Platform** が発表されました。これはVertex AIの進化版として、モデル選定、モデル構築、エージェント構築、統合、DevOps、オーケストレーション、セキュリティ、ガバナンスをまとめる基盤です。Google Cloud Next ’26でも、Agent Designer、長時間実行エージェント、Agent Inbox、Skills、Canvas、第8世代TPUなどが発表されました。([Google Cloud][13])

開発者向けでは **Google Antigravity 2.0** が大きなトピックです。単なるコーディング支援ではなく、複数エージェントを並列に動かし、スケジュール実行やバックグラウンド自動化、Android / Firebase / AI Studio連携を扱う開発基盤として展開されています。([blog.google][14])

## 4. 動画・音声・マルチモーダル生成が一段進む

Googleは5月29日に **Gemini Omni** を発表しました。これは、画像・音声・動画・テキストを入力として組み合わせ、Geminiの知識と推論を使って動画生成・編集を行うモデルです。Googleはまず動画出力から始め、将来的には「あらゆる入力からあらゆる出力を生成する」方向を示しています。([Google DeepMind][15])

6月3日には **Gemma 4 12B** が発表されました。これは、16GBのVRAMまたはユニファイドメモリでローカル実行できることを意識した、マルチモーダル対応の中型オープンモデルです。視覚・音声入力を別エンコーダーなしにLLM本体へ統合する設計を採用し、ノートPC上でのエージェント型マルチモーダル処理を狙っています。([blog.google][16])

6月9日には **Gemini 3.5 Live Translate** が発表されました。70以上の言語を自動検出し、話者の抑揚・速度・ピッチを保ちながら、数秒遅れで自然な音声翻訳を行うモデルです。開発者向けにはGemini Live API、一般ユーザー向けにはGoogle翻訳アプリ、企業向けにはGoogle Meetのプレビューとして展開されています。([blog.google][17])

6月10日には **DiffusionGemma** も発表されました。これは通常の自己回帰LLMのように1トークンずつ生成するのではなく、テキスト拡散によりブロック単位で生成する実験的オープンモデルで、専用GPU上で最大4倍高速なテキスト生成を狙っています。ローカルでの高速インタラクティブ編集やリアルタイム支援に向いた方向性です。([blog.google][18])

## 5. コーディングAIは「補助」から「開発チームの構成員」へ

4〜6月の生成AIで最も実務的な進展は、コーディングAIのエージェント化です。OpenAIはCodexとChatGPT Sitesを通じて、社内アプリの生成・反復・デプロイをChatGPT内に取り込みました。AnthropicはClaude CodeでDynamic Workflowsを発表し、Claudeが多数のサブエージェントを並列に走らせ、大規模コードベースの移行や検証を行う方向を示しました。GoogleはAntigravity 2.0を、xAIはGrok Buildを、MistralはVibeのリモートエージェントを打ち出しました。([OpenAI Help Center][3])

この流れのポイントは、AIが「コードを書く道具」から、**仕様理解、実装、テスト、修正、レビュー、デプロイ準備までをまとめて進める作業主体**に近づいていることです。特にClaude Opus 4.7 / 4.8、GPT-5.5、Gemini 3.5 Flashはいずれも、コーディング、ツール利用、長時間タスク、検証性を強く訴求しています。([OpenAI][1])

## 6. オープンモデル・中国勢・非米国勢の存在感

この期間は、米国大手だけでなく、中国勢や欧州勢、オープンモデルも重要でした。DeepSeekは4月24日に **DeepSeek V4 Preview** を公開し、V4-ProとV4-Flashをオープンソースとして提供しました。公式説明では、1Mコンテキスト、Thinking / Non-Thinkingの両モード、OpenAI Chat Completions互換、Anthropic API互換、エージェント型コーディング能力を特徴としています。([DeepSeek API Docs][19])

AlibabaのQwenも4月に **Qwen3.6-Plus** や **Qwen3.6-35B-A3B** を発表し、実務エージェント、コーディング、マルチモーダル利用を強調しました。Qwen3.6-35B-A3BはApache 2.0系のオープンモデルとして注目され、低コスト・ローカル実行・エージェント開発の文脈で存在感を増しました。([Qwen][20])

Metaは4月8日に **Muse Spark** を発表しました。MetaのAIブログでは、個人向けスーパーインテリジェンスに向けた新モデルとして扱われており、同日には高度AIの構築・テスト体制に関する研究記事も公開されています。これは、MetaがLlama中心のオープンモデル戦略から、よりパーソナルAI体験に軸を広げていることを示しています。([AI Meta][21])

xAIは5月後半から6月にかけて、Grok Build、Grok Build API、Grok Imagine 1.5 Preview、Grok for PowerPointなどを相次いで出しました。Grokも、チャットボットというより、コーディング、動画生成、Office連携、音声、エージェント基盤へ広がっています。([xAI][22])

Mistralは5月にMistral Medium 3.5、Vibeのリモートコーディングエージェント、Search Toolkit、MCP連携、Workflows、Physics AIなどを発表しました。欧州勢も、単なるLLM提供ではなく、企業ワークフロー、検索パイプライン、工学・物理シミュレーション領域へ拡張しています。([Mistral AI][23])

## 7. AIインフラ、電力、資本市場が中心テーマ化

4〜6月は、AIがソフトウェアの話だけでは済まなくなりました。AnthropicはGoogle / Broadcomとの複数ギガワット級TPU契約、SpaceX Colossus 1の300MW超・22万GPU超の容量利用、650億ドルの大型資金調達を発表しました。GoogleもCloud Nextで第8世代TPU、推論向けTPU 8i、学習向けTPU 8t、高速ストレージ、ネットワークを発表しています。([Anthropic][9])

この背景には、生成AIの競争軸が **モデル性能 × 推論コスト × 電力 × データセンター容量** へ移ったことがあります。Reutersは、OpenAIやAnthropicがIPO準備へ進む中、AI企業が巨大な計算資源と資本を必要としていることを報じています。また、欧米ではデータセンター需要が電力網に与える影響も大きな論点になっています。([Reuters][24])

## 8. 規制・安全保障：AIモデルそのものが管理対象に

最大の規制トピックは、AnthropicのFable 5 / Mythos 5停止です。米政府は外国籍者によるアクセスを制限する輸出管理指令を出し、Anthropicは全顧客に対して当該モデルを停止しました。これにより、AI規制はGPUや半導体だけでなく、**モデルの能力、モデルへのアクセス、利用者の国籍・所属**にまで踏み込む段階に入ったと見られます。([Anthropic][25])

6月16日には、G7首脳が米国の先端AIモデルに対して「trusted partners」、つまり信頼できる国・企業へのアクセス枠を検討していると報じられました。これは、先端AIを同盟国のサイバー防衛に使いたい一方で、国家安全保障上の制約も強まるというジレンマを表しています。([Reuters][26])

米国では6月2日に、先端AIのイノベーションと安全保障を促進する大統領令が出され、政府・民間システムの近代化、防衛、知財保護、高度AI能力の育成が政策目標として示されました。6月4日には、州によるAIモデル開発規制を連邦レベルで制限する草案も報じられ、米国では「連邦一元化」と「州規制」のせめぎ合いが続いています。([The White House][27])

EUではAI Actの実施が進み、2026年8月2日の本格適用を前に、高リスクAIやGPAI、透明性・著作権・安全性の実務対応が重要になっています。欧州委員会は、汎用AIモデル向けのCode of Practiceを、安全性、透明性、著作権の遵守支援ツールとして位置づけています。([デジタル戦略][28])

日本では、4月7日に個人情報保護法改正案が閣議決定され、AI開発等の統計情報等作成を念頭に、一定条件のもとで本人同意を不要とする方向が示されました。6月には松本デジタル相が、日本がAI開発で遅れれば「AI植民地」になりかねないと述べ、個人データ活用とAI競争力のバランスが国内政策の焦点になっています。([PPC][29])

## 9. セキュリティ、プライバシー、悪用リスクも顕在化

Googleは6月12日、AIを利用したフィッシングキット「Outsider」の作成者を相手にニューヨーク連邦地裁で訴訟を起こしました。Googleによると、OutsiderはGeminiなどのAIツールを使って詐欺サイト作成を支援し、2025年11月から2026年4月にかけて関連URLが150万件超検出されたとされています。([Reuters][30])

xAIのGrokについては、カナダのプライバシー当局が、画像生成機能に十分な初期安全対策がなく、非同意の性的ディープフェイク作成を可能にしたとして、連邦プライバシー法違反と判断しました。これは、画像・動画生成AIが一般化するほど、肖像、同意、プライバシー、未成年保護の問題が重大化することを示しています。([Reuters][31])

## 2026年4月〜6月17日のキーワード

この期間のキーワードは、**AIエージェント、コーディングエージェント、AI検索、マルチモーダル生成、音声翻訳、ローカルAI、オープンモデル、AIインフラ、ギガワット級データセンター、IPO、輸出管理、主権AI、AI安全保障、ディープフェイク規制**です。

実務的には、2026年春〜初夏の生成AIは「どのモデルが一番賢いか」だけでは評価できなくなりました。重要なのは、**社内データに接続できるか、権限管理できるか、長時間タスクを任せられるか、コストが合うか、監査できるか、法規制に耐えられるか**です。生成AIはこの約3か月で、明確に「便利なツール」から「企業・国家・インフラを巻き込む基盤技術」へ移行しました。

* [Reuters](https://www.reuters.com/technology/us-blocks-foreign-access-anthropics-most-advanced-ai-models-axios-reports-2026-06-13/?utm_source=chatgpt.com)
* [Reuters](https://www.reuters.com/legal/government/g7-leaders-discuss-trusted-partners-access-cutting-edge-us-ai-models-sources-say-2026-06-16/?utm_source=chatgpt.com)
* [Reuters](https://www.reuters.com/business/openai-expects-go-public-within-next-year-information-reports-2026-06-10/?utm_source=chatgpt.com)
* [Reuters](https://www.reuters.com/business/media-telecom/japan-could-end-up-an-ai-colony-if-it-falls-behind-digital-minister-warns-2026-06-05/?utm_source=chatgpt.com)
* [Reuters](https://www.reuters.com/business/media-telecom/groks-ai-image-generation-tool-violated-canadian-privacy-law-says-watchdog-2026-06-11/?utm_source=chatgpt.com)
* [Reuters](https://www.reuters.com/legal/government/google-targets-ai-powered-phishing-new-york-lawsuit-2026-06-12/?utm_source=chatgpt.com)
* [Reuters](https://www.reuters.com/business/energy/dutch-power-moratoriums-highlight-challenge-facing-grid-operators--reeii-2026-06-16/?utm_source=chatgpt.com)

[1]: https://openai.com/index/introducing-gpt-5-5/ "Introducing GPT-5.5 | OpenAI"
[2]: https://help.openai.com/en/articles/9624314-model-release-notes "Model Release Notes | OpenAI Help Center"
[3]: https://help.openai.com/en/articles/10128477-chatgpt-enterprise-edu-release-notes "ChatGPT Enterprise & Edu - Release Notes | OpenAI Help Center"
[4]: https://openai.com/index/openai-submits-confidential-s-1/ "Confidential submission of draft S-1 to the SEC | OpenAI"
[5]: https://www.anthropic.com/news/claude-opus-4-7 "Introducing Claude Opus 4.7 \ Anthropic"
[6]: https://www.anthropic.com/news/claude-design-anthropic-labs "Introducing Claude Design by Anthropic Labs \ Anthropic"
[7]: https://www.anthropic.com/news/claude-opus-4-8 "Introducing Claude Opus 4.8 \ Anthropic"
[8]: https://www.anthropic.com/news/claude-fable-5-mythos-5 "Claude Fable 5 and Claude Mythos 5 \ Anthropic"
[9]: https://www.anthropic.com/news/google-broadcom-partnership-compute "Anthropic expands partnership with Google and Broadcom for multiple gigawatts of next-generation compute \ Anthropic"
[10]: https://blog.google/innovation-and-ai/sundar-pichai-io-2026/ "Google I/O 2026: Sundar Pichai’s opening keynote"
[11]: https://deepmind.google/blog/gemini-3-5-frontier-intelligence-with-action/ "Gemini 3.5: frontier intelligence with action"
[12]: https://blog.google/products-and-platforms/products/search/search-io-2026/ "Google Search’s I/O 2026 updates: AI agents and more"
[13]: https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform "Introducing Gemini Enterprise Agent Platform | Google Cloud Blog"
[14]: https://blog.google/innovation-and-ai/technology/developers-tools/google-io-2026-developer-highlights/ "I/O 2026 developer highlights: Antigravity, Gemini API, AI Studio"
[15]: https://deepmind.google/blog/introducing-gemini-omni/ "Introducing Gemini Omni"
[16]: https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemma-4-12b/ "Introducing Gemma 4 12B"
[17]: https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-live-3-5-translate/ "Gemini 3.5 Live Translate is here"
[18]: https://blog.google/innovation-and-ai/technology/developers-tools/diffusion-gemma-faster-text-generation/ "Introducing DiffusionGemma"
[19]: https://api-docs.deepseek.com/news/news260424 "DeepSeek V4 Preview Release | DeepSeek API Docs"
[20]: https://qwen.ai/blog?id=qwen3.6&utm_source=chatgpt.com "Qwen3.6-Plus: Towards Real World Agents"
[21]: https://ai.meta.com/blog/ "AI at Meta Blog"
[22]: https://x.ai/news "News: Research, Product & Company Updates | xAI"
[23]: https://mistral.ai/news/ "Frontier AI LLMs, assistants, agents, services | Mistral AI"
[24]: https://www.reuters.com/technology/openai-files-us-ipo-after-anthropic-ai-giants-head-public-markets-2026-06-08/?utm_source=chatgpt.com "OpenAI files for US IPO after Anthropic as AI giants head to ..."
[25]: https://www.anthropic.com/news/fable-mythos-access "Statement on the US government directive to suspend access to Fable 5 and Mythos 5 \ Anthropic"
[26]: https://www.reuters.com/legal/government/g7-leaders-discuss-trusted-partners-access-cutting-edge-us-ai-models-sources-say-2026-06-16/ "G7 leaders discuss 'trusted partners' access to cutting-edge US AI models, sources say | Reuters"
[27]: https://www.whitehouse.gov/presidential-actions/2026/06/promoting-advanced-artificial-intelligence-innovation-and-security/ "Promoting Advanced Artificial Intelligence Innovation and Security – The White House"
[28]: https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai "AI Act | Shaping Europe’s digital future"
[29]: https://www.ppc.go.jp/files/pdf/260407_kisyahaifusiryou.pdf?utm_source=chatgpt.com "個人情報保護法等の一部を改正する法律案について"
[30]: https://www.reuters.com/legal/government/google-targets-ai-powered-phishing-new-york-lawsuit-2026-06-12/ "Google targets AI-powered phishing in New York lawsuit | Reuters"
[31]: https://www.reuters.com/business/media-telecom/groks-ai-image-generation-tool-violated-canadian-privacy-law-says-watchdog-2026-06-11/ "Grok's AI image generation tool violated Canadian privacy law, watchdog says | Reuters"
