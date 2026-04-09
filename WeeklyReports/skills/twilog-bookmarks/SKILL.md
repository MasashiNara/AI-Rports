---
name: twilog-bookmarks
description: 指定した日付（JST）にTwilogでブックマークしたツイートを収集し、決まったMarkdownフォーマットでファイル出力する。ユーザーが「YYYY/M/Dのtwilogのブックマークをまとめて」のように依頼したら起動する。
user-invocable: true
allowed-tools:
  - mcp__twilog__get_twitter_posts
  - Write
  - Read
  - Bash(mkdir *)
---

# /twilog-bookmarks — Twilogブックマークまとめ

引数: `$ARGUMENTS`

`$ARGUMENTS` から対象日付（JST）を解釈する。`2026/4/8`, `2026-04-08`, `20260408` などを許容する。引数が空なら、JSTの「今日」を対象にする。出力先パスが第2引数で指定された場合はそこへ書く。指定がなければ、カレントディレクトリの `bookmarks-YYYY-MM-DD.md` に書く。

## 手順

1. **日付の正規化**
   - 引数を `YYYY-MM-DD`（JST基準）に正規化する。これを `JST_DATE` と呼ぶ。
   - `YYYYMMDD` 形式（`API_DATE`）も用意する。

2. **Twilogから取得**
   - `mcp__twilog__get_twitter_posts` を以下で呼ぶ:
     - `timeline_filter`: `bookmarks`
     - `startDate`: `API_DATE`
     - `endDate`: `API_DATE`
     - `page`: `1`
   - レスポンスの `meta.maxPage` が 2 以上なら、`page` を 2, 3, ... と最終ページまで繰り返し呼んで `logs` を結合する。
   - **注意**: Twilog API は基本JSTで日付フィルタするが、念のため取得後にクライアント側で `createdAt`（UTC）をJSTに変換し、`JST_DATE` と一致するもののみを残す。
     - 変換式: JSTの日付 = `createdAt` の UTC エポックに +9 時間して `YYYY-MM-DD` を取り出す。

3. **時系列ソート**
   - `createdAt` の昇順（古い順）で並べ替える。
   - 注: 直前の例示出力では新しい順だったが、ファイルに残す形式としては時系列順が読みやすいので昇順を既定とする。ユーザーが「新しい順で」と明示したらその限りではない。

4. **見出しの要約**
   - 各ツイートの `content` から、URL・ハッシュタグ・改行を取り除いた本文をもとに、日本語で簡潔な見出し（30〜60文字目安）を作る。
   - 引用RTの場合は引用元の話題を含めて要約する。
   - 元のtweetの主題が一目で分かる名詞句を優先する（「〜について」「〜が話題」のような薄い言い回しは避ける）。

5. **ファイル出力**
   - 出力パス（既定: `./bookmarks-YYYY-MM-DD.md`）に以下のフォーマットで `Write` する。先頭・末尾に余計な行を入れない。

   ```
   ## {見出し1}
   {createdAt(ISO8601 UTC, 例: 2026-04-02T08:36:46.000Z)} {authorId}
   [oembed {contentUrl}]

   ## {見出し2}
   {createdAt} {authorId}
   [oembed {contentUrl}]
   ```

   - エントリ間は空行1つで区切る。
   - `createdAt` は API レスポンスの値をそのまま使う（UTCのISO8601）。JSTには変換しない（フォーマット指定どおり）。
   - `authorId` は `@` を付けず、APIレスポンスの `authorId` の値そのままを使う。
   - `contentUrl` はそのまま `[oembed ...]` の中に入れる。

6. **完了報告**
   - 取得件数と出力ファイルパスを1〜2行で報告する。0件なら「該当ブックマークなし」と伝えてファイルは作らない。

## エッジケース

- 引数が日付として解釈できない場合は、ユーザーに正しい形式を提示して停止する。勝手に推測しない。
- 出力先ファイルが既に存在する場合は、上書き前に件数とパスを示してユーザーに確認する。
- API がエラーまたは空レスポンスを返した場合は、その旨を報告してファイルを作成しない。
- ページ取得中に途中エラーが出た場合は、何ページまで取れたかを明示して停止する。部分的な結果でファイルを作らない。
