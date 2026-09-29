# X（Twitter）関連スキル まとめ

このプロジェクトで X の投稿を扱う Claude Code のスキル／コマンドの一覧と使い分け。

## 一覧

| スキル / コマンド | 何をするか | データ源 | コスト・所要時間 | 置き場所 |
|---|---|---|---|---|
| `twilog-bookmarks` | 指定日（JST）のブックマークを `bookmarks-YYYY-MM-DD.md` に出力 | Twilog MCP（自分のブックマーク） | 無料・数秒 | `~/.claude/skills/twilog-bookmarks/` |
| `x-posts-sync` | `AI_Reports_*.md` の X URL を一覧化し、投稿本文を取得して JSONL に保存。日本語以外は和訳し、Markdown / HTML まで作り直す | FxTwitter 公開API＋Claude（和訳） | 取得は無料・1件約0.7秒。和訳はサブエージェント（400件強で約3分） | `~/.claude/skills/x-posts-sync/` |
| `x-search`（スキル） / `/xsearch`（コマンド） | X 上の話題・反応を検索し、Grok の要約＋出典URLを返す | xAI x_search（Grok） | xAI クレジット消費・1回30〜120秒 | スキル: `~/.claude/skills/x-search/`、コマンド: `~/.claude/commands/xsearch.md`、原本: `./xsearch/` |

### 使い分け

- **自分がブックマークした投稿を集める** → `twilog-bookmarks`
- **レポートに載せた投稿を訳付きで読み返す** → `x-posts-sync`（`x_posts.html` を新しい順で開く）
- **既知の投稿URLの本文を正確に取る** → `x-posts-sync`（本文そのまま。xsearch の `--url` は要約・言い換えが混ざる）
- **URLが分からない話題を探す・反応を知る** → `x-search` / `/xsearch`

## データの流れ

```
Twilog ブックマーク
   │ /twilog-bookmarks 2026/9/16 - 2026/9/24
   ▼
bookmarks-YYYY-MM-DD.md  （見出し / 日時 投稿者 / [oembed URL]）
   │ scripts/concatenate.bash, oembed_to_md.bash など（手作業でまとめ）
   ▼
AI_Reports_YYYYMMDD-YYYYMMDD.md（直下） / AI_Report/AI_Reports_*.md（過去分）
   │ /x-posts-sync
   ▼
① 取得  x_url_list.tsv → x_posts.jsonl / x_posts_raw.jsonl
② 和訳  日本語以外の投稿 → x_posts_ja.jsonl（Claude のサブエージェントが訳す）
③ 生成  x_posts.md（古い順） / x_posts.html（新しい順）  ※どちらも訳付き
```

---

## twilog-bookmarks

Twilog に記録された自分のブックマークを、日本語見出し付きの Markdown にまとめる。

- **起動例**: 「2026/4/8のtwilogのブックマークをまとめて」「`/twilog-bookmarks 2026/3/25 - 2026/4/8`」
- **引数**: `2026/4/8` / `2026-04-08` / `20260408`。空なら JST の今日。範囲は `A - B` または `A..B`（両端含む、1日1ファイル）。
- **出力**: カレントの `bookmarks-YYYY-MM-DD.md`。古い順。
  ```
  ## {30〜60字の日本語見出し}
  {createdAt(UTC ISO8601)} {authorId}
  [oembed {contentUrl}]
  ```
- **注意点**
  - 取得後に `createdAt` を JST 換算して対象日だけ残す。
  - 既存ファイルがあると上書き前に確認。32日以上の範囲も実行前に確認。
  - 0件・APIエラー・ページ取得の途中失敗ではファイルを作らない。
- 詳細: `~/.claude/skills/twilog-bookmarks/README.md`

## x-posts-sync

AI レポートに載っている X 投稿の本文をまとめて取得し、日本語以外は和訳して、読み返し用の Markdown / HTML まで作る。

- **起動例**: 「XのURL一覧を更新して」「Xのポストを取得して」「x_posts を HTML にして」「`/x-posts-sync`」
- **1回の実行で行うこと**
  1. **取得**: レポートから X の URL を集め、未取得の投稿本文を FxTwitter から取る
  2. **和訳**: 日本語以外の投稿（引用元・X Articles を含む）で未翻訳のものを、Claude のサブエージェントが並列で訳して取り込む
  3. **生成**: 全件の `x_posts.md`（古い順）と `x_posts.html`（新しい順）を作り直す
- **オプション**
  - 取得: `--extract-only`（一覧更新のみ。和訳・生成もしない） / `--fetch-only`（取得のみ） / `--limit N` / `--dir PATH`
  - 省略: `--no-translate`（和訳しない） / `--no-render`（Markdown / HTML を作らない）
- **対象**: 直下と `AI_Report/` の `AI_Reports_YYYYMMDD[-YYYYMMDD].md`（`*_oembed.md` と `.txt` は除外）
- **出力**（直下）

  | ファイル | 内容 |
  |---|---|
  | `x_url_list.tsv` | 投稿IDで重複除去した URL 一覧（id, posted_at, author, url, title, sources）。毎回作り直し |
  | `x_posts.jsonl` | 検索用。本文、投稿者、日時、反応数、画像URL、引用元の投稿、返信先、X Articles の全文（`article_text`）、`report_title`、`sources` |
  | `x_posts_raw.jsonl` | FxTwitter の応答そのまま |
  | `x_posts_failed.tsv` | 今回取れなかった投稿（404=削除、401=非公開） |
  | `x_posts_ja.jsonl` | 和訳（id, text_ja, article_title_ja, article_text_ja）。追記型で、訳済みは再翻訳しない |
  | `x_posts.md` | 全件の Markdown（古い順・訳付き）。毎回作り直し |
  | `x_posts.html` | 全件の HTML（新しい順・訳付き）。毎回作り直し |

- **HTML の見方**（`x_posts.html` をブラウザで開く）
  - 日付目次と投稿カード。上部のボタンで「新しい順／古い順」を切り替え（ブラウザに記憶）
  - 訳がある投稿は原文の下に「日本語訳」。「訳のみ」ボタンで原文を隠せる
  - 検索欄でキーワード／`@投稿者` の AND 絞り込み（訳文も対象）。投稿者名クリックでその人だけ表示。Paper/Dark 切り替え付き
  - 画像・動画は X のサーバーを直接参照するので、閲覧にはネット接続が必要
- **個別に変換したいとき**（期間・出典で絞った版など。`--out` で別名にする）
  - Markdown: `python3 ~/.claude/skills/x-posts-sync/scripts/x_posts_to_md.py`
  - HTML: `python3 ~/.claude/skills/x-posts-sync/scripts/x_posts_to_html.py`（Markdown 版のオプション＋`--newest-first` / `--title`）
  - 共通: `--from 2026-09-16 --to 2026-09-24`（JST の投稿日）、`--source 20260916-20260924`（出典ファイル）、`--out -`（標準出力）、`--no-article`（記事本文を省略）、`--no-translation`（訳を出さない）
- **和訳の仕組み**: `x_posts_translate.py todo` で未翻訳分を切り出し → サブエージェントが訳す → 検証して `x_posts_translate.py merge` で取り込み。`status` で進み具合を確認できる。訳しても原文と同じになるもの（製品名だけ等）は「翻訳不要」として記録され、以後対象外。
- **注意点**
  - 取得済みの投稿は再取得しない（反応数は取得時点の値）。`report_title` と `sources` だけは毎回最新の一覧で更新する。
  - 取得できなかった投稿は毎回再試行される（非公開が解除されれば取れる）。
  - FxTwitter は非公式サービスなので、仕様変更や停止の可能性がある。
  - `x_posts_sync.py` を直接（cron など）実行すると取得だけで、和訳と生成は行われない。次に `/x-posts-sync` を実行したときにまとめて行われる。
  - 和訳は AI 翻訳。要約せず全文を訳すよう指示しているが、訳文の正確さまでは保証しない。
- 実績（2026-09-29）: 27ファイル → 1,278件中 1,273件取得（失敗5件は削除3・非公開2）。和訳 420件＋翻訳不要 4件。

## x-search / `/xsearch`

xAI の x_search（Grok）で X を検索する。Hermes Agent の内部ツールを `xsearch` CLI（`~/.local/bin/xsearch`）から直接呼ぶ。

- **起動**
  - スキル `x-search`: 「X でみんな何て言ってる？」のような依頼で Claude が自動で使う。
  - コマンド `/xsearch`: `/xsearch "what are people saying about MCP" --handles anthropicai`
- **主なオプション**
  - `--handles a,b` / `--exclude a,b`（最大10、併用不可）
  - `--from YYYY-MM-DD --to YYYY-MM-DD`
  - `--url <投稿URL>`：投稿者と ±1日の期間を自動設定し、本文の引用を依頼する（ベストエフォート）
  - `--images` / `--videos`（添付メディアも解析）、`--json`（構造化出力）
- **結果の読み方**
  - 返ってくるのは Grok の**要約**と `References:`（出典URL）。本文そのものではない。信頼できるのは References 側。
  - `[warning] ... UNSOURCED` が出たら、実投稿に基づかない Grok の知識からの回答。証拠として扱わない。
- **運用上の注意**（これまでの経験から）
  - クレジットに上限がある。URL を大量に一括で verbatim 取得すると xAI のスペンド上限に達し、全件失敗して当日は復旧できない。**既知URLの本文取得は `x-posts-sync` を使う**。
  - トピック探索は「キーワードで探す → 候補を20〜35件に絞って `--url` で確認」の2段階で、並列に実行する。
  - エージェント運用系のキーワードは合成回答（UNSOURCED）に、攻撃的なセキュリティ系は拒否になりやすい。防御側の言い方に言い換える。
- **セットアップ**: `uv` が必要。認証は `uvx --from hermes-agent hermes auth add xai-oauth`（SuperGrok）か、`~/.hermes/.env` に `XAI_API_KEY`。
- 詳細: `./xsearch/README.md`（原本一式: `run_x_search.py`, `xsearch`, `xsearch.md`, `SKILL.md`）

> 補足: `~/.claude/skills/synced/…/x-search/` にも同じ内容の `x-search` があります（claude.ai から同期されたもの。`anthropic-skills:x-search` として表示される）。中身は `~/.claude/skills/x-search/SKILL.md` と同一です。
