---
title: "Claude Code 企業展開向け settings.json / managed settings 推奨レポート（統合・検証版）"
date: "2026-05-25"
lang: ja
version: "v3（2件のレポートを統合し、公式ドキュメント・バイナリ抽出の環境変数一覧・公式サンプルと突き合わせて検証）"
---

# Claude Code 企業展開向け settings.json / managed settings 推奨レポート（統合・検証版）

**目的:** Claude Code を社内展開する際に、`${HOME}/.claude/settings.json` および managed settings の役割を整理し、なるべくセキュアな標準設定案を、レビュー可能かつ事実確認済みの形で提示する。

**このレポートについて:** 先行する2件の調査レポート（ChatGPT 系・Genspark 系）を統合し、各設定キー・環境変数・配置先・挙動を、公式ドキュメント（`code.claude.com/docs`）、Claude Code バイナリ（v2.1.118）から抽出された環境変数一覧、および Anthropic 公式サンプル（`anthropics/claude-code` リポジトリの `examples/settings`）と突き合わせて検証した。検証で判明した修正点は §11 にまとめている。

> **重要な前提:** Claude Code の設定は非常に流動的で、v2.1.145 時点で 80 以上の設定キーと 180 以上の環境変数が存在し、リリースごとに増減する。本レポートの設定値・挙動は本書作成時点（2026-05-25）のものであり、**展開前に必ず社内で検証したバージョンの公式ドキュメントで再確認すること**。Anthropic の公式サンプルですら「コミュニティ管理のスニペットであり、サポート対象外・不正確な場合がある。設定の正しさは利用者の責任」と明記されている。

---

## 1. エグゼクティブサマリー

`${HOME}/.claude/settings.json` の事前配布だけでは、企業セキュリティポリシーの強制手段としては不十分である。Claude Code の設定優先順位では **Managed settings が最上位**であり、コマンドライン引数・ローカルプロジェクト設定・プロジェクト設定・ユーザー設定のいずれよりも優先され、他のどのレイヤーからも上書きできない。したがって、組織として強制したい制御は、`managed-settings.json`／`managed-settings.d/`、MDM / OS ポリシー（macOS の `com.anthropic.claudecode`、Windows の `HKLM\SOFTWARE\Policies\ClaudeCode`）、または Claude.ai 管理コンソールの server-managed settings に置くべきである。

推奨方針は以下の 2 層構成である。

| レイヤー | 配置先 | 目的 | 強制力 |
|---|---|---|---|
| **Managed settings** | macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`<br>Linux / WSL: `/etc/claude-code/managed-settings.json`<br>Windows: `C:\Program Files\ClaudeCode\managed-settings.json`<br>（いずれも同階層に `managed-settings.d/` ドロップインを併用可）<br>または MDM / server-managed settings | 権限、sandbox、MCP、hooks、plugin、モデル、ログイン強制、Remote Control などの統制 | 高い（上書き不可） |
| **User settings** | `${HOME}/.claude/settings.json` | 言語、表示、軽い既定値、個人の利便性 | 低い（容易に上書きされる） |

会社標準として強く推奨する結論は以下のとおり。

1. **権限・sandbox・MCP・hooks・plugin・ログイン強制は managed settings で統制する。** user settings はセキュリティの主戦場にしない。
2. `allowManagedPermissionRulesOnly: true` を使い、ユーザー・プロジェクト側で権限ルールを広げられないようにする。
3. `permissions.disableBypassPermissionsMode: "disable"` と `permissions.disableAutoMode: "disable"` を設定する。
4. **Bash sandbox を有効化し、失敗時は fail-closed にする**（`sandbox.enabled: true` + `failIfUnavailable: true` + `allowUnsandboxedCommands: false`）。sandbox は Bash とその子プロセスにのみ効く点に注意。
5. **資格情報は permission の `Read(...)` deny と sandbox の `filesystem.denyRead` の両方で塞ぐ。** sandbox のデフォルト read は広く、明示的に deny しない限り `~/.aws` や `~/.ssh` も読める。
6. **MCP / hooks / plugin は初期状態では原則禁止**し、審査済みのものだけ allowlist で許可する。
7. **WebFetch / WebSearch と Bash 経由の `curl` / `wget` は別々に制御する。** WebFetch を止めても Bash 経由の外向き通信は残る。
8. **subprocess への資格情報引き渡しを `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` で遮断する。**（prompt injection 対策として重要。元レポートの一方のみが言及していた強力な制御。）
9. settings.json の外側も設計する: **Team / Enterprise（または Bedrock / Vertex / Foundry）での商用利用、SSO、企業プロキシ / CA / mTLS、監査ログ（OpenTelemetry）、データ保持方針（ZDR）** までを一体で設計して初めて企業利用に耐える。

---

## 2. 前提とスコープ

本レポートは、Claude Code の CLI 利用を主対象とする。IDE 拡張、Claude Desktop、Claude Code on the web、Remote Control などは関連機能として扱うが、端末上の Claude Code CLI における設定配布・権限制御を中心に整理する。

想定するセキュリティ目標は以下である。

- 認証情報、秘密鍵、`.env`、クラウド認証情報、Kubernetes 設定などを Claude Code 本体や subprocess から読み取らせない。
- 破壊的コマンド、外部送信、CI/CD・本番操作を最小権限にする。
- ユーザーやプロジェクト（クローンしてきた信頼できないリポジトリを含む）が独自に権限・MCP・hooks・plugin を広げることを防ぐ。
- 管理者が設定を監査・検証・追跡できる配布方式にする。

---

## 3. 設定アーキテクチャ

### 3.1 設定スコープと優先順位

同一キーが複数スコープにある場合、Claude Code は次の優先順位で適用する（高い順）。

1. **Managed settings**（最上位、他のどのレイヤーでも上書き不可。コマンドライン引数すら上書きできない）
2. コマンドライン引数（`--settings` など、当該セッション限り）
3. Local project settings（`.claude/settings.local.json`）
4. Project settings（`.claude/settings.json`）
5. User settings（`${HOME}/.claude/settings.json`、最下位）

スカラー値は上位スコープが下位を上書きするが、**配列値（`permissions.allow` / `ask` / `deny`、`sandbox.filesystem.*`、`sandbox.network.allowedDomains` など）はスコープ間で「連結＋重複排除」されてマージされる**。つまり、deny 配列をユーザー設定だけに置いても、下位スコープからの追加が混ざるため、企業統制には向かない。`allowManaged...Only` 系のフラグ（後述）で「managed のものだけ有効」にして初めて統制になる。

### 3.2 Managed レイヤー内部の優先順位（両元レポートとも未記載・重要）

「Managed」は単一ではなく、内部にさらに優先順位がある（高い順）。

1. **server-managed settings**（Claude.ai 管理コンソールからリモート配信）
2. **MDM / OS レベルポリシー**（macOS の managed preferences、Windows の `HKLM` レジストリ）
3. **ファイルベース**（`managed-settings.d/*.json` ＋ `managed-settings.json`）
4. **HKCU レジストリ**（Windows のユーザー単位、最下位。admin 級ソースが無い場合のみ）

重要なのは、**異なる managed 階層は互いにマージされず、最上位の 1 つだけが採用される（first-source-wins）**点。例えば server-managed settings が有効な場合、ファイルベースの `managed-settings.json` は使われない。ただし**ファイルベース階層の内部では**、`managed-settings.json`（ベース）と `managed-settings.d/` 内の `*.json`（ドロップイン）はマージされる。

### 3.3 `managed-settings.d/` ドロップインディレクトリ（v2.1.83+、両元レポートとも未記載）

`managed-settings.json` と同じシステムディレクトリに `managed-settings.d/` を置くと、複数チームが互いのファイルを編集せずに独立したポリシー断片を配布できる（systemd / sudoers の drop-in 方式）。

- マージ順: `managed-settings.json`（ベース）を最初にマージ → `managed-settings.d/*.json` をファイル名のアルファベット順にマージ。後のファイルがスカラー値を上書き、配列は連結＋重複排除、オブジェクトは deep-merge。
- 数値プレフィックスでマージ順を制御する（例: `10-telemetry.json`、`20-security.json`、`30-mcp-allowlist.json`）。
- `.` で始まる隠しファイルは無視される。

> 運用例: セキュリティチームは `20-security.json` に deny ルールと sandbox を、基盤チームは `30-mcp-allowlist.json` に MCP allowlist を、コスト管理チームは `40-model-restrictions.json` にモデル制限を、と分担できる。

### 3.4 配置先（OS 別）

| OS | ファイルベース managed settings | MDM / OS ポリシー |
|---|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json`（＋ `managed-settings.d/`） | `com.anthropic.claudecode` managed preferences（Jamf / Kandji 等の構成プロファイル） |
| Linux / WSL | `/etc/claude-code/managed-settings.json`（＋ `managed-settings.d/`） | （MDM なし。WSL は §9 の `wslInheritsWindowsSettings` 参照） |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json`（＋ `managed-settings.d/`） | `HKLM\SOFTWARE\Policies\ClaudeCode` の `Settings` 値（Group Policy / Intune）。ユーザー単位は `HKCU\SOFTWARE\Policies\ClaudeCode` |

> **Windows の注意（両元レポートとも正しく記載）:** 旧パス `C:\ProgramData\ClaudeCode\managed-settings.json` は **v2.1.75 以降サポートされない**。`C:\Program Files\ClaudeCode\` へ移行すること。

MCP を固定配布する場合の `managed-mcp.json` も同じディレクトリに置く（§7 参照）。MDM 配布テンプレート（Jamf / Kandji / Intune / Group Policy）は公式リポジトリ `anthropics/claude-code/tree/main/examples/mdm` にある。

### 3.5 設定の反映タイミングと確認

- Claude Code は設定ファイルを監視し、ほとんどのキー（`permissions`、`hooks`、`apiKeyHelper` 等）は再起動なしで反映される。`ConfigChange` hook が変更ごとに発火する。
- `model` と `outputStyle` のみセッション開始時に一度読まれ、次回再起動で反映される。
- 反映状況の確認は `/status`（読み込まれた設定ソースと配信チャネルが `(remote)` / `(plist)` / `(HKLM)` / `(HKCU)` / `(file)` のように表示される）、`/permissions`、`/config`、`/doctor`、および `claude debug` 系コマンドで行う。

---

## 4. 重要な設計判断

### 4.1 `${HOME}/.claude/settings.json` は「標準初期値」であり「強制ポリシー」ではない

user settings は優先順位が最下位で、プロジェクトの `.claude/settings.json` や `.claude/settings.local.json`、CLI 引数で上書き・追加され得る。配列型は連結マージされるため、権限や sandbox の allowlist を user settings だけで完全統制するのは不可能。**強制したいものは managed に置く。**

### 4.2 権限ルールと sandbox は役割が違う（範囲を正しく理解する）

- **権限ルール**（`Read` / `Edit` / `Bash` / `WebFetch` / `WebSearch` / `Agent` / MCP など）は Claude Code の**ツール利用**を制御する。
- **sandbox** は **Bash とその子プロセスにのみ** OS レベルのファイルシステム・ネットワーク境界を作る（macOS は Seatbelt、Linux/WSL2 は bubblewrap）。**Read / Write / WebFetch / WebSearch / MCP / hooks / 内部コマンドには効かない**（公式サンプル README に明記）。

したがって、`Read(...)` deny だけでは Python / Node / shell script などの subprocess が直接ファイルやネットワークへアクセスする経路を塞げず、逆に sandbox だけでは Claude の Read ツールや WebFetch を縛れない。**permissions と sandbox の両方**を defense-in-depth として使う。なお、`Read(...)` deny や `Edit(...)` のパスは sandbox の `denyRead` / `denyWrite` にもマージされ、`WebFetch(domain:...)` の allow は sandbox の `allowedDomains` にもマージされる。

### 4.3 資格情報は二重に塞ぐ（重要な落とし穴）

sandbox を有効にしただけでは不十分。**sandbox のデフォルト read は広く、`~/.aws/credentials` や `~/.ssh/` も明示的に `filesystem.denyRead` しない限り読める。** 同時に Claude 自身の Read ツールも `permissions.deny` の `Read(~/.aws/**)` 等で塞ぐ。両方を設定すること。

### 4.4 WebFetch と Bash ネットワークは別経路

`WebFetch` / `WebSearch` を deny しても、Bash が許可されていれば `curl` / `wget` / `python -c` / `node` などの外向き通信経路が残る。WebFetch の deny、Bash ネットワークコマンドの deny、sandbox の `network.allowedDomains` 制限を**組み合わせる**。

### 4.5 MCP・hooks・plugin は最初は閉じるのが安全

- **MCP**: 外部ツール連携の強力な拡張点。公式ディレクトリ掲載はセキュリティ監査を意味しない。初期は `allowedMcpServers: []` ＋ `allowManagedMcpServersOnly: true`（必要に応じて `managed-mcp.json` で空配布）。
- **hooks**: 任意の shell 実行・HTTP 送信ポイントになり得る。初期は `allowManagedHooksOnly: true`（＋必要なら `disableAllHooks`）。HTTP hook を使う場合は `allowedHttpHookUrls` / `httpHookAllowedEnvVars` で URL と環境変数を allowlist 化。
- **plugin / marketplace**: サプライチェーンリスク。初期は `strictKnownMarketplaces: []`（全 marketplace 追加禁止）＋ `strictPluginOnlyCustomization: true`（skills / agents / hooks / MCP を plugin・managed 由来のみに限定）。社内 marketplace を用意してから `strictKnownMarketplaces` に追加する。

### 4.6 信頼できないリポジトリを脅威モデルに含める

クローンしてきたリポジトリの `.claude/settings.json` や `.mcp.json` は攻撃ベクトルになり得る。Claude Code はこれを意識した設計になっている（例: `autoMemoryDirectory` は project/local 設定からは受け付けない＝クローンしたリポジトリにメモリ書き込み先を機密領域へ向けさせない、`defaultMode: "auto"` は project/local 設定では無視される＝リポジトリが自身に auto mode を付与できない）。`allowManagedPermissionRulesOnly` と `strictPluginOnlyCustomization` はこの脅威への中核的な防御になる。

---

## 5. 推奨 managed settings ベースライン

以下は社内標準としてレビューしやすい「堅め」の baseline。`github.example.com`、`registry.npmjs.example.com`、`pypi.example.com` は社内 Git / npm mirror / PyPI mirror に置き換える。

> **注意:**
> - `minimumVersion` は運用開始時点の検証済みバージョンに置き換えること。
> - このベースラインは検証済みの設定キー・環境変数のみで構成している（検証で除外した項目は §11 参照）。
> - 公式の `settings-strict.json` は「全 Bash を `ask`」という、より単純で厳格な方針を採る。下記は開発生産性とのバランスを取り、低リスク操作を `allow`、要注意操作を `ask`、危険操作を `deny` に振り分けている。組織の方針に応じて「全 Bash ask」に倒してもよい。

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "minimumVersion": "2.1.143",
  "language": "japanese",
  "autoUpdatesChannel": "stable",
  "model": "sonnet",
  "availableModels": ["sonnet", "haiku"],
  "cleanupPeriodDays": 7,
  "autoMemoryEnabled": false,
  "respectGitignore": true,
  "feedbackSurveyRate": 0,
  "companyAnnouncements": [
    "Claude Code は社内セキュリティポリシーに従って利用してください。秘密情報・個人情報・認証情報をプロンプトやリポジトリに含めないでください。"
  ],
  "claudeMd": "秘密情報・認証情報・個人情報をプロンプトやコミットに含めないこと。外部送信・破壊的コマンド・本番操作は事前承認が必要。",
  "env": {
    "CLAUDE_CODE_SUBPROCESS_ENV_SCRUB": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_MCP_ALLOWLIST_ENV": "1",
    "CLAUDE_CODE_DISABLE_AUTO_MEMORY": "1",
    "CLAUDE_CODE_DISABLE_BACKGROUND_TASKS": "1",
    "CLAUDE_CODE_DISABLE_CRON": "1",
    "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1",
    "CLAUDE_CODE_CERT_STORE": "system",
    "BASH_DEFAULT_TIMEOUT_MS": "120000",
    "BASH_MAX_TIMEOUT_MS": "300000",
    "BASH_MAX_OUTPUT_LENGTH": "20000",
    "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY": "4"
  },
  "permissions": {
    "defaultMode": "default",
    "disableBypassPermissionsMode": "disable",
    "disableAutoMode": "disable",
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git branch *)",
      "Bash(npm test *)",
      "Bash(npm run test *)",
      "Bash(npm run lint *)",
      "Bash(pnpm test *)",
      "Bash(pnpm run test *)",
      "Bash(pnpm run lint *)",
      "Bash(yarn test *)",
      "Bash(yarn lint *)"
    ],
    "ask": [
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(gh pr create *)",
      "Bash(gh pr edit *)",
      "Bash(rm *)",
      "Bash(docker *)",
      "Bash(kubectl *)",
      "Bash(terraform *)",
      "Bash(aws *)",
      "Bash(gcloud *)",
      "Bash(az *)"
    ],
    "deny": [
      "Read(.env)",
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(secrets/**)",
      "Read(secret/**)",
      "Read(**/*secret*)",
      "Read(**/*credential*)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)",
      "Read(~/.kube/**)",
      "Read(~/.docker/config.json)",
      "Read(~/.npmrc)",
      "Read(~/.pypirc)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Read(**/*.p12)",
      "Read(**/*.pfx)",
      "Edit(.git/**)",
      "Edit(.claude/**)",
      "Edit(.vscode/**)",
      "Edit(.idea/**)",
      "Edit(.husky/**)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(nc *)",
      "Bash(ncat *)",
      "Bash(netcat *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(rsync *)",
      "Bash(sudo)",
      "Bash(sudo *)",
      "Bash(su)",
      "Bash(su *)",
      "Bash(rm -rf *)",
      "Bash(rm -fr *)",
      "Bash(git push *)",
      "Bash(kubectl delete *)",
      "Bash(kubectl apply *)",
      "Bash(terraform apply *)",
      "Bash(terraform destroy *)",
      "WebFetch",
      "WebSearch"
    ]
  },
  "allowManagedPermissionRulesOnly": true,
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "autoAllowBashIfSandboxed": false,
    "allowUnsandboxedCommands": false,
    "excludedCommands": [],
    "filesystem": {
      "denyRead": [
        "~/.aws",
        "~/.ssh",
        "~/.gnupg",
        "~/.kube",
        "~/.docker",
        "~/.npmrc",
        "~/.pypirc",
        "~/.config/gh",
        "~/.config/gcloud",
        "~/.azure",
        "~/.claude.json"
      ],
      "denyWrite": [
        "~/.aws",
        "~/.ssh",
        "~/.gnupg",
        "~/.kube",
        "~/.docker",
        "/etc",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
        "/sbin",
        "/var/run",
        "~/.bashrc",
        "~/.zshrc",
        "~/.profile"
      ],
      "allowWrite": [],
      "allowManagedReadPathsOnly": true
    },
    "network": {
      "allowedDomains": [
        "github.example.com",
        "registry.npmjs.example.com",
        "pypi.example.com"
      ],
      "deniedDomains": [],
      "allowManagedDomainsOnly": true,
      "allowAllUnixSockets": false,
      "allowLocalBinding": false
    }
  },
  "allowedHttpHookUrls": [],
  "httpHookAllowedEnvVars": [],
  "allowManagedHooksOnly": true,
  "disableAllHooks": true,
  "disableSkillShellExecution": true,
  "allowedMcpServers": [],
  "deniedMcpServers": [],
  "allowManagedMcpServersOnly": true,
  "strictKnownMarketplaces": [],
  "strictPluginOnlyCustomization": true,
  "channelsEnabled": false,
  "allowedChannelPlugins": [],
  "disableAgentView": true,
  "disableRemoteControl": true,
  "disableDeepLinkRegistration": "disable"
}
```

> **Windows / PowerShell について:** 上記の Bash ルールは PowerShell ツール（`CLAUDE_CODE_USE_POWERSHELL_TOOL=1` または `defaultShell: "powershell"` で有効化）には適用されない。Windows で PowerShell ツールを使う場合は、別途 `PowerShell(Invoke-WebRequest *)`、`PowerShell(Invoke-RestMethod *)`、`PowerShell(iwr *)`、`PowerShell(irm *)`、`PowerShell(curl *)`、`PowerShell(ssh *)`、`PowerShell(scp *)`、`PowerShell(Remove-Item -Recurse *)`、`PowerShell(Start-Process *)`、`PowerShell(Set-ExecutionPolicy *)` 等を `deny` に追加する。PowerShell ツールを有効化しないなら、これらのルールは不要。

> **高機密向けの追加（任意）:** `"CLAUDE_CODE_SKIP_PROMPT_HISTORY": "1"`（プロンプト履歴・transcript をディスクに書かない）。自社配布バイナリで更新を完全に止めるなら `"DISABLE_UPDATES": "1"`。`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` は自動更新も止めるため、telemetry だけ止めたい場合は代わりに `DISABLE_TELEMETRY=1` ＋ `DISABLE_ERROR_REPORTING=1`（＋ `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`）を使うと更新機構を壊さずに済む。

---

## 6. 設定項目ごとの推奨理由

| 領域 | 推奨設定 | 理由 |
|---|---|---|
| Managed settings | 使用必須 | 管理者が配布し、他のどのレイヤーよりも優先される（上書き不可）。 |
| `allowManagedPermissionRulesOnly` | `true` | ユーザー・プロジェクトが独自の `allow` / `ask` / `deny` を定義して権限を広げることを防ぐ。 |
| `permissions.disableBypassPermissionsMode` | `"disable"` | `--dangerously-skip-permissions` / bypassPermissions を無効化。全権限プロンプトをスキップする危険モードを封じる。 |
| `permissions.disableAutoMode` | `"disable"` | auto mode（自動承認系）を無効化。`Shift+Tab` の選択肢からも外れ、`--permission-mode auto` も拒否される。 |
| `permissions.defaultMode` | `"default"` | 既定の権限モード。高機密では `"plan"`（読み取り・計画のみで編集に承認が必要）も検討。`acceptEdits` / `dontAsk` / `auto` は挙動が異なるため permission-modes ドキュメントで確認の上で採用判断する。 |
| `sandbox.enabled` | `true` | Bash と子プロセスに OS レベルの filesystem / network 制約をかける。 |
| `sandbox.failIfUnavailable` | `true` | sandbox を起動できない端末で、警告だけ出して unsandboxed 実行されることを防ぐ（fail-closed）。 |
| `sandbox.allowUnsandboxedCommands` | `false` | `dangerouslyDisableSandbox` による sandbox 回避を完全に封じる。 |
| `sandbox.filesystem.allowManagedReadPathsOnly` | `true` | ユーザー・プロジェクト側の read 緩和（`allowRead`）を無効化。 |
| `sandbox.network.allowManagedDomainsOnly` | `true` | ユーザー・プロジェクト側の domain allowlist 追加を無効化。 |
| `allowedMcpServers: []` ＋ `allowManagedMcpServersOnly: true` | 初期は MCP 禁止 | MCP は強力な拡張点。審査済みサーバーだけを許可する。denylist (`deniedMcpServers`) は全スコープから常にマージされ、allowlist より優先。 |
| `disableAllHooks` ＋ `allowManagedHooksOnly` | 初期は hooks 禁止 | hooks はコマンド実行・HTTP 送信経路になり得る。必要なものだけ managed hooks ＋ URL/env allowlist で許可。 |
| `strictKnownMarketplaces: []` | 初期は marketplace 禁止 | plugin サプライチェーンを社内審査済み marketplace に限定する準備ができるまで禁止。 |
| `strictPluginOnlyCustomization` | `true` | skills / agents / hooks / MCP をユーザー・プロジェクト由来で読み込ませない（plugin・managed のみ）。 |
| `disableRemoteControl` | `true` | 端末のローカル filesystem に接続する機能。初期は無効化し、必要時のみ解放（v2.1.128+）。 |
| `disableAgentView` | `true` | バックグラウンドエージェント／agent view（`--bg` 等）を無効化。 |
| `disableDeepLinkRegistration` | `"disable"` | `claude-cli://` プロトコルハンドラ登録を防ぐ。 |
| `channelsEnabled` | `false` | channels（外部メッセージ push）を無効化。 |
| `claudeMd`（managed） | セキュリティ指示を注入 | `companyAnnouncements`（起動時バナーのみ）と異なり、組織管理のメモリとしてモデルの文脈に常時注入される。user/project からは無視される。 |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` | 設定推奨 | Anthropic / クラウドプロバイダの資格情報を Bash・hooks・MCP stdio などの子プロセスに渡さない。prompt injection 対策として重要。 |
| `CLAUDE_CODE_MCP_ALLOWLIST_ENV=1` | 設定推奨 | MCP サーバーへ渡す環境変数の allowlist フィルタを有効化（既定は local-agent entrypoint のみ有効）。 |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`（＋ `autoMemoryEnabled: false`） | 設定推奨 | 自動メモリの読み書きを止め、機密の意図せぬ永続化を防ぐ。 |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` | 要検討 | telemetry / error reporting / feedback / 自動更新などの非必須通信をまとめて停止。**自動更新も止まるため**、MDM / package manager 等で別途更新管理が必要。 |
| `CLAUDE_CODE_CERT_STORE=system` | 環境依存 | 信頼する CA ストアを指定（`bundled` / `system` のカンマ区切り）。社内 CA を使う環境向け。 |
| `BASH_*_TIMEOUT_MS` / `BASH_MAX_OUTPUT_LENGTH` / `MAX_TOOL_USE_CONCURRENCY` | 任意 | 実行時間・出力長・並列度の上限。暴走・過剰出力の抑制。値は運用に合わせ調整。 |
| `cleanupPeriodDays` | `7`（既定 30） | セッションファイルの保持期間を短縮（最小 1、`0` は不可）。 |

---

## 7. MCP を完全に止める場合

managed settings に以下を入れる。

```json
{
  "allowedMcpServers": [],
  "allowManagedMcpServersOnly": true
}
```

さらに、端末に `managed-mcp.json` を空の server map で配布する。

```json
{ "mcpServers": {} }
```

`managed-mcp.json` が存在する場合、Claude Code はそのファイルで定義されたサーバーだけを読み込む。空配布で MCP は読み込まれず、ユーザーの `claude mcp add` も企業ポリシーで拒否される。配置先は §3.4 の managed settings と同じディレクトリ。

> 特定サーバーだけ許可する場合は `allowedMcpServers: [{ "serverName": "github" }]` のように列挙する（公式 `serverName` 形式）。`deniedMcpServers` は全スコープから常にマージされ、allowlist より優先される。

---

## 8. settings.json の外側で会社が追加すべき対策

設定ファイルだけでは「何を禁止するか」しか決められない。以下を併せて設計する。

### 8.1 商用利用（Team / Enterprise / API / Bedrock / Vertex / Foundry）
Free / Pro / Max の consumer 前提ではなく、商用条件下で利用する。商用条件では、Claude Code に送られたコード・プロンプトを生成モデルの学習に使わない方針。Enterprise では Zero Data Retention（ZDR）も利用可能。

### 8.2 SSO / domain capture / role-based permissions
Claude for Enterprise では SSO、domain capture、role ベース権限、Compliance API、managed policy が提供される。個別 API キーの野放図な配布より IdP 連携と集中管理を優先する方が、オフボーディング・監査の面で優れる。`forceLoginMethod` / `forceLoginOrgUUID`（managed settings）で個人アカウントや別組織での利用をブロックできる。`forceLoginOrgUUID` に空配列を入れると fail-closed でログイン不可になる点に注意。

### 8.3 プロキシ / CA / mTLS
`HTTPS_PROXY` / `HTTP_PROXY`、`NODE_EXTRA_CA_CERTS`、`CLAUDE_CODE_CLIENT_CERT` / `CLAUDE_CODE_CLIENT_KEY` などで企業プロキシ・社内 CA・mTLS に対応できる。出口を corporate proxy に統一し、必要ドメインのみ許可する。`NO_PROXY` の扱いはバージョンにより異なるため、利用バージョンの corporate-proxy ドキュメントで確認すること。

### 8.4 subprocess への資格情報引き渡し防止
`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` を設定すると、Anthropic / クラウドプロバイダの資格情報が Bash・hooks・MCP stdio サーバーなどの子プロセスに渡らなくなる（§5・§6 で baseline に組み込み済み）。

### 8.5 履歴・痕跡の削減
`cleanupPeriodDays` の短縮に加え、必要に応じて `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` でセッション履歴・transcript をディスクに書かせない。高機密リポジトリ・CI・短命環境で有効。

### 8.6 アップデート統制
自社配布バイナリを使う場合、`DISABLE_UPDATES=1`（管理者級、`DISABLE_AUTOUPDATER` より優先）で勝手な更新を止め、検証済みバージョンだけを展開する。`minimumVersion` で下限を固定。

### 8.7 監査ログ / OpenTelemetry
OpenTelemetry ベースの監視で、tool decision、permission mode 変更、hook block、認証イベント、MCP 接続、plugin install、コマンド実行・ファイル操作などを収集できる。「何を禁止するか」だけでなく「何が起きたか」を見る体制を作る。詳細ログ（`OTEL_LOG_USER_PROMPTS`、`OTEL_LOG_TOOL_CONTENT` など）は機微情報を含み得るため、初期はメタデータ中心で始め、必要に応じて段階的に詳細化する。

### 8.8 高度な managed 制御（必要に応じて）
- `forceRemoteSettingsRefresh: true`（managed-only）: server-managed settings を新規取得できるまで CLI 起動をブロックし、取得失敗時は fail-closed。起動直後に managed なしで動く「すき間」を塞ぐ。
- `policyHelper`（v2.1.136+、MDM / system ファイルのみ）: 端末の状態・ID・リモートサービスから managed settings を起動時に動的算出する executable を指定。
- `parentSettingsBehavior`（v2.1.133+）: Claude Desktop / IDE 拡張など埋め込みホストが SDK 経由で供給する managed settings の扱い。既定 `"first-wins"`（admin tier があれば破棄）、`"merge"` にすると admin tier の下でポリシーを「厳しくする方向にのみ」適用可能。

---

## 9. 導入時のチェックリスト

### 9.1 事前設計
- [ ] Claude for Team / Enterprise、Console API、Bedrock、Vertex AI、Microsoft Foundry のどれを使うか決める。
- [ ] 配布方式を決める（server-managed / MDM・OS ポリシー / file-based managed settings ＋ `managed-settings.d/`）。複数の managed 階層はマージされず最上位のみ採用される点に注意。
- [ ] Windows / WSL の取り扱いを決める。Windows の admin 級 managed settings を WSL に継承させたい場合は `wslInheritsWindowsSettings: true` を検討（HKLM か `C:\Program Files\ClaudeCode\managed-settings.json` に設定、HKCU を WSL に効かせるには HKCU にも設定が必要）。
- [ ] `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` を使う場合、自動更新の代替手段を用意する。
- [ ] チーム分担が必要なら `managed-settings.d/` のファイル命名規約（数値プレフィックス）を決める。

### 9.2 ポリシー設計
- [ ] `permissions.allow` は読み取り・テスト・lint など低リスク操作に限定。
- [ ] `permissions.ask` に git commit、PR 作成、Docker、Kubernetes、Terraform、cloud CLI などを入れる。
- [ ] `permissions.deny` に credential 読み取り、破壊的コマンド、外部送信、WebFetch / WebSearch を入れる。
- [ ] sandbox の `filesystem.denyRead` / `denyWrite` に credential・shell profile・system path を入れる（**permission の Read deny と二重に**）。
- [ ] `sandbox.network.allowedDomains` を社内許可ドメインだけに限定し、`allowManagedDomainsOnly: true`。
- [ ] MCP / hooks / plugin は初期禁止、必要なものだけ審査後に allowlist 化。
- [ ] `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` を設定。

### 9.3 検証
- [ ] JSON schema（`https://json.schemastore.org/claude-code-settings.json`）で構文確認。公開 schema は最新キーに追随しないことがあるため、検証警告＝設定不正とは限らない。
- [ ] `/status` で managed settings の読み込み元・配信チャネル（`(remote)`/`(plist)`/`(HKLM)`/`(HKCU)`/`(file)`）を確認。
- [ ] `/permissions` で権限ルールの適用状況を確認。`/doctor`・`claude debug` 系で設定の有効性を確認。
- [ ] `.env`、`~/.ssh`、`~/.aws`、`~/.kube` が（Read ツール・Bash subprocess の両方から）読めないことを確認。
- [ ] `curl` / `wget` / WebFetch / WebSearch がポリシー通り拒否されることを確認。
- [ ] `kubectl apply`、`terraform apply`、`git push` が ask または deny されることを確認。
- [ ] sandbox 未対応・依存不足端末で `failIfUnavailable` が fail-closed することを確認。
- [ ] `claude mcp list` / `claude mcp add` で MCP 制限が有効であることを確認。
- [ ] `--dangerously-skip-permissions` が拒否されることを確認。

---

## 10. レビュー時の論点

| 論点 | 推奨初期判断 | レビュー観点 |
|---|---|---|
| WebFetch / WebSearch | 原則 deny | 社内 proxy / allowlist 経由で必要か。必要なら `WebFetch(domain:...)` で限定。 |
| Bash ネットワーク | `curl` / `wget` 等 deny | package download を社内 mirror に限定できるか。 |
| Git push | 原則 deny または ask | Claude Code から直接 push させる運用を許すか。 |
| Kubernetes / Terraform | 原則 ask または deny | dev / staging / prod で分けるか。 |
| Docker | ask | Docker socket 経由でホスト権限に近づくため、利用シナリオを限定するか。`sandbox.excludedCommands` で扱う必要があるか。 |
| MCP | 初期は禁止 | 社内審査済み MCP catalog を作るか。 |
| hooks | 初期は禁止 | 監査・ログ出力など managed hooks として必要なものがあるか。 |
| plugin | 初期は禁止 | 社内 marketplace を用意するか。 |
| Remote Control / agent view | 初期は禁止 | Team / Enterprise 管理画面と端末側 managed settings の両方で扱うか。 |
| auto mode | 初期は禁止 | 検証済みリポジトリ・隔離環境だけで許可するか。 |
| defaultMode | `default` | 高機密で `plan` にするか。`dontAsk` / `acceptEdits` / `auto` の挙動を確認したか。 |

---

## 11. 元レポートからの主な修正・検証結果

本統合版で、元の2レポートに対して行った主な修正・確認は以下のとおり。

### 11.1 修正した誤り
- **環境変数 `CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY` を削除。** Claude Code バイナリ（v2.1.118）の環境変数一覧に存在せず、実在しない可能性が高い。PowerShell 制御の実在メカニズムは `CLAUDE_CODE_USE_POWERSHELL_TOOL`（ツール有効化）、`defaultShell: "powershell"`、`CLAUDE_CODE_PWSH_PARSE_TIMEOUT_MS` であり、PowerShell コマンドの制限は `PowerShell(...)` permission ルールで行う（§5 の Windows 注記参照）。
- **ドキュメント URL を現行の `code.claude.com/docs/en/...` に統一。** 一方のレポートが使っていた `docs.anthropic.com/en/docs/claude-code/...` は旧パス（リダイレクトはされるが正準ではない）。

### 11.2 検証して「正しい」と確認した主な項目
- 設定優先順位（Managed > CLI 引数 > Local > Project > User）と配列のマージ挙動。
- managed settings 配置先（macOS / Linux・WSL / Windows）。**Windows は `C:\Program Files\ClaudeCode\` が正しく、`C:\ProgramData\...` は v2.1.75 で廃止**（両レポートとも正しく記載）。
- 検証で実在を確認した設定キー: `allowManagedPermissionRulesOnly`、`disableBypassPermissionsMode`、`disableAutoMode`、`allowManagedHooksOnly`、`disableAllHooks`、`disableSkillShellExecution`、`allowedMcpServers`/`deniedMcpServers`/`allowManagedMcpServersOnly`、`strictKnownMarketplaces`、`strictPluginOnlyCustomization`、`channelsEnabled`/`allowedChannelPlugins`、`disableAgentView`、`disableRemoteControl`、`disableDeepLinkRegistration`、`forceLoginMethod`/`forceLoginOrgUUID`/`forceRemoteSettingsRefresh`、`wslInheritsWindowsSettings`、`allowedHttpHookUrls`/`httpHookAllowedEnvVars`、sandbox 一式。
- 検証で実在を確認した環境変数: `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`、`CLAUDE_CODE_MCP_ALLOWLIST_ENV`、`CLAUDE_CODE_DISABLE_AUTO_MEMORY`、`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`、`CLAUDE_CODE_DISABLE_CRON`、`CLAUDE_CODE_DISABLE_1M_CONTEXT`、`CLAUDE_CODE_CERT_STORE`、`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`、`CLAUDE_CODE_SKIP_PROMPT_HISTORY`、`DISABLE_UPDATES`、`CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY`（既定 10）。
- 公式サンプル `settings-strict.json` / `settings-bash-sandbox.json` / `settings-lax.json` は実在し、`disableBypassPermissionsMode`・`allowManagedPermissionRulesOnly`・`allowManagedHooksOnly`・`strictKnownMarketplaces: []`・sandbox lockdown を含むことを確認（ただし**公式が「コミュニティ管理・不正確の可能性あり」と免責**している点に留意）。

### 11.3 要確認（バージョン依存・公式一覧に未掲載）
- `BASH_DEFAULT_TIMEOUT_MS` / `BASH_MAX_TIMEOUT_MS`: 長く文書化されてきた変数だが、参照したバイナリ抽出一覧（v2.1.118）には `BASH_MAX_OUTPUT_LENGTH` のみ確認できた。利用バージョンの env-vars ドキュメントで再確認すること。
- `NO_PROXY` のサポート: corporate-proxy ドキュメントとバイナリ抽出で記述が食い違う（バージョン依存の可能性）。利用バージョンで確認すること。

### 11.4 両レポートが見落としていた重要項目（本版で追加）
- Managed 階層内部の優先順位と first-source-wins（§3.2）。
- `managed-settings.d/` ドロップインディレクトリ（§3.3、v2.1.83+）。
- 資格情報の二重防御（permission の Read deny ＋ sandbox の denyRead、§4.3）。
- sandbox が Bash 専用で Read/WebFetch/MCP/hooks には効かないという範囲の明確化（§4.2）。
- `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`（一方のレポートのみ言及→ baseline に統合、§5）。
- 信頼できないリポジトリを脅威モデルに含める観点と関連設計（§4.6）。
- `claudeMd`（managed memory）、`policyHelper`、`parentSettingsBehavior`、`forceRemoteSettingsRefresh` などの高度な managed 制御（§6・§8.8）。

---

## 12. 実務上の推奨プロファイル

### 標準開発端末
- Managed settings を必須化。`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`。
- sandbox を有効化し、社内 Git / package mirror / artifact repository だけネットワーク許可。
- WebFetch / WebSearch と Bash 外部通信は原則 deny。
- Git commit / PR 作成は ask、Git push は deny または ask。

### セキュア開発端末 / 高機密リポジトリ
- `sandbox.network.allowedDomains` を空または社内ドメインのみ。
- Docker / kubectl / terraform / cloud CLI は deny。
- MCP / hooks / plugin / Remote Control / agent view は完全禁止。
- `defaultMode: "plan"`、`CLAUDE_CODE_SKIP_PROMPT_HISTORY=1`、Enterprise の ZDR、監査強化を併用。
- 必要に応じて dev container / VM などの追加隔離。

### AI champion / 高度利用者
- 標準より広い `ask` を許可（`allow` は広げない。必要なものもまず `ask` から）。
- MCP / plugin は審査済みのみ許可し、`allowManagedMcpServersOnly` と `strictKnownMarketplaces` は維持。

---

## 13. 最終結論（上司レビュー向け一言）

**Claude Code を会社で展開する際、`${HOME}/.claude/settings.json` の統一は補助策としては有効だが、セキュリティの本命は managed settings による強制配布である。** さらに、Bash sandbox（fail-closed）、資格情報の二重防御、MCP / hooks / plugin の allowlist、subprocess 環境スクラブ、ログイン強制（SSO）、プロキシ / CA / mTLS、履歴削減、更新統制、監査ログ（OpenTelemetry）まで含めて設計して初めて、企業利用に耐える安全性に近づく。設定キー・環境変数は流動的なため、**展開前に検証済みバージョンの公式ドキュメントで再確認し、`managed-settings.d/` と検証コマンド（`/status`・`/permissions`・`/doctor`）で実機確認すること。**

---

## 14. 参考資料

- Claude Code settings（設定スコープ・優先順位・配置先・全設定キー）: https://code.claude.com/docs/en/settings
- Configure permissions（permission system・managed-only settings）: https://code.claude.com/docs/en/permissions
- Sandboxing: https://code.claude.com/docs/en/sandboxing
- Environment variables: https://code.claude.com/docs/en/env-vars
- Server-managed settings（fail-closed startup）: https://code.claude.com/docs/en/server-managed-settings
- Control MCP server access（managed-mcp.json）: https://code.claude.com/docs/en/managed-mcp
- Managed marketplace restrictions（strictKnownMarketplaces）: https://code.claude.com/docs/en/plugin-marketplaces
- Hooks: https://code.claude.com/docs/en/hooks
- Corporate proxy: https://code.claude.com/docs/en/corporate-proxy
- Monitoring usage（OpenTelemetry）: https://code.claude.com/docs/en/monitoring-usage
- Data usage（学習利用・ZDR）: https://code.claude.com/docs/en/data-usage
- Set up Claude Code for your organization（管理者向け配布）: https://code.claude.com/docs/en/admin-setup
- 公式サンプル（settings）: https://github.com/anthropics/claude-code/tree/main/examples/settings
- 公式 MDM 配布テンプレート: https://github.com/anthropics/claude-code/tree/main/examples/mdm
- JSON Schema（settings.json）: https://json.schemastore.org/claude-code-settings.json

> 検証の補助として、Claude Code バイナリから抽出された環境変数一覧（コミュニティ）も参照した。`CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY` の非実在判定はこの一覧（v2.1.118）に基づく。設定の正準は常に公式ドキュメントとし、本レポートの値は展開前に必ず再確認すること。
