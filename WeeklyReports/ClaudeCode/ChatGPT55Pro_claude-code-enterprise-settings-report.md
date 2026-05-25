---
title: "Claude Code 企業展開向け settings.json / managed settings 推奨レポート"
date: "2026-05-25"
lang: ja
---

# Claude Code 企業展開向け settings.json / managed settings 推奨レポート

**作成日:** 2026-05-25  
**目的:** Claude Code を社内展開する際に、`${HOME}/.claude/settings.json` および managed settings の役割を整理し、なるべくセキュアな標準設定案をレビュー可能な形で提示する。

---

## 1. エグゼクティブサマリー

`${HOME}/.claude/settings.json` の事前配布だけでは、企業セキュリティポリシーの強制手段としては不十分である。Claude Code の設定優先順位では **Managed settings が最上位**であり、ユーザー設定・プロジェクト設定・ローカルプロジェクト設定より優先される。組織として強制したい制御は、`managed-settings.json`、MDM / OS ポリシー、または Claude.ai 管理コンソールの server-managed settings に置くべきである。[^settings-scope][^admin-setup]

推奨方針は以下の 2 層構成である。

| レイヤー | 配置先 | 目的 | 強制力 |
|---|---|---|---|
| Managed settings | macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`<br>Linux / WSL: `/etc/claude-code/managed-settings.json`<br>Windows: `C:\Program Files\ClaudeCode\managed-settings.json`<br>または Claude.ai 管理コンソール | 権限、sandbox、MCP、hooks、plugin、モデル、Remote Control などの統制 | 高い |
| User settings | `${HOME}/.claude/settings.json` | 言語、表示、軽い既定値、個人の利便性 | 低い |

本レポートの結論として、会社標準では次を強く推奨する。

1. **権限・sandbox・MCP・hooks・plugin は managed settings で統制する。**  
2. **`allowManagedPermissionRulesOnly: true` を使い、ユーザー・プロジェクト側で権限ルールを広げられないようにする。**  
3. **`permissions.disableBypassPermissionsMode: "disable"` と `permissions.disableAutoMode: "disable"` を設定する。**  
4. **Bash sandbox を有効化し、失敗時は fail-closed にする。**  
5. **MCP / hooks / plugin は初期状態では原則禁止し、審査済みのものだけ許可する。**  
6. **WebFetch / WebSearch と Bash 経由の `curl` / `wget` を別々に制御する。WebFetch を止めても Bash 経由の外向き通信は残る。**[^admin-enforce][^permissions-network]

---

## 2. 前提とスコープ

本レポートは、Claude Code の CLI 利用を主対象とする。IDE 拡張、Claude Desktop、Claude Code on the web、Remote Control などは関連機能として扱うが、端末上の Claude Code CLI における設定配布・権限制御を中心に整理する。

想定するセキュリティ目標は以下である。

- 認証情報、秘密鍵、`.env`、クラウド認証情報、Kubernetes 設定などを Claude Code や subprocess から読み取らせない。
- 破壊的コマンド、外部送信、CI/CD・本番操作を最小権限にする。
- ユーザーやプロジェクトが独自に権限・MCP・hooks・plugin を広げることを防ぐ。
- 管理者が設定を監査・検証できる配布方式にする。

---

## 3. 重要な設計判断

### 3.1 `${HOME}/.claude/settings.json` は「標準初期値」であり「強制ポリシー」ではない

Claude Code の設定優先順位は、Managed settings、コマンドライン引数、Local project settings、Project settings、User settings の順である。User settings である `${HOME}/.claude/settings.json` は最下位に位置するため、プロジェクト側の `.claude/settings.json` や `.claude/settings.local.json` によって多くの値が変更・追加され得る。配列型の設定は置換ではなく連結・重複排除されるため、権限や sandbox の allowlist をユーザー設定だけで完全統制するのは難しい。[^settings-precedence]

### 3.2 権限ルールと sandbox は役割が違う

権限ルールは Claude Code のツール利用を制御する。一方、sandbox は Bash とその子プロセスに対して OS レベルのファイルシステム・ネットワーク境界を作る。したがって、`Read(...)` や `WebFetch(...)` の deny だけでは、Python / Node / shell script などの subprocess が直接ファイルやネットワークへアクセスする経路を完全には塞げない。防御層として、**permissions と sandbox の両方**を使うべきである。[^permissions-sandbox][^sandbox-settings]

### 3.3 WebFetch と Bash ネットワークは別経路

`WebFetch` を deny しても、Bash が許可されていれば `curl`、`wget`、`python -c`、`node` などの外向き通信経路が残る。Claude Code の公式ドキュメントでも、WebFetch 単独ではネットワークアクセスを防げず、Bash ネットワークツールや sandbox のネットワーク制御を組み合わせるべきと説明されている。[^permissions-network]

### 3.4 MCP は最初は閉じるのが安全

MCP サーバーは Claude Code に外部ツール連携を追加する強力な拡張点である。公式ディレクトリ掲載はセキュリティ監査や管理を意味しないため、企業展開では「何でも追加可」ではなく、`managed-mcp.json` による固定配布、または `allowedMcpServers` と `allowManagedMcpServersOnly` による allowlist 運用を推奨する。[^managed-mcp]

---

## 4. 推奨 managed settings ベースライン

以下は、社内標準としてレビューしやすい「堅め」の baseline である。`github.example.com`、`registry.npmjs.example.com`、`pypi.example.com` は社内 Git、社内 npm mirror、社内 PyPI mirror などに置き換える。

> 注意: `minimumVersion` は運用開始時点の検証済みバージョンに置き換えること。ここでは、本レポート作成時点で公式ドキュメントに記載のある v2.1.143 以降の設定群を前提にしている。

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "minimumVersion": "2.1.143",
  "language": "japanese",
  "autoUpdatesChannel": "stable",
  "model": "sonnet",
  "availableModels": [
    "sonnet",
    "haiku"
  ],
  "cleanupPeriodDays": 7,
  "autoMemoryEnabled": false,
  "respectGitignore": true,
  "feedbackSurveyRate": 0,
  "companyAnnouncements": [
    "Claude Code は社内セキュリティポリシーに従って利用してください。秘密情報、個人情報、認証情報をプロンプトやリポジトリに含めないでください。"
  ],
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_MCP_ALLOWLIST_ENV": "1",
    "CLAUDE_CODE_DISABLE_AUTO_MEMORY": "1",
    "CLAUDE_CODE_DISABLE_BACKGROUND_TASKS": "1",
    "CLAUDE_CODE_DISABLE_CRON": "1",
    "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1",
    "CLAUDE_CODE_CERT_STORE": "system",
    "CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY": "1",
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
      "Bash(az *)",
      "PowerShell(git add *)",
      "PowerShell(git commit *)",
      "PowerShell(docker *)",
      "PowerShell(kubectl *)",
      "PowerShell(terraform *)"
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
      "PowerShell(Invoke-WebRequest *)",
      "PowerShell(Invoke-RestMethod *)",
      "PowerShell(iwr *)",
      "PowerShell(irm *)",
      "PowerShell(curl *)",
      "PowerShell(ssh *)",
      "PowerShell(scp *)",
      "PowerShell(Remove-Item -Recurse *)",
      "PowerShell(Start-Process *)",
      "PowerShell(Set-ExecutionPolicy *)",
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

---

## 5. 設定項目ごとの推奨理由

| 領域 | 推奨設定 | 理由 |
|---|---|---|
| Managed settings | 使用必須 | 管理者が配布し、ユーザー・プロジェクト設定より優先される。|
| `allowManagedPermissionRulesOnly` | `true` | ユーザー・プロジェクトが独自の `allow` / `ask` / `deny` を定義して権限を広げることを防ぐ。|
| `permissions.disableBypassPermissionsMode` | `"disable"` | `--dangerously-skip-permissions` / bypassPermissions の利用を防ぐ。bypassPermissions はすべての権限プロンプトをスキップするため、通常端末では禁止すべき。|
| `permissions.disableAutoMode` | `"disable"` | auto mode は自動承認系の動作になるため、初期展開では禁止または限定展開が望ましい。|
| `sandbox.enabled` | `true` | Bash と子プロセスに OS レベルの filesystem / network 制約をかける。|
| `sandbox.failIfUnavailable` | `true` | sandbox が起動できない端末で、警告だけ出して unsandboxed 実行されることを防ぐ。|
| `sandbox.allowUnsandboxedCommands` | `false` | `dangerouslyDisableSandbox` による sandbox 回避を閉じる。|
| `sandbox.network.allowManagedDomainsOnly` | `true` | ユーザーやプロジェクト側の domain allowlist 追加を無効化する。|
| `allowedMcpServers: []` + `allowManagedMcpServersOnly: true` | 初期は MCP 禁止 | MCP は強力な拡張点であり、審査済みサーバーだけを許可すべき。|
| `disableAllHooks` + `allowManagedHooksOnly` | 初期は hooks 禁止 | hooks はコマンド実行・HTTP 送信経路になり得る。必要な場合だけ managed hooks と URL allowlist で許可する。|
| `strictKnownMarketplaces: []` | 初期は plugin marketplace 禁止 | plugin サプライチェーンを社内審査済み marketplace に限定する準備ができるまで禁止する。|
| `strictPluginOnlyCustomization` | `true` | skills、agents、hooks、MCP をユーザー・プロジェクト由来で読み込ませない。|
| `disableRemoteControl` | `true` | 端末上のローカル filesystem に接続する機能であるため、初期展開では無効化し、必要時だけ管理者設定で解放する。|
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` | 非必須通信を抑える。ただし自動更新も止まるため、MDM / package manager 等で別途更新管理が必要。[^env-vars]|

---

## 6. `${HOME}/.claude/settings.json` として配布する場合の最小例

ユーザー設定は強制力が低いため、セキュリティ制御の主戦場にしない。配布するなら、主に UX と軽い既定値に限定する。

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "language": "japanese",
  "model": "sonnet",
  "autoUpdatesChannel": "stable",
  "cleanupPeriodDays": 7,
  "autoMemoryEnabled": false,
  "respectGitignore": true,
  "permissions": {
    "defaultMode": "default",
    "disableBypassPermissionsMode": "disable",
    "disableAutoMode": "disable",
    "deny": [
      "Read(.env)",
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(secrets/**)",
      "Read(**/*secret*)",
      "Read(**/*credential*)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "WebFetch",
      "WebSearch",
      "Bash(curl *)",
      "Bash(wget *)"
    ]
  },
  "env": {
    "CLAUDE_CODE_DISABLE_AUTO_MEMORY": "1",
    "BASH_DEFAULT_TIMEOUT_MS": "120000",
    "BASH_MAX_OUTPUT_LENGTH": "20000"
  }
}
```

ただし、このファイルはユーザーが書き換えられる。また、プロジェクト設定やローカル設定とマージされるため、企業統制としては managed settings を併用する。

---

## 7. MCP を完全に止める場合

MCP を完全に停止したい場合、`managed-settings.json` 側で以下を入れる。

```json
{
  "allowedMcpServers": [],
  "allowManagedMcpServersOnly": true
}
```

さらに、端末に `managed-mcp.json` を配布して空 server map にする。

```json
{
  "mcpServers": {}
}
```

`managed-mcp.json` が存在する場合、Claude Code はそのファイルで定義されたサーバーだけを読み込む。空の `mcpServers` を配布すると、MCP サーバーは読み込まれず、ユーザーによる `claude mcp add` も企業ポリシーにより拒否される。[^managed-mcp-empty]

配置先は以下である。

| OS | `managed-mcp.json` 配置先 |
|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-mcp.json` |
| Linux / WSL | `/etc/claude-code/managed-mcp.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-mcp.json` |

---

## 8. Claude.ai Team / Enterprise で組織ログインを固定する場合

Claude.ai Team / Enterprise を利用し、個人アカウントや別組織での利用を避けたい場合、managed settings に以下を追加することを検討する。

```json
{
  "forceLoginMethod": "claudeai",
  "forceLoginOrgUUID": "YOUR_ORG_UUID",
  "forceRemoteSettingsRefresh": true
}
```

`forceRemoteSettingsRefresh` は、リモート managed settings を新規取得できるまで CLI 起動をブロックし、取得失敗時に fail-closed するための managed-only 設定である。[^managed-only]

---

## 9. 導入時のチェックリスト

### 9.1 事前設計

- [ ] Claude for Teams / Enterprise、Console API、Bedrock、Vertex AI、Microsoft Foundry のどれを使うか決める。
- [ ] 端末配布方式を決める。候補は server-managed settings、MDM / OS-level policy、file-based managed settings。
- [ ] Windows / WSL の取り扱いを決める。Windows の admin-only managed settings を WSL に継承させたい場合は `wslInheritsWindowsSettings` を検討する。
- [ ] `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` を使う場合、自動更新の代替手段を用意する。

### 9.2 ポリシー設計

- [ ] `permissions.allow` は読み取り・テスト・lint など低リスク操作に限定する。
- [ ] `permissions.ask` に git commit、PR 作成、Docker、Kubernetes、Terraform、cloud CLI などを入れる。
- [ ] `permissions.deny` に credential 読み取り、破壊的コマンド、外部送信、WebFetch / WebSearch を入れる。
- [ ] sandbox の `denyRead` / `denyWrite` に credential、shell profile、system path を入れる。
- [ ] `sandbox.network.allowedDomains` を社内許可ドメインだけに限定する。
- [ ] MCP、hooks、plugin は初期状態では禁止し、必要なものだけ審査後に allowlist 化する。

### 9.3 検証

- [ ] JSON schema による構文確認を行う。[^schema]
- [ ] Claude Code 起動後に `/status` で managed settings の読み込み元を確認する。
- [ ] `/permissions` で権限ルールの適用状況を確認する。
- [ ] `.env`、`~/.ssh`、`~/.aws`、`~/.kube` が読めないことを確認する。
- [ ] `curl` / `wget` / WebFetch / WebSearch がポリシー通りに拒否されることを確認する。
- [ ] `kubectl apply`、`terraform apply`、`git push` がポリシー通りに ask または deny されることを確認する。
- [ ] sandbox 未対応・依存不足端末で `failIfUnavailable` が fail-closed することを確認する。
- [ ] `claude mcp list` と `claude mcp add` で MCP 制限が有効であることを確認する。

---

## 10. レビュー時の論点

| 論点 | 推奨初期判断 | レビュー観点 |
|---|---|---|
| WebFetch / WebSearch | 原則 deny | 社内 proxy / allowlist 経由で必要か。必要なら domain 単位で許可するか。|
| Bash ネットワーク | `curl` / `wget` 等は deny | 開発時の package download を社内 mirror に限定できるか。|
| Git push | 原則 deny または ask | Claude Code から直接 push させる運用を許すか。|
| Kubernetes / Terraform | 原則 ask または deny | dev / staging / prod で分ける必要があるか。|
| Docker | ask | Docker socket 経由でホスト権限へ近づくため、利用シナリオを限定するか。|
| MCP | 初期は禁止 | 社内審査済み MCP サーバーの catalog を作るか。|
| hooks | 初期は禁止 | セキュリティ監査・ログ出力など、managed hooks として必要なものがあるか。|
| plugin | 初期は禁止 | 社内 marketplace を用意するか。|
| Remote Control | 初期は禁止 | Team / Enterprise 管理画面と端末側 managed settings の両方で扱うか。|
| auto mode | 初期は禁止 | 検証済みリポジトリ・隔離環境だけで許可するか。|

---

## 11. 実務上の推奨プロファイル

### 標準開発端末

- Managed settings を必須化。
- sandbox を有効化し、社内 Git / package mirror / artifact repository だけネットワーク許可。
- WebFetch / WebSearch と Bash 外部通信は原則 deny。
- Git commit / PR 作成は ask、Git push は deny または ask。

### セキュア開発端末 / 高機密リポジトリ

- `sandbox.network.allowedDomains` を空または社内ドメインのみにする。
- Docker、kubectl、terraform、cloud CLI は deny。
- MCP、hooks、plugin、Remote Control は完全禁止。
- 必要に応じて dev container / VM などの追加隔離を使う。

### AI champion / 高度利用者

- 標準より広い `ask` を許可する。
- `allow` は広げず、必要なものもまず `ask` から始める。
- MCP / plugin は審査済みのみ許可し、`allowManagedMcpServersOnly` と `strictKnownMarketplaces` は維持する。

---

## 12. 参考資料

[^settings-scope]: Claude Code Docs, “Claude Code の設定”, 設定スコープ・設定ファイル・managed settings 配置先。https://code.claude.com/docs/ja/settings
[^admin-setup]: Claude Code Docs, “Set up Claude Code for your organization”, managed settings の配布方式と優先順位。https://code.claude.com/docs/en/admin-setup
[^admin-enforce]: Claude Code Docs, “Set up Claude Code for your organization”, tools / sandbox / MCP / plugin / hooks の enforcement surface。https://code.claude.com/docs/en/admin-setup
[^settings-precedence]: Claude Code Docs, “Claude Code settings”, settings precedence と array merge。https://code.claude.com/docs/en/settings
[^permissions-sandbox]: Claude Code Docs, “Configure permissions”, permissions と sandbox の関係。https://code.claude.com/docs/en/permissions
[^sandbox-settings]: Claude Code Docs, “Claude Code settings”, sandbox settings。https://code.claude.com/docs/en/settings#sandbox-settings
[^permissions-network]: Claude Code Docs, “Configure permissions”, WebFetch と Bash network tool の制御上の注意。https://code.claude.com/docs/en/permissions
[^managed-mcp]: Claude Code Docs, “Control MCP server access for your organization”。https://code.claude.com/docs/en/managed-mcp
[^managed-mcp-empty]: Claude Code Docs, “Control MCP server access for your organization”, `managed-mcp.json` empty server map による MCP 無効化。https://code.claude.com/docs/en/managed-mcp
[^managed-only]: Claude Code Docs, “Configure permissions”, managed-only settings; “Claude Code settings”, `forceRemoteSettingsRefresh`。https://code.claude.com/docs/en/permissions
[^env-vars]: Claude Code Docs, “Environment variables”。https://code.claude.com/docs/en/env-vars
[^schema]: JSON Schema Store, Claude Code settings schema。https://json.schemastore.org/claude-code-settings.json

