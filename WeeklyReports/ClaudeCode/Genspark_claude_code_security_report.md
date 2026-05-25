# Claude Code 企業展開セキュリティ調査レポート

作成日: 2026-05-25

## 1. エグゼクティブサマリー

Claude Code を会社で安全に展開するうえで、`${HOME}/.claude/settings.json` の統一は有用ですが、それだけでは十分ではありません。Claude Code の設定優先順位では **Managed > CLI 引数 > Local > Project > User** の順で評価されるため、`~/.claude/settings.json` は最下位に近い「個人設定」です。したがって、組織として強制したいセキュリティ設定は **managed settings** で配布し、`~/.claude/settings.json` は補助的な既定値に留めるのが推奨です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings)

Anthropic の公式サンプルでは、`settings-strict.json` と `settings-bash-sandbox.json` が組織配布向けの出発点として示されています。前者は bypass 権限の禁止、WebSearch/WebFetch の無効化、managed のみで permission rules / hooks を許可する構成で、後者は Bash を sandbox 内に閉じ込め、sandbox 外への退避実行も禁止する構成です。 [Anthropic GitHub Examples](https://github.com/anthropics/claude-code/tree/main/examples/settings) [strict example](https://raw.githubusercontent.com/anthropics/claude-code/main/examples/settings/settings-strict.json) [bash sandbox example](https://raw.githubusercontent.com/anthropics/claude-code/main/examples/settings/settings-bash-sandbox.json)

## 2. 結論

会社標準として本当に推奨されるのは、**`${HOME}/.claude/settings.json` を統一すること自体ではなく、managed settings を中核に据えること**です。特に権限、Hooks、MCP、sandbox、ネットワーク制御、資格情報保護は user settings ではなく managed settings で統制するべきです。`~/.claude/settings.json` は、`$schema`、`cleanupPeriodDays`、軽い既定値のような「個人既定値」に留めるのが安全です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings)

## 3. Claude Code の設定階層と意味

Claude Code の設定は、Managed、User、Project、Local の各スコープで管理され、同一キーが複数箇所にある場合は Managed が最優先されます。Managed 設定は、Claude.ai 管理コンソールの server-managed settings、MDM/OS ポリシー、または system ディレクトリ上の `managed-settings.json` として配布できます。ファイルベースの managed settings の配置場所は、macOS では `/Library/Application Support/ClaudeCode/`、Linux/WSL では `/etc/claude-code/`、Windows では `C:\Program Files\ClaudeCode\` です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings)

server-managed settings は MDM がない環境でも使いやすい一方で、初回起動時に設定取得に失敗すると、一時的に managed settings なしで起動しうる点に注意が必要です。この brief window を避けたい場合は `forceRemoteSettingsRefresh: true` を使い、取得に失敗したら起動させない fail-closed 運用が推奨されます。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/server-managed-settings)

## 4. `${HOME}/.claude/settings.json` に入れるべきもの／入れるべきでないもの

`~/.claude/settings.json` に入れるべきなのは、主に個人既定値です。たとえば JSON schema、セッション履歴の保持期間短縮、軽微な UI や既定モード設定は候補になります。一方で、permission rules、Hooks、MCP allowlist、sandbox 強制などは project/local/CLI で影響を受けるため、user settings に置いても組織ポリシーとしては弱いです。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings)

### 推奨される user settings の最小例

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "cleanupPeriodDays": 7,
  "permissions": {
    "defaultMode": "default"
  }
}
```

この程度に留めることで、個人設定と組織ポリシーの責任分界が明確になります。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings)

## 5. 組織配布で推奨される managed settings の方向性

Anthropic 公式サンプル `settings-strict.json` では、`disableBypassPermissionsMode` による bypass 禁止、`ask: ["Bash"]` による Bash 実行時確認、`deny: ["WebSearch", "WebFetch"]` による外部検索・取得の停止、`allowManagedPermissionRulesOnly: true` による managed 以外の権限ルール禁止、`allowManagedHooksOnly: true` による managed 以外の Hooks 禁止が採用されています。これは企業の堅めの初期ベースラインとして妥当です。 [strict example](https://raw.githubusercontent.com/anthropics/claude-code/main/examples/settings/settings-strict.json)

同じく公式の `settings-bash-sandbox.json` は、`sandbox.enabled: true`、`autoAllowBashIfSandboxed: false`、`allowUnsandboxedCommands: false` を基本とし、Bash を sandbox 内で実行させつつ、sandbox 失敗時の外部再実行も禁止します。CLI 活用を許容しつつ OS レベルの境界も欲しい組織に向いています。 [bash sandbox example](https://raw.githubusercontent.com/anthropics/claude-code/main/examples/settings/settings-bash-sandbox.json)

### ベースラインとして推奨できる項目

- `permissions.disableBypassPermissionsMode: "disable"`
- 必要に応じて `disableAutoMode: "disable"`
- `allowManagedPermissionRulesOnly: true`
- `allowManagedHooksOnly: true`
- `allowedMcpServers` と `allowManagedMcpServersOnly: true`
- `sandbox.enabled: true`
- `sandbox.failIfUnavailable: true`
- `sandbox.allowUnsandboxedCommands: false`
- `sandbox.network.allowedDomains` の最小化
- `allowManagedDomainsOnly: true` の検討
- `sandbox.filesystem.denyRead` に `~/.aws`, `~/.ssh`, `~/.gnupg` などを追加
- 必要なければ `disableRemoteControl: true`
- 必要に応じて `disableSkillShellExecution: true`
- `cleanupPeriodDays` の短縮

これらは permissions・sandbox・MCP・Hooks・ネットワークの複数層でリスクを下げるための構成です。Anthropic も permissions と sandboxing の併用を defense-in-depth として推奨しています。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/permissions) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/sandboxing)

## 6. とくに重要なセキュリティ論点

### 6.1 bypass モードと auto モード

`bypassPermissions` はほぼ全プロンプト確認を飛ばす強力なモードであり、企業環境では managed settings で無効化するのが妥当です。`auto` モードも存在しますが research preview と位置付けられているため、まずは固定的な permission rules と sandbox による統制を優先するのが無難です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/permissions)

### 6.2 Hooks

Hooks は PreToolUse などで危険な操作をブロックできる一方、任意の shell 実行ポイントでもあります。企業運用では `allowManagedHooksOnly: true` を基本とし、必要な Hooks だけを管理側で配布する方が安全です。設定変更の監視・抑止には `ConfigChange` hook も利用できます。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/hooks) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/security)

### 6.3 MCP

MCP は外部システム接続の拡張点なので、allowlist 管理が重要です。公式 docs では `allowedMcpServers` と `allowManagedMcpServersOnly: true` を組み合わせて、管理者が認めたサーバーのみ有効化する方式が推奨されています。denylist も併用できます。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/managed-mcp)

### 6.4 Bash sandbox

Claude Code の sandbox は macOS では Seatbelt、Linux/WSL2 では bubblewrap を使い、Bash とその子プロセスに対して OS レベルの filesystem/network 制約をかけます。組織運用では `sandbox.enabled: true`、`failIfUnavailable: true`、`allowUnsandboxedCommands: false` の組み合わせが強く推奨されます。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/sandboxing)

### 6.5 資格情報ファイルの保護

重要な注意点として、sandbox のデフォルト read は広く、`~/.aws/credentials` や `~/.ssh/` のような資格情報ファイルも明示 deny しない限り読めます。したがって、sandbox を有効にするだけでは不十分で、`sandbox.filesystem.denyRead` で明示的に資格情報ディレクトリを塞ぐ必要があります。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/sandboxing)

## 7. 設定ファイル以外に、会社で追加すべきセキュリティ対策

### 7.1 Enterprise / Team / API 系を使う

会社利用では Free/Pro/Max の consumer 前提ではなく、Team / Enterprise / API / Bedrock / Vertex / Foundry など商用条件下での利用を優先するべきです。商用条件では、Anthropic は Claude Code に送られたコードやプロンプトを生成モデル学習に使わない方針です。Enterprise では Zero Data Retention も利用可能です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/data-usage)

### 7.2 SSO / domain capture / role-based permissions

Claude for Enterprise では SSO、domain capture、role-based permissions、Compliance API、managed policy settings が提供されます。会社展開では、個別 API key の野放図な配布より、IdP 連携と集中管理を優先する方が offboarding や監査の面で優れます。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/iam) [Anthropic Enterprise](https://www.anthropic.com/product/enterprise)

### 7.3 プロキシ、CA、mTLS

Claude Code は `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY`、`NODE_EXTRA_CA_CERTS`、`CLAUDE_CODE_CLIENT_CERT` / `CLAUDE_CODE_CLIENT_KEY` などをサポートしており、企業プロキシや社内 CA、mTLS に対応できます。ネットワーク制御が必要な組織では、出口を corporate proxy に統一し、必要ドメインのみ allowlist 化することが推奨されます。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/corporate-proxy)

### 7.4 subprocess への認証情報引き渡しを防ぐ

`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` を設定すると、Anthropic やクラウドプロバイダの資格情報が Bash、Hooks、MCP stdio サーバーなどの子プロセスに渡らなくなります。prompt injection や危険な subprocess 実行を考慮すると、企業運用で非常に重要な設定です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/env-vars)

### 7.5 履歴・痕跡の削減

ローカル保存リスクを下げるには、`cleanupPeriodDays` を短くするだけでなく、必要に応じて `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` を使い、セッション履歴や transcript をディスクに書かせない運用も有効です。高機密リポジトリや CI、短命環境では有力な選択肢です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/env-vars) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/data-usage)

### 7.6 非本質的な外部通信の停止

`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` を使うと、telemetry、error reporting、feedback、auto updater などの非本質的通信をまとめて停止できます。自社方針上、まずは最小通信にしたい場合の初期設定として有効です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/env-vars) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/data-usage)

### 7.7 アップデート統制

自社配布バイナリを使う組織では、`DISABLE_UPDATES=1` により勝手な更新を止め、検証済みバージョンだけを展開する運用が可能です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/env-vars)

### 7.8 監査ログ / OpenTelemetry

Claude Code には OpenTelemetry ベースの監視機構があり、tool decision、permission mode 変更、hook block、認証イベント、MCP 接続、plugin install、コマンド実行やファイル操作などを収集できます。企業展開では「何を禁止するか」だけでなく「何が起きたか」を見る体制も重要です。ただし詳細ログは機微情報を含みうるため、初期はメタデータ中心で始め、必要に応じて段階的に詳細化するのが安全です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/monitoring-usage)

## 8. 導入パターン別の推奨

### 標準業務端末向け

標準的な開発端末では、managed settings による bypass 禁止、managed-only の permission rules / hooks、MCP allowlist、sandbox 有効化、資格情報ディレクトリ denyRead、proxy 経由の通信、SSO、短めのローカル履歴保持を基本セットとするのが現実的です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/permissions) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/sandboxing)

### 高機密リポジトリ向け

高機密用途では、`WebSearch` / `WebFetch` の deny、必要最小限の `allowedDomains`、`defaultMode` を `dontAsk` または `plan` 寄りにする検討、`CLAUDE_CODE_SKIP_PROMPT_HISTORY=1`、Enterprise の ZDR、監査強化を組み合わせるのが妥当です。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/permissions) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/data-usage)

## 9. 推奨実装方針

### 9.1 まず採用すべき運用原則

1. `~/.claude/settings.json` は薄くする
2. 強制ポリシーは managed settings で配る
3. Bash は sandbox 前提にする
4. MCP と Hooks は allowlist 管理する
5. 認証情報ファイルと subprocess 環境を保護する
6. 監査・可視化まで含めて設計する

### 9.2 推奨度の高い managed settings サンプル

以下は、公式ドキュメント・公式サンプルの内容を踏まえた、企業向けの「叩き台」です。

```json
{
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "deny": [
      "WebSearch",
      "WebFetch"
    ]
  },
  "allowManagedPermissionRulesOnly": true,
  "allowManagedHooksOnly": true,
  "allowManagedMcpServersOnly": true,
  "allowedMcpServers": [
    { "serverName": "github" }
  ],
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "allowUnsandboxedCommands": false,
    "filesystem": {
      "denyRead": [
        "~/.aws",
        "~/.ssh",
        "~/.gnupg"
      ]
    },
    "network": {
      "allowedDomains": []
    }
  },
  "cleanupPeriodDays": 7,
  "disableRemoteControl": true,
  "disableSkillShellExecution": true
}
```

実際には、利用部門、必要な MCP、外部通信先、CI の有無、クラウド基盤の方式に応じて調整が必要です。ただし思想としては、公式の `strict` と `bash-sandbox` を合わせて、MCP と資格情報保護を加えた形が組織運用の有力な出発点になります。 [strict example](https://raw.githubusercontent.com/anthropics/claude-code/main/examples/settings/settings-strict.json) [bash sandbox example](https://raw.githubusercontent.com/anthropics/claude-code/main/examples/settings/settings-bash-sandbox.json) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/managed-mcp)

## 10. 補足: MDM / エンタープライズ配布テンプレート

Anthropic 公式リポジトリには、Jamf / Kandji / Intune / Group Policy 向けの配布テンプレートが含まれています。macOS では `com.anthropic.claudecode` の managed preferences / mobileconfig、Windows では Group Policy 用 ADMX や PowerShell スクリプト、任意プラットフォーム向けの `managed-settings.json` サンプルが用意されています。 [Anthropic GitHub MDM Examples](https://github.com/anthropics/claude-code/tree/main/examples/mdm) [managed-settings example](https://raw.githubusercontent.com/anthropics/claude-code/main/examples/mdm/managed-settings.json)

## 11. 最終結論

上司レビュー向けに一言でまとめると、**Claude Code を会社で展開する際は、`${HOME}/.claude/settings.json` の統一は補助策としては有効だが、セキュリティの本命は managed settings による強制配布である**、というのが結論です。さらに、sandbox、MCP allowlist、Hooks 制御、SSO、プロキシ/CA、subprocess 環境スクラブ、履歴削減、監査ログまで含めて設計して初めて、企業利用に耐える安全性に近づきます。 [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings) [Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/security) [Anthropic Enterprise](https://www.anthropic.com/product/enterprise)

## 参考文献

- Claude Code settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Claude Code permissions: https://docs.anthropic.com/en/docs/claude-code/permissions
- Claude Code security: https://docs.anthropic.com/en/docs/claude-code/security
- Claude Code sandboxing: https://docs.anthropic.com/en/docs/claude-code/sandboxing
- Claude Code server-managed settings: https://docs.anthropic.com/en/docs/claude-code/server-managed-settings
- Claude Code managed MCP: https://docs.anthropic.com/en/docs/claude-code/managed-mcp
- Claude Code env vars: https://docs.anthropic.com/en/docs/claude-code/env-vars
- Claude Code IAM: https://docs.anthropic.com/en/docs/claude-code/iam
- Claude Code corporate proxy: https://docs.anthropic.com/en/docs/claude-code/corporate-proxy
- Claude Code monitoring usage: https://docs.anthropic.com/en/docs/claude-code/monitoring-usage
- Claude Code data usage: https://docs.anthropic.com/en/docs/claude-code/data-usage
- Claude Code enterprise deployment overview: https://docs.anthropic.com/en/docs/claude-code/third-party-integrations
- Anthropic Enterprise product page: https://www.anthropic.com/product/enterprise
- Anthropic announcement on Claude Code for Team / Enterprise: https://www.anthropic.com/news/claude-code-on-team-and-enterprise
- Official GitHub examples/settings: https://github.com/anthropics/claude-code/tree/main/examples/settings
- Official GitHub examples/mdm: https://github.com/anthropics/claude-code/tree/main/examples/mdm
