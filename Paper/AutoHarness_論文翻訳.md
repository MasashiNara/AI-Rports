# AutoHarness: コードハーネスの自動合成によるLLMエージェントの改善

Xinghua Lou, Miguel Lázaro-Gredilla, Antoine Dedieu,
Carter Wendelken, Wolfgang Lehrach, Kevin P. Murphy

Google DeepMind

{xinghua,lazarogredilla,adedieu,cwendelken,wpl,kpmurphy}@deepmind.com

2026年3月5日

https://arxiv.org/abs/2603.03329v1

---

## 概要

近年、言語モデルは大きな進歩を遂げているが、エージェントとして使用した場合、与えられた状態に対して単に最適でないだけでなく、外部環境によって厳密に禁止されている行動を取ろうとすることが多い。例えば、最近のKaggle GameArenaチェス大会では、Gemini-2.5-Flashの敗北の78%が違法手に起因していた。人間がLLMの周囲に「ハーネス」を手動で作成してこのような失敗を防ぐことが多い。本論文では、Gemini-2.5-Flashが（ゲーム）環境からのフィードバックを用いた少数回の反復的コード改良により、このようなコードハーネスを自動的に合成できることを実証する。生成されたハーネスは145種類のTextArenaゲーム（1人用・2人用の両方）において全ての違法手を防止し、より小型のGemini-2.5-Flashモデルが、Gemini-2.5-Proなどのより大型のモデルを上回ることを可能にする。この手法を限界まで推し進めると、Gemini-2.5-Flashにポリシー全体をコードとして生成させることができ、意思決定時にLLMを使用する必要がなくなる。生成されたコードポリシーは、16種類のTextArena 1人用ゲームにおいて、Gemini-2.5-ProおよびGPT-5.2-Highよりも高い平均報酬を達成する。本研究の結果は、小型モデルを用いてカスタムコードハーネス（またはポリシー全体）を合成することで、はるかに大型のモデルを上回る性能を達成でき、同時にコスト効率も優れていることを示している。

---

## 1 はじめに

大規模言語モデル（LLM）はコード合成や数学問題の解決において顕著な能力を示している（例：Chervonyi et al. (2025); Huang & Yang (2025)）。しかし、その計画・推論性能は脆弱であり得る（例：Valmeekam et al., 2023a; Petrov et al., 2025）。例えば、最近のKaggle GameArena (Kaggle, 2025) チェス大会では、Gemini 2.5 Flashの敗北の78%は戦略的失策ではなく、単純な違法手に起因していた。

この失敗モードは、モデルのゲームに対する見かけ上の理解と、実際にルールに従う能力との間の乖離を浮き彫りにしている（例：Ruoss et al., 2024のFig. A16参照）[^1]。この問題を軽減する従来のアプローチには、ゲーム軌跡でのファインチューニングや、手の妥当性を検証する手動コーディングされたハーネスの使用がある。LLMのファインチューニング、特に現在のフラグシップモデルの規模では、迅速でもコスト効率が良くもなく、他のタスク（例：命令追従）でのモデル性能を劣化させる可能性がある。手動設計のハーネスは脆弱で労働集約的であり、新しいゲームごとに追加作業が必要である。より拡張性の高い解決策として——本論文ではこれを追求する——LLM自身のコード生成能力を活用してこのギャップを埋めることが挙げられる。

エージェントは、特定のLLMと、モデルと解決すべきタスクの間の「接着剤」や「配管」として機能するハーネスの組み合わせとして定義されることが多い。本研究では、LLM自身がハーネスをコーディングすることでエージェントを完成させるフレームワーク「code as harness（ハーネスとしてのコード）」を提案する。最も単純な形態では、ハーネスはLLMを呼び出し、受け入れ不可能な回答を棄却する制御ループとして見ることができる。何が受け入れ可能かの定義自体が学習される。これは本質的に、条件付けがタスクに基づいて学習されるLLMのための棄却サンプラーとなる。

[^1]: 与えられた状態でどの行動が有効かを知るという一般的な問題は「行動適用可能性」問題と呼ばれ、AI計画コミュニティで研究されてきた (Kokel et al., 2025)。

---

## 2 関連研究

**ゲームプレイと推論のためのLLM** テキストベースのアドベンチャーゲームからMinecraftやチェスなどの複雑な戦略ゲームまで、ゲーム環境におけるエージェントとしてのLLMの使用は広く研究されてきた (Shinn et al., 2023; Wang et al., 2023)。初期の研究では、戦略的計画を改善するための「chain-of-thought」プロンプティング (Wei et al., 2022) に焦点が当てられた。しかし、最近のベンチマークでは、高度なモデルでさえ、厳密に定義された環境における状態追跡と妥当性の面で苦戦することが明らかになっている (Valmeekam et al., 2023b)。「tree of thoughts」(Yao et al., 2023) などの手法は、推論時の探索を利用して先読みをシミュレートするが、有効な遷移に関してハルシネーションを起こしやすいLLMの内部世界モデルに依存している。本研究は、状態遷移の妥当性チェッカーをモデルの内部シミュレーションに依存するのではなく、外部の検証可能なプログラムにオフロードする点で異なる。LLMはゲームの状態遷移関数全体（すなわち世界モデル）をコードとして生成することもできる (Lehrach et al., 2025) が、比較的単純な戦略で対応できる複雑なゲームに対しては過度に負荷が高い。さらに、このアプローチは有効な行動間の選択におけるLLMの戦略的能力を活用しない。

**ポリシーとしてのコード** 本アプローチは、行動計画のためのコード生成を用いる成長中の研究群の上に構築されている。Voyager (Wang et al., 2023) は、LLMが実行可能コードをライブラリに保存することでMinecraftのスキルを継続的に学習できることを実証した。同様に、Eureka (Ma et al., 2024) は、LLMが強化学習のための報酬関数を生成する進化的探索を実行できることを示した。本研究により近いものとして、code as policies (Liang et al., 2023) はロボット制御をコード生成として直接定式化した。本アプローチは関連しているが、ツリー探索と豊富な環境フィードバックに基づく反復的コード改良を使用して、ハイブリッドなコード＋LLMハーネスを生成する。

**改良と探索** 前述のように、反復的改良はコード生成にとって極めて重要である。Reflexion (Shinn et al., 2023) は、エージェントが失敗ログを振り返る言語的強化学習ループを導入した。プログラム合成の領域では、AlphaCode (Li et al., 2022) が大規模なサンプリングとフィルタリングを利用し、AlphaEvolve (Novikov et al., 2025) はLLMを変異関数として使用する進化的アルゴリズムをコードベース全体に適用した。本手法は、Tang et al. (2024) に従いThompson Samplingを用いた構造化ツリー探索にこれらの概念を統合するが、コードハーネスの作成を目標とするオンライン・マルチターン設定で適用する。

---

## 3 手法

Tang et al. (2024) に着想を得て、本アプローチはツリー構造で複数のコード仮説を維持し、Thompson Samplingを用いて次にどのノードを改良するかを選択する。各ノードのヒューリスティック値は合法手精度の平均である。改良（勾配フリーのコードオプティマイザ）はベースLLMにより、試みた手が合法であったかどうか、どのような報酬が得られたか（もしあれば）に関する環境（批評家）からのフィードバックを用いて行われる（図1参照）。`is_legal_action()` がTrueを返すが行動が無効な場合は両方の関数を改良し、`is_legal_action()` がFalseを返し行動が無効な場合は `propose_action()` のみを改良する。

このアプローチを用いて、異なる種類のコードハーネスを生成できる。**harness-as-action-filter（行動フィルターとしてのハーネス）** は `propose_action()` を呼び出して合法手の集合を生成し、LLMを活用してそれらをランク付けする（chain of thought推論を使用する可能性がある）。**harness-as-action-verifier（行動検証器としてのハーネス）** は、まずLLMを呼び出して行動を生成し、`is_legal_action()` で検証し、無効な場合は「違法手」警告メッセージを含む新しいプロンプトでプロセスを繰り返す。**harness-as-policy（ポリシーとしてのハーネス）** はコードを用いて行動を選択する。コードは原理的にはLLMを呼び出すこともできるが、本設定ではポリシーはプリミティブなPython関数とnumpyなどの標準ライブラリのみを使用するため、推論時にLLMを呼び出す必要がない。本論文では主にharness-as-action-verifierに焦点を当てるが、4.3節ではharness-as-policyの予備的結果も報告する。

---

## 4 実験結果

実験には、TextArena (Guertler et al., 2025) の全1人用（1P）および2人用（2P）ゲームから、行動空間が自由形式テキスト/対話であるゲーム9種（「Mafia」や「Codenames」など）を除いた145ゲームを選択した。これには、チェス、チェッカー、ブラックジャック、数独などの有名なゲームや、これらのゲームの新しいバリエーションが含まれる。使用した全ゲームの一覧は付録の表1にある。

ハーネスにとってより困難な問題とするため、観測文字列からあらゆる形式の「利用可能な手」ヒントを手動で削除してゲームを修正した（例については付録A.4節参照）。これは、エージェントが合法な行動を明示的に教えられるのではなく、環境フィードバックから推論する必要がある多くの実世界シナリオをよりよく反映していると考える（この修正なしでは、ハーネスはプロンプトから合法手のリストをそのままコピーできてしまう。これはより良い結果をもたらすが、不要であることを示す）。

### 4.1 学習

学習セットアップ（harness-as-action-verifier用）は以下の通りである。各反復で10個の並列環境を使用し、最大1000ステップまでロールアウトする（環境の自動リセットあり）。コードによる違法手またはコード実行の失敗が発生すると、ロールアウトは終了する。最大5つの失敗ステップがサンプリングされ、様々な種類のエラーを統合する批評家（Critic）に供給される。これらのエラーメッセージ付きステップは、元のコードとともに改良器（Refiner）に供給され、新しい（改善されたことが期待される）コードが生成される。Thompson Samplingのヒューリスティック重みは1.0に設定した。ヒューリスティック値（すなわち合法手成功率）が1.0に達するか、タイムアウトすると学習は終了する。学習にはGemini-2.5-Flashを使用した。

平均して14.5回のツリー探索反復で学習が終了し、32ゲーム中19ゲームは10回未満の反復で終了した。学習に最も多くのLLM呼び出しを要したゲームは、GermanWhist-v0（2P）、Cryptarithm-v0（1P）、Othello-v0（2P）、Chess-v0（2P）であった（図2参照）。行動フィルターの精度は、新規テストロールアウト（ゲームごとに10個のランダムシードで長さ1000）に適用し、合法手の割合を測定することで評価した。付録の表1に示すように、全ゲームで合法手成功率100%を達成した。生成されたコードハーネスの例については付録D節を参照。

### 4.2 評価

次に、実際のゲームプレイ中のエージェントの性能評価に移る。効率性の理由から、全145ゲームではなく、16の1Pゲームと16の2Pゲームに結果を絞った。以下のエージェントを評価した：Gemini-2.5-Flash、Gemini-2.5-Pro、およびGemini-2.5-Flash+Harness（提案手法）[^2]。全実験で同じ最適化済みプロンプトを使用した。1Pゲームでは20試合を実施し、報酬を評価指標とした。2Pゲームでは40試合をランダムシードで実施し、提案手法が先手・後手となる試合を均等に分け、平均勝率/引き分け率/敗率を評価指標とした。

2Pゲームの結果を図3に示す。本アプローチにより、はるかに小型のGemini-2.5-Flashが、はるかに大型のGemini-2.5-Proに対して16ゲーム中9ゲームで勝利（総合勝率56.3%）し、Gemini-2.5-Proの総合勝率は38.2%であった。（バニラの）Gemini-2.5-Flashとの対戦では16ゲーム中12ゲームで勝利し、総合勝率は64.8%に上昇した。

1Pゲームの結果を図4に示す。本アプローチはGemini-2.5-Proよりも16ゲーム中8ゲームで高い報酬を達成し、5ゲームで同点であった。平均報酬は0.745であり、Gemini-2.5-Pro（0.707）およびGemini-2.5-Flash（0.673）と比較して優れていた。

[^2]: 本手法はまずLLM（ここではGemini-2.5-Flash）を使用して行動検証器コードハーネスを生成し、次にこのハーネスを使用して同じLLMからの提案をフィルタリングする。

### 4.3 ポリシーとしてのハーネス（Harness-as-Policy）

極端なケースとして、ポリシー全体をコードとして学習し、テスト時にLLMを使用する必要をなくすことを検討する。これは16の1Pゲームで評価した（2Pゲームに対してコード形式でポリシー全体を学習することははるかに困難であるため[^3]）。上記のエージェントに加えて、3つの新しいエージェントを評価した：GPT-5.2（thinking なし）、GPT-5.2-High（thinking 高）、およびHarness-as-Policy（提案手法）。全エージェントは以前と同様にゲームごとに20回評価したが、GPT-5.2とGPT-5.2-Highはコスト上の理由からそれぞれ10回と5回の繰り返しとした。

学習では、ヒューリスティック値を報酬を含むように修正した。具体的には、違法手が取られた場合は H = 0 とし、それ以外は H = 0.5 + 0.5r とした。ここで r ∈ [0.0, 1.0] は環境報酬であり、軌跡の終了時にのみ利用可能である（スパース報酬設定）。Harness-as-Policyは本コード合成手法を用いてGemini-2.5-Flashで最大256反復まで学習した。平均して学習は89.4反復を要し、ヒューリスティック値0.939を達成した。

図5に示すように、本アプローチは最高の平均報酬（0.870）を達成し、GPT-5.2（0.635）、Gemini-2.5-Pro（0.707）、GPT-5.2-High（0.844）を含む全てのエージェントを上回った。ゲーム別では、提案手法が3/16ゲームで勝利、GPT-5.2-Highが5/16ゲームで勝利し、残りの8/16は同点であった（詳細は付録参照）。Harness-as-Policyは純粋な（Python）コードを生成するため、テスト時コストはほぼゼロである一方、GPT-5.2およびGPT-5.2-Highの実験には約640ドルのコストがかかった。

[^3]: 2人用ゲームは相手のポリシーに関する戦略的推論を必要とし、実行時にMCTS的な手法が必要になることが多い（例：Duan et al., 2024参照）。原理的には本コード合成手法でそのようなポリシーを生成することは可能だが、Lehrach et al. (2025) のように探索対象のコード世界モデルも学習する必要があり、テキストゲームでは困難である。

---

## 5 結論と今後の展望

LLMエージェントの性能を向上させるための、コードハーネスの自動合成に基づく新しいアプローチを開発した。現在は各環境（ゲーム）ごとに個別のハーネスを生成している。今後は、生成されたドメイン固有のエキスパート（エージェント）をベースLLMに蒸留し、システム全体が再帰的に自己改善するようにしたい。また、再利用可能なハーネスのライブラリの構築や、CraftaxやTerra Novaなどのより困難なマルチモーダルゲームへの手法の適用も探求したい。

---

## 参考文献

- Chervonyi, Y., Trinh, T. H., Olšák, M., et al. Gold-medalist performance in solving olympiad geometry with alphageometry2. JMLR, 26(241):1–39, 2025.
- Duan, J., Zhang, R., Diffenderfer, J., et al. GTBench: Uncovering the strategic reasoning limitations of LLMs via game-theoretic evaluations. arXiv [cs.CL], February 2024.
- Guertler, L., Cheng, B., Yu, S., et al. Textarena. arXiv:2504.11442, 2025.
- Huang, Y. & Yang, L. F. Winning gold at imo 2025 with a model-agnostic verification-and-refinement pipeline. arXiv:2507.15855, 2025.
- Kaggle. Kaggle game arena: A benchmarking platform for ai models. https://www.kaggle.com/game-arena, 2025.
- Kokel, H., Katz, M., Srinivas, K., & Sohrabi, S. ACPBench hard: Unrestrained reasoning about action, change, and planning. In AAAI 2025 Workshop LM4Plan, February 2025.
- Lehrach, W., Hennes, D., Lazaro-Gredilla, M., et al. Code world models for general game playing. arXiv:2510.04542, 2025.
- Li, Y., Choi, D., Chung, J., et al. Competition-level code generation with alphacode. Science, 378(6624):1092–1097, 2022.
- Liang, J., Huang, W., Xia, F., et al. Code as policies: Language model programs for embodied control. In ICRA, pp. 9493–9500. IEEE, 2023.
- Ma, Y. J., Liang, W., Wang, G., et al. Eureka: Human-level reward design via coding large language models. In ICLR, 2024.
- Novikov, A., Vũ, N., Eisenberger, M., et al. Alphaevolve: A coding agent for scientific and algorithmic discovery. arXiv:2506.13131, 2025.
- Petrov, I., Dekoninck, J., Baltadzhiev, L., et al. Proof or bluff? evaluating llms on 2025 usa math olympiad. arXiv:2503.21934, 2025.
- Ruoss, A., Pardo, F., Chan, H., et al. LMAct: A benchmark for in-context imitation learning with long multimodal demonstrations. December 2024.
- Shinn, N., Cassano, F., Gopinath, A., et al. Reflexion: Language agents with verbal reinforcement learning. NeurIPS, 36:8634–8652, 2023.
- Tang, H., Hu, K., Zhou, J., et al. Code repair with llms gives an exploration-exploitation tradeoff. NeurIPS, 37:117954–117996, 2024.
- Valmeekam, K., Marquez, M., Sreedharan, S., & Kambhampati, S. On the planning abilities of large language models - a critical investigation. In NeurIPS, November 2023a.
- Valmeekam, K., Marquez, M., Sreedharan, S., & Kambhampati, S. On the planning abilities of large language models-a critical investigation. NeurIPS, 36:75993–76005, 2023b.
- Wang, G., Xie, Y., Jiang, Y., et al. Voyager: An open-ended embodied agent with large language models. arXiv preprint arXiv:2305.16291, 2023.
- Wei, J., Wang, X., Schuurmans, D., et al. Chain-of-thought prompting elicits reasoning in large language models. NeurIPS, 35:24824–24837, 2022.
- Yao, S., Yu, D., Zhao, J., et al. Tree of thoughts: Deliberate problem solving with large language models. NeurIPS, 36:11809–11822, 2023.

---

## 付録

### A TextArenaゲーム

#### A.1 全145ゲームのリスト

以下の表に全145ゲームを示す。学習済みハーネスの精度と、それを達成するために必要なLLM呼び出し回数を併記する。エンドツーエンドのエージェント評価に使用した32ゲームには * を付記する。

| インデックス | ゲーム | プレイヤー数 | 学習ステップ数 | 合法手率 |
|---|---|---|---|---|
| 0 | 2048-v0* | 1 | 27 | 1.0 |
| 1 | 2048-v0-easy | 1 | 4 | 1.0 |
| 2 | 2048-v0-extreme | 1 | 44 | 1.0 |
| 3 | 2048-v0-hard | 1 | 47 | 1.0 |
| 4 | 2048-v0-mega-easy | 1 | 31 | 1.0 |
| 5 | 2048-v0-super-easy | 1 | 6 | 1.0 |
| 6 | 2048-v0-ultra-easy | 1 | 2 | 1.0 |
| 7 | 2048-v0-very-easy | 1 | 57 | 1.0 |
| 8 | 2048-v0-very-hard | 1 | 7 | 1.0 |
| 9 | Alquerque-v0* | 2 | 4 | 1.0 |
| 10 | Bandit-v0* | 1 | 2 | 1.0 |
| 11 | Bandit-v0-hard | 1 | 1 | 1.0 |
| 12 | Battleship-v0 | 2 | 4 | 1.0 |
| 13 | Battleship-v0-extreme | 2 | 32 | 1.0 |
| 14 | Battleship-v0-large | 2 | 9 | 1.0 |
| 15 | Battleship-v0-standard | 2 | 6 | 1.0 |
| 16 | Blackjack-v0* | 1 | 2 | 1.0 |
| 17 | Blackjack-v0-long | 1 | 1 | 1.0 |
| 18 | Breakthrough-v0* | 2 | 2 | 1.0 |
| 19 | Breakthrough-v0-blind | 2 | 20 | 1.0 |
| 20 | Breakthrough-v0-large | 2 | 9 | 1.0 |
| 21 | Breakthrough-v0-long | 2 | 7 | 1.0 |
| 22 | Breakthrough-v0-small | 2 | 136 | 1.0 |
| 23 | Breakthrough-v0-tiny | 2 | 5 | 1.0 |
| 24 | Briscola-v0 | 2 | 2 | 1.0 |
| 25 | Checkers-v0* | 2 | 7 | 1.0 |
| 26 | Checkers-v0-long | 2 | 3 | 1.0 |
| 27 | Chess-v0* | 2 | 64 | 1.0 |
| 28 | Chess-v0-blind | 2 | 19 | 1.0 |
| 29 | Chess-v0-long | 2 | 16 | 1.0 |
| 30 | Chopsticks-v0* | 2 | 15 | 1.0 |
| 31 | Chopsticks-v0-long | 2 | 7 | 1.0 |
| 32 | Chopsticks-v0-medium | 2 | 15 | 1.0 |
| 33 | ColonelBlotto-v0 | 2 | 1 | 1.0 |
| 34 | ColonelBlotto-v0-extreme | 2 | 1 | 1.0 |
| 35 | ColonelBlotto-v0-large | 2 | 1 | 1.0 |
| 36 | ColonelBlotto-v0-small | 2 | 1 | 1.0 |
| 37 | ConnectFour-v0 | 2 | 10 | 1.0 |
| 38 | ConnectFour-v0-blind | 2 | 2 | 1.0 |
| 39 | ConnectFour-v0-large | 2 | 1 | 1.0 |
| 40 | Crusade-v0* | 2 | 4 | 1.0 |
| 41 | Cryptarithm-v0* | 1 | 45 | 1.0 |
| 42 | FifteenPuzzle-v0* | 1 | 3 | 1.0 |
| 43 | FrozenLake-v0* | 1 | 19 | 1.0 |
| 44 | FrozenLake-v0-hardcore | 1 | 4 | 1.0 |
| 45 | FrozenLake-v0-random | 1 | 22 | 1.0 |
| 46 | GameOfPureStrategy-v0 | 2 | 3 | 1.0 |
| 47 | GermanWhist-v0* | 2 | 43 | 1.0 |
| 48 | Golf-v0* | 2 | 8 | 1.0 |
| 49 | Golf-v0-medium | 2 | 9 | 1.0 |
| 50 | GuessTheNumber-v0* | 1 | 2 | 1.0 |
| 51 | GuessTheNumber-v0-hardcore | 1 | 2 | 1.0 |
| 52 | HighSociety-v0 | 2 | 3 | 1.0 |
| 53 | IndianPoker-v0 | 2 | 11 | 1.0 |
| 54 | IndianPoker-v0-extreme | 2 | 2 | 1.0 |
| 55 | IndianPoker-v0-long | 2 | 26 | 1.0 |
| 56 | IndianPoker-v0-medium | 2 | 7 | 1.0 |
| 57 | IndianPoker-v0-short | 2 | 2 | 1.0 |
| 58 | IteratedMatchingPennies-v0 | 2 | 1 | 1.0 |
| 59 | IteratedRockPaperScissors-v0 | 2 | 1 | 1.0 |
| 60 | IteratedTwoThirdsAverage-v0 | 2 | 1 | 1.0 |
| 61 | KuhnPoker-v0 | 2 | 5 | 1.0 |
| 62 | KuhnPoker-v0-extreme | 2 | 3 | 1.0 |
| 63 | KuhnPoker-v0-long | 2 | 2 | 1.0 |
| 64 | KuhnPoker-v0-medium | 2 | 2 | 1.0 |
| 65 | KuhnPoker-v0-short | 2 | 3 | 1.0 |
| 66 | LiarsDice-v0* | 2 | 4 | 1.0 |
| 67 | LiarsDice-v0-large | 2 | 6 | 1.0 |
| 68 | LiarsDice-v0-small | 2 | 5 | 1.0 |
| 69 | LightsOut-v0* | 1 | 1 | 1.0 |
| 70 | LinesOfAction-v0* | 2 | 23 | 1.0 |
| 71 | Mastermind-v0* | 1 | 2 | 1.0 |
| 72 | Mastermind-v0-extreme | 1 | 1 | 1.0 |
| 73 | Mastermind-v0-hard | 1 | 2 | 1.0 |
| 74 | MemoryGame-v0 | 2 | 3 | 1.0 |
| 75 | MemoryGame-v0-hard | 2 | 2 | 1.0 |
| 76 | MemoryGame-v0-medium | 2 | 2 | 1.0 |
| 77 | Minesweeper-v0* | 1 | 11 | 1.0 |
| 78 | Minesweeper-v0-hard | 1 | 6 | 1.0 |
| 79 | Minesweeper-v0-medium | 1 | 10 | 1.0 |
| 80 | Minesweeper-v0-small | 1 | 2 | 1.0 |
| 81 | NewRecruit-v0* | 2 | 2 | 1.0 |
| 82 | Nim-v0 | 2 | 1 | 1.0 |
| 83 | Nim-v0-large | 2 | 2 | 1.0 |
| 84 | Nim-v0-medium | 2 | 2 | 1.0 |
| 85 | Othello-v0* | 2 | 62 | 1.0 |
| 86 | Othello-v0-big | 2 | 2 | 1.0 |
| 87 | Othello-v0-hard | 2 | 30 | 1.0 |
| 88 | Othello-v0-huge | 2 | 12 | 1.0 |
| 89 | Othello-v0-small | 2 | 5 | 1.0 |
| 90 | Othello-v0-tiny | 2 | 13 | 1.0 |
| 91 | PegJump-v0* | 1 | 1 | 1.0 |
| 92 | PigDice-v0 | 2 | 1 | 1.0 |
| 93 | PigDice-v0-100 | 2 | 1 | 1.0 |
| 94 | PigDice-v0-150 | 2 | 1 | 1.0 |
| 95 | PigDice-v0-200 | 2 | 1 | 1.0 |
| 96 | PigDice-v0-250 | 2 | 1 | 1.0 |
| 97 | PigDice-v0-300 | 2 | 1 | 1.0 |
| 98 | PigDice-v0-350 | 2 | 1 | 1.0 |
| 99 | PigDice-v0-400 | 2 | 1 | 1.0 |
| 100 | PigDice-v0-450 | 2 | 1 | 1.0 |
| 101 | PigDice-v0-50 | 2 | 1 | 1.0 |
| 102 | PigDice-v0-500 | 2 | 1 | 1.0 |
| 103 | PigDice-v0-long | 2 | 1 | 1.0 |
| 104 | PigDice-v0-short | 2 | 1 | 1.0 |
| 105 | Poker-v0 | 2 | 17 | 1.0 |
| 106 | Poker-v0-extreme | 2 | 7 | 1.0 |
| 107 | Poker-v0-long | 2 | 5 | 1.0 |
| 108 | Poker-v0-small | 2 | 29 | 1.0 |
| 109 | QuantumTicTacToe-v0 | 2 | 12 | 1.0 |
| 110 | ReverseTicTacToe-v0 | 2 | 3 | 1.0 |
| 111 | RushHour-v0* | 1 | 3 | 1.0 |
| 112 | SantoriniBaseFixed-v0 | 2 | 30 | 1.0 |
| 113 | Secretary-v0* | 1 | 1 | 1.0 |
| 114 | Secretary-v0-long | 1 | 1 | 1.0 |
| 115 | SimpleTak-v0 | 2 | 4 | 1.0 |
| 116 | SimpleTak-v0-extreme | 2 | 8 | 1.0 |
| 117 | SimpleTak-v0-large | 2 | 12 | 1.0 |
| 118 | SimpleTak-v0-medium | 2 | 5 | 1.0 |
| 119 | Snake-v0 | 2 | 1 | 1.0 |
| 120 | Snake-v0-large | 2 | 1 | 1.0 |
| 121 | Snake-v0-standard | 2 | 1 | 1.0 |
| 122 | Sokoban-v0* | 1 | 5 | 1.0 |
| 123 | Sokoban-v0-medium | 1 | 1 | 1.0 |
| 124 | SpiteAndMalice-v0* | 2 | 33 | 1.0 |
| 125 | Stratego-v0* | 2 | 23 | 1.0 |
| 126 | Sudoku-v0* | 1 | 5 | 1.0 |
| 127 | Sudoku-v0-easy | 1 | 5 | 1.0 |
| 128 | Sudoku-v0-hard | 1 | 9 | 1.0 |
| 129 | Sudoku-v0-medium | 1 | 4 | 1.0 |
| 130 | Sudoku-v0-very-easy | 1 | 4 | 1.0 |
| 131 | Surround-v0 | 2 | 1 | 1.0 |
| 132 | Surround-v0-large | 2 | 1 | 1.0 |
| 133 | Surround-v0-standard | 2 | 1 | 1.0 |
| 134 | Tak-v0* | 2 | 21 | 1.0 |
| 135 | Tak-v0-hard | 2 | 53 | 1.0 |
| 136 | Tak-v0-medium | 2 | 6 | 1.0 |
| 137 | TicTacToe-v0 | 2 | 4 | 1.0 |
| 138 | TowerOfHanoi-v0* | 1 | 7 | 1.0 |
| 139 | TowerOfHanoi-v0-extreme | 1 | 44 | 1.0 |
| 140 | TowerOfHanoi-v0-hard | 1 | 7 | 1.0 |
| 141 | TowerOfHanoi-v0-hardcore | 1 | 2 | 1.0 |
| 142 | TowerOfHanoi-v0-medium | 1 | 7 | 1.0 |
| 143 | UltimateTicTacToe-v0* | 2 | 13 | 1.0 |
| 144 | WildTicTacToe-v0 | 2 | 10 | 1.0 |

#### A.2 ゲームごとの報酬

| ゲーム | gemini-2.5-flash | gemini-2.5-pro | gemini-2.5-flash+harness (提案手法) | gpt-5.2 | gpt-5.2-high | harness-as-policy (提案手法) |
|---|---|---|---|---|---|---|
| 2048-v0 | 0.215 | 0.378 | 0.308 | 0.212 | 0.745 | **0.912** |
| Bandit-v0 | 0.398 | 0.201 | 0.208 | 0.350 | **1.000** | 0.459 |
| Blackjack-v0 | 0.410 | 0.330 | **0.480** | 0.460 | **0.480** | 0.410 |
| Cryptarithm-v0 | **1.000** | 0.950 | **1.000** | 0.600 | **1.000** | **1.000** |
| FifteenPuzzle-v0 | 0.107 | 0.103 | 0.162 | 0.035 | 0.183 | **0.597** |
| FrozenLake-v0 | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** |
| GuessTheNumber-v0 | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** |
| LightsOut-v0 | 0.730 | 0.802 | 0.840 | 0.691 | **1.000** | **1.000** |
| Mastermind-v0 | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** |
| Minesweeper-v0 | 0.637 | 0.586 | 0.686 | 0.593 | **1.000** | 0.940 |
| PegJump-v0 | 0.325 | 0.682 | 0.782 | 0.221 | 0.429 | **1.000** |
| RushHour-v0 | 0.688 | 0.887 | **1.000** | **1.000** | **1.000** | **1.000** |
| Secretary-v0 | 0.550 | 0.700 | 0.650 | 0.600 | **0.800** | 0.750 |
| Sokoban-v0 | 0.700 | 0.700 | 0.800 | 0.600 | **0.867** | 0.850 |
| Sudoku-v0 | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** | **1.000** |
| TowerOfHanoi-v0 | **1.000** | **1.000** | **1.000** | 0.800 | **1.000** | **1.000** |

#### A.3 ゲームごとの合法手率

| ゲーム | gemini-2.5-flash | gemini-2.5-pro | gemini-2.5-flash+harness (提案手法) | gpt-5.2 | gpt-5.2-high | harness-as-policy (提案手法) |
|---|---|---|---|---|---|---|
| 2048-v0 | 96.57% | 98.36% | 99.86% | 96.05% | 99.94% | 100.00% |
| Bandit-v0 | 99.76% | 96.39% | 99.77% | 100.00% | 100.00% | 100.00% |
| Blackjack-v0 | 99.38% | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% |
| Cryptarithm-v0 | 96.97% | 98.70% | 100.00% | 88.44% | 100.00% | 100.00% |
| FifteenPuzzle-v0 | 84.70% | 88.14% | 96.59% | 87.18% | 100.00% | 100.00% |
| FrozenLake-v0 | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% |
| GuessTheNumber-v0 | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% |
| LightsOut-v0 | 100.00% | 100.00% | 99.76% | 100.00% | 100.00% | 100.00% |
| Mastermind-v0 | 100.00% | 100.00% | 100.00% | 98.57% | 100.00% | 100.00% |
| Minesweeper-v0 | 88.69% | 81.20% | 100.00% | 81.10% | 100.00% | 100.00% |
| PegJump-v0 | 67.97% | 83.10% | 98.25% | 60.17% | 77.78% | 100.00% |
| RushHour-v0 | 82.17% | 95.36% | 97.24% | 94.51% | 100.00% | 100.00% |
| Secretary-v0 | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% |
| Sokoban-v0 | 91.89% | 97.11% | 98.48% | 95.88% | 100.00% | 100.00% |
| Sudoku-v0 | 96.77% | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% |
| TowerOfHanoi-v0 | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% | 100.00% |

#### A.4 ゲーム例: Chess-v0

本節では、観測から合法手リストを削除する方法を例示する。

##### A.4.1 元のChess-v0の観測

```
[GAME] You are playing White in a game of Chess.
Make your moves in UCI format enclosed in square brackets (e.g., [e2e4]).

[GAME] Current board:
+-----------------+
8 | r n b q k b n r |
7 | p p p p p p p p |
6 | . . . . . . . . |
5 | . . . . . . . . |
4 | . . . . . . . . |
3 | . . . . . . . . |
2 | P P P P P P P P |
1 | R N B Q K B N R |
+-----------------+
  a b c d e f g h

Valid moves: [g1h3], [g1f3], [b1c3], [b1a3], [h2h3], [g2g3], [f2f3], [e2e3],
[d2d3], [c2c3], [b2b3], [a2a3], [h2h4], [g2g4], [f2f4], [e2e4], [d2d4],
[c2c4], [b2b4], [a2a4]
```

##### A.5 「有効な手」を削除した修正版Chess-v0の観測

```
[GAME] You are playing White in a game of Chess.
Make your moves in UCI format enclosed in square brackets (e.g., [e2e4]).

[GAME] Current board:
+-----------------+
8 | r n b q k b n r |
7 | p p p p p p p p |
6 | . . . . . . . . |
5 | . . . . . . . . |
4 | . . . . . . . . |
3 | . . . . . . . . |
2 | P P P P P P P P |
1 | R N B Q K B N R |
+-----------------+
  a b c d e f g h
```

---

### B プロンプト

#### B.1 LLM-as-policy プロンプト

```
あなたは専門的で論理的かつ戦略的なAIゲームプレイヤーです。あなたのタスクは、以下の
ゲーム情報を分析し、最善の一手を決定することです。

ゲームルール、あなたのプレイヤー役割、現在のゲーム状態、および利用可能な全ての手を
注意深く読んでください。あなたの目標は、ゲームに勝つ確率を最大化するように最適に
プレイすることです。

あなたは現在プレイヤー {player_id} です。

ゲーム情報は以下の通りです:
{observation}

**あなたのタスク:**
状況を分析し、あなたの手を提示してください。以下の2つのステップに正確に従ってください。

**ステップ1: 思考**
まず、ステップバイステップの推論を提供してください。現在のゲーム状態、目標、利用可能な
手を分析してください。最も有望な選択肢の長所と短所を評価し、最終的な手を選択する理由を
説明してください。

**ステップ2: 手の提示**
思考ブロックの後、選択した最善の一手のみを提示してください。手はゲーム情報に記載された
有効な手の一つでなければなりません。

最終的な手を `<move></move>` タグで囲んでください。閉じタグ `</move>` の後に他のテキスト、
説明、句読点を追加しないでください。

正しい回答形式の例:
<move>
[あなたが選択した手]
</move>
```

#### B.2 コード改良プロンプト

```
あなたはテキストゲームの専門知識を持つPythonプログラマーです。

以下の名前のテキストゲームが与えられています: {name}

以下はゲームの説明です。
{description}

以下はゲームの行動空間の説明です。
{action_space}

あなたは以下のゲーム盤面をテキストとして、エラーフィードバック付きで観察しています。
{tasks_with_feedback}

あなたのタスクは、以下のPython関数を作成または改良することです。
```python
{code}
```

以下の関数シグネチャに従ってください。
```python
{code_signatures}
```

以下の指示に従ってください。
* コード、ゲーム盤面、エラーフィードバックについてステップバイステップで考えてください。
* ゲーム盤面を通して各行動について推論し、重要な失敗ステップを書き出してください。
* 失敗ステップの修正に役立つコード改良について推論してください。
* 行動の全シーケンスについて推論し、ゲームの進行状況を0から1の値として書き出してください。
* ゲーム進行状況の改善に役立つコード改良について推論してください。
* ループに陥ることを避けるコード改良について推論してください。
* コードを書く前に考えを書き出してください。
* 与えられた関数シグネチャに従ってください。
* 新しいコードが観察された全てのゲーム盤面を満たせるようにしてください。
* 新しいコードが現在の全てのエラーを修正できるようにしてください。
* 安全に実行できるコードのみを生成してください。
* コードは簡潔かつ正確にしてください。
* 必要に応じて、最善の合法手の一つをランダムにサンプリングして提案行動として返してください。
* try-exceptブロックを使用しないでください。
* 関数を ```python で囲んだPythonコードブロックに記述してください。
```

---

### C ハーネス関数のシグネチャ

#### C.1 Code-as-action-verifier（行動検証器としてのコード）

```python
def propose_action(board: str) -> str:
    """ゲーム盤面のテキストから有効なランダム行動を提案する

    Args:
        board (str): テキストとしてのゲーム盤面。

    Returns:
        str: 文字列としての有効なランダム行動。

    Raises:
        Exception: 有効なランダム行動の提案に失敗した場合。
    """
    raise NotImplementedError()


def is_legal_action(board: str, action: str) -> bool:
    """ゲーム盤面のテキストに対して行動文字列が有効かどうかをチェックする

    Args:
        board (str): テキストとしてのゲーム盤面。
        action (str): 文字列としての入力行動。

    Returns:
        bool: 入力行動文字列が有効かどうか。

    Raises:
        Exception: 行動文字列の有効性チェックに失敗した場合。
    """
    raise NotImplementedError()
```

#### C.2 Harness-as-policy（ポリシーとしてのハーネス）

上記と同じ関数シグネチャを使用するが、`propose_action()` のドキュメント文字列は以下の通り:

```
最終報酬が最大化されるように、ゲーム盤面のテキストから最善の合法手の一つを提案する。
```

---

### D ハーネスコードのサンプル

#### D.1 Minesweeper-v0

Minesweeper-v0の `propose_action()` コードスニペットは、最初の手のチェック、論理推論による確実に安全なセルの発見、および最良の推測のための確率的ヒューリスティックの適用によって戦略を分解している。ここではコードハーネス全体は示していない。

```python
def propose_action(board: str) -> str:
    """ゲーム盤面のテキストから最終報酬が最大化されるような
    最善の合法手の一つを提案する。

    Args:
        board (str): テキストとしてのゲーム盤面。

    Returns:
        str: 最善の合法手の一つを表す文字列。

    Raises:
        Exception: 合法手の提案に失敗した場合。
    """
    grid = parse_board_to_grid(board)
    if not grid:
        raise Exception("盤面の解析に失敗したか盤面が空です。行動を提案できません。")

    num_rows, num_cols = get_board_dimensions(grid)
    if num_rows == 0 or num_cols == 0:
        raise Exception("盤面の寸法がゼロです。行動を提案できません。")

    # 最初の手かどうかをチェック（全セルが未開示）
    all_cells_unrevealed = True
    for r_check in range(num_rows):
        for c_check in range(num_cols):
            if grid[r_check][c_check] != '.':
                all_cells_unrevealed = False
                break
        if not all_cells_unrevealed:
            break

    # 戦略1: 最初の手（全セルが未開示の場合）
    # 安全なスタートのために初期開示領域を最大化する中央セルを選択。
    if all_cells_unrevealed:
        first_move_row = num_rows // 2 - (1 if num_rows % 2 == 0 and num_rows // 2 > 0 else 0)
        first_move_col = num_cols // 2 - (1 if num_cols % 2 == 0 and num_cols // 2 > 0 else 0)
        return f"[{first_move_row} {first_move_col}]"

    # 戦略2: 確実に安全なセルと地雷の論理推論
    board_mines: list[list[bool | None]] = [[None for _ in range(num_cols)] for _ in range(num_rows)]

    # 現在開示されているセルに基づいてboard_minesを初期化
    for r in range(num_rows):
        for c in range(num_cols):
            if grid[r][c].isdigit():
                board_mines[r][c] = False

    safe_to_reveal: list[tuple[int, int]] = []
    safe_cells_set = set()

    # 新しい推論がなくなるまで複数回推論を伝播
    max_deduction_iterations = num_rows * num_cols
    for _ in range(max_deduction_iterations):
        new_deductions_made_this_iteration = False

        # --- 単純推論ルール（ルールA & B）---
        for r in range(num_rows):
            for c in range(num_cols):
                if grid[r][c].isdigit():
                    N = int(grid[r][c])
                    unrevealed_unknown_neighbors = []
                    known_mine_neighbors_count = 0
                    for dr in [-1, 0, 1]:
                        for dc in [-1, 0, 1]:
                            if dr == 0 and dc == 0:
                                continue
                            nr, nc = r + dr, c + dc
                            if 0 <= nr < num_rows and 0 <= nc < num_cols:
                                if board_mines[nr][nc] is True:
                                    known_mine_neighbors_count += 1
                                elif grid[nr][nc] == '.' and board_mines[nr][nc] is None:
                                    unrevealed_unknown_neighbors.append((nr, nc))

                    num_unrevealed_and_unknown = len(unrevealed_unknown_neighbors)
                    mines_to_deduce = N - known_mine_neighbors_count

                    # ルールA: 地雷の推論
                    if mines_to_deduce > 0 and mines_to_deduce == num_unrevealed_and_unknown:
                        for (ur, uc) in unrevealed_unknown_neighbors:
                            if board_mines[ur][uc] is None:
                                board_mines[ur][uc] = True
                                new_deductions_made_this_iteration = True

                    # ルールB: 安全セルの推論
                    elif mines_to_deduce == 0 and num_unrevealed_and_unknown > 0:
                        for (ur, uc) in unrevealed_unknown_neighbors:
                            if board_mines[ur][uc] is None:
                                board_mines[ur][uc] = False
                                if (ur, uc) not in safe_cells_set:
                                    safe_to_reveal.append((ur, uc))
                                    safe_cells_set.add((ur, uc))
                                new_deductions_made_this_iteration = True

        # --- 高度な推論ルール（部分集合ルール）---
        # （省略: 全ての手がかり制約のペアに部分集合ルールを適用）

        if not new_deductions_made_this_iteration:
            break

    # 確実に安全なセルが見つかった場合、ランダムに一つ選択。
    if safe_to_reveal:
        chosen_move = random.choice(safe_to_reveal)
        return f"[{chosen_move[0]} {chosen_move[1]}]"

    # 戦略3: 最良推測のための確率的ヒューリスティック
    # （確実に安全なセルが見つからない場合）
    # （省略: リスクスコアの計算と最小リスクの手の選択）

    raise Exception("合法手を提案できません。")
```

#### D.2 Chess-v0

Chess-v0の興味深いコードスニペットには、UCI（Universal Chess Interface）の解析とフォーマット、駒の位置特定、攻撃チェックが含まれる。ここではコードハーネス全体は示していない。

```python
def _to_uci_coord(row: int, col: int) -> str:
    """0インデックスのグリッド座標(row, col)をUCI文字列（例：'e2'）に変換する。"""
    file_char = chr(ord('a') + col)
    rank_char = str(8 - row)  # グリッド行0はランク8、グリッド行7はランク1
    return file_char + rank_char


def _from_uci_coord(coord_str: str) -> tuple[int, int] | None:
    """UCI文字列（例：'e2'）を0インデックスのグリッド座標(row, col)に変換する。
    無効な入力の場合はNoneを返す。"""
    if not (len(coord_str) == 2 and 'a' <= coord_str[0] <= 'h' and '1' <= coord_str[1] <= '8'):
        return None
    col = ord(coord_str[0]) - ord('a')
    row = 8 - int(coord_str[1])
    return row, col


def _find_king(grid: list[list[str]], king_color: str) -> tuple[int, int] | None:
    """指定された色のキングの座標を見つける。"""
    for r in range(8):
        for c in range(8):
            piece = grid[r][c]
            if (king_color == 'w' and piece == 'K') or \
               (king_color == 'b' and piece == 'k'):
                return r, c
    return None


def _is_square_attacked(grid: list[list[str]], r: int, c: int, by_white: bool) -> bool:
    """マス(r, c)が色'by_white'（白はTrue、黒はFalse）のいずれかの駒に
    攻撃されているかをチェックする。"""

    def is_attacker(piece_sym: str, is_white_attacker: bool) -> bool:
        if piece_sym == '.': return False
        return (is_white_attacker and piece_sym.isupper()) or \
               (not is_white_attacker and piece_sym.islower())

    # 1. ポーンの攻撃（斜め1マス）
    pawn_attacker_dr_from_target = 1 if by_white else -1
    for dc_pawn in [-1, 1]:
        pr, pc = r + pawn_attacker_dr_from_target, c + dc_pawn
        if 0 <= pr < 8 and 0 <= pc < 8 and grid[pr][pc].upper() == 'P':
            if is_attacker(grid[pr][pc], by_white):
                return True

    # 2. ナイトの攻撃（L字型）
    knight_moves_deltas = [(-2, -1), (-2, 1), (-1, -2), (-1, 2),
                           (1, -2), (1, 2), (2, -1), (2, 1)]
    for dr_k, dc_k in knight_moves_deltas:
        kr, kc = r + dr_k, c + dc_k
        if 0 <= kr < 8 and 0 <= kc < 8 and grid[kr][kc].upper() == 'N':
            if is_attacker(grid[kr][kc], by_white):
                return True

    # 3. キングの攻撃（任意方向1マス）
    for dr_k, dc_k in [(-1, -1), (-1, 0), (-1, 1), (0, -1),
                        (0, 1), (1, -1), (1, 0), (1, 1)]:
        kr, kc = r + dr_k, c + dc_k
        if 0 <= kr < 8 and 0 <= kc < 8 and grid[kr][kc].upper() == 'K':
            if is_attacker(grid[kr][kc], by_white):
                return True

    # 4. ルーク/クイーンの攻撃（直線）
    straight_directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    for dr_s, dc_s in straight_directions:
        for step in range(1, 8):
            sr, sc = r + dr_s * step, c + dc_s * step
            if not (0 <= sr < 8 and 0 <= sc < 8): break
            piece_at_sr_sc = grid[sr][sc]
            if piece_at_sr_sc == '.': continue
            if is_attacker(piece_at_sr_sc, by_white) and \
               (piece_at_sr_sc.upper() == 'R' or piece_at_sr_sc.upper() == 'Q'):
                return True
            else:
                break

    # 5. ビショップ/クイーンの攻撃（斜線）
    diagonal_directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    for dr_d, dc_d in diagonal_directions:
        for step in range(1, 8):
            sr, sc = r + dr_d * step, c + dc_d * step
            if not (0 <= sr < 8 and 0 <= sc < 8): break
            piece_at_sr_sc = grid[sr][sc]
            if piece_at_sr_sc == '.': continue
            if is_attacker(piece_at_sr_sc, by_white) and \
               (piece_at_sr_sc.upper() == 'B' or piece_at_sr_sc.upper() == 'Q'):
                return True
            else:
                break

    return False
```
