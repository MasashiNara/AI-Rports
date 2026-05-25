はい。**Linux / WSL2 の Claude Code 組み込み Bash sandbox を使う限り、現時点では `socat` を完全に回避する公式な設定は見当たりません。** 公式ドキュメント上、Linux / WSL2 の sandbox は `bubblewrap` と `socat` の 2 つに依存し、`socat` は sandbox proxy へネットワーク通信を中継する relay と説明されています。macOS は Seatbelt を使うため追加インストール不要ですが、Linux / WSL2 では `socat` が依存関係に含まれます。([Claude Code][1])

そのため、企業運用としては次の判断になります。

## 推奨方針

**`socat` を使いたくないなら、Claude Code の組み込み Bash sandbox ではなく、コンテナ・VM・リモート実行環境を sandbox 境界にする**のが一番きれいです。

Claude Code 公式ドキュメントでも、sandbox 方式として「組み込み Bash sandbox」「sandbox runtime」「dev container」「custom container」「VM」「Claude Code on the web」が比較されており、組み込み Bash sandbox は Bash とその子プロセスだけを制限します。一方、dev container / custom container / VM は Claude Code プロセス全体を隔離境界の中に置けます。([Claude Code][2])

---

## 選択肢 1: macOS では組み込み sandbox を使う

macOS 端末なら、Claude Code の Bash sandbox は macOS の Seatbelt を使うため、Linux / WSL2 のように `bubblewrap` / `socat` を入れる必要がありません。公式ドキュメントでも「macOS ではインストール不要、Linux / WSL2 では `bubblewrap` と `socat` が必要」と整理されています。([Claude Code][1])

macOS 向け managed settings はそのまま sandbox を有効化できます。

```json
{
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
        "~/.pypirc"
      ],
      "denyWrite": [
        "~/.aws",
        "~/.ssh",
        "~/.gnupg",
        "~/.kube",
        "~/.docker",
        "/etc",
        "/usr/local/bin",
        "~/.bashrc",
        "~/.zshrc",
        "~/.profile"
      ]
    },
    "network": {
      "allowedDomains": [
        "github.example.com",
        "registry.npmjs.example.com",
        "pypi.example.com"
      ],
      "allowManagedDomainsOnly": true,
      "allowAllUnixSockets": false,
      "allowLocalBinding": false
    }
  },
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "disableAutoMode": "disable"
  }
}
```

この方針は、会社の開発端末が macOS 中心なら最もシンプルです。

---

## 選択肢 2: Linux / WSL2 では組み込み sandbox を無効化し、コンテナまたは VM を標準実行環境にする

Linux / WSL2 で `socat` を避けたい場合は、**Claude Code の組み込み Bash sandbox を使わず、Claude Code 自体を dev container / custom container / VM の中で実行**する構成にします。

公式ドキュメントでも、dev container は Claude Code をコンテナ内で実行し、端末・言語サーバー・ビルドツールもコンテナ内で動く構成として説明されています。また、ネットワーク egress はコンテナ側の firewall や社内ネットワーク制御で制限する想定です。([Claude Code][3])

この場合、managed settings では Claude Code の組み込み sandbox を無効化し、代わりに permission と拡張機能制御を強化します。

```json
{
  "sandbox": {
    "enabled": false
  },
  "permissions": {
    "defaultMode": "default",
    "disableBypassPermissionsMode": "disable",
    "disableAutoMode": "disable",
    "deny": [
      "Bash(socat *)",
      "Bash(nc *)",
      "Bash(ncat *)",
      "Bash(netcat *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(rsync *)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Read(~/.kube/**)",
      "Read(~/.docker/config.json)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./**/.env)",
      "Read(./**/.env.*)"
    ]
  },
  "allowedMcpServers": [],
  "allowManagedMcpServersOnly": true,
  "disableAllHooks": true,
  "allowManagedHooksOnly": true,
  "disableSkillShellExecution": true,
  "disableRemoteControl": true
}
```

この構成では、Claude Code 内蔵の `socat` 依存を使いません。ただし、これは **Claude Code の sandbox 機能を使わない** という意味なので、代わりに外側のコンテナ / VM / VDI / CI runner / Kubernetes などで隔離境界を作る必要があります。

---

## コンテナ標準化の例

dev container の例です。ポイントは、`socat` を入れないこと、ホストの秘密情報を mount しないこと、ネットワーク egress を外側で制御することです。

```json
{
  "name": "company-claude-code-dev",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {}
  },
  "remoteUser": "vscode",
  "mounts": [
    "source=claude-code-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
  ],
  "containerEnv": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_AUTOUPDATER": "1",
    "HTTP_PROXY": "http://proxy.example.com:8080",
    "HTTPS_PROXY": "http://proxy.example.com:8080",
    "NO_PROXY": "localhost,127.0.0.1,.internal.example.com"
  },
  "runArgs": [
    "--cap-drop=ALL",
    "--security-opt=no-new-privileges:true"
  ]
}
```

Dockerfile 側では、managed settings をコンテナ内に配置します。

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates curl nodejs npm \
 && apt-get purge -y socat || true \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code@2.1.150

RUN mkdir -p /etc/claude-code
COPY managed-settings.json /etc/claude-code/managed-settings.json
```

公式ドキュメントでは、Linux の managed settings は `/etc/claude-code/managed-settings.json` に置くと最上位の設定階層として扱われ、ユーザー設定やプロジェクト設定より優先されると説明されています。([Claude Code][3])

---

## 重要: コンテナだけでは egress 制御にならない

`HTTP_PROXY` / `HTTPS_PROXY` を環境変数で渡すだけでは不十分です。悪意あるスクリプトや依存パッケージは、環境変数の proxy を無視して直接外部に接続できます。

したがって、`socat` を使わない sandbox 運用にするなら、ネットワーク制御は次のどれかで強制してください。

| 方式                                           | 推奨度 | コメント                                                                                    |
| -------------------------------------------- | --: | --------------------------------------------------------------------------------------- |
| VM / VDI / remote dev environment の firewall |   高 | 端末側より強制しやすい                                                                             |
| Kubernetes / CNI NetworkPolicy               |   高 | 企業内 platform がある場合に運用しやすい                                                               |
| Docker network + ホスト firewall                |   中 | 開発端末ごとのばらつきに注意                                                                          |
| dev container 内 iptables                     |   中 | 公式 reference container も firewall 例を持つが、`NET_ADMIN` / `NET_RAW` capability が必要になるため設計注意 |
| `HTTP_PROXY` だけ                              |   低 | 回避可能なのでセキュリティ境界にしない                                                                     |

Claude Code の dev container ドキュメントでも、reference container は outbound traffic を allowlist 以外ブロックする firewall script を含む一方、firewall 実行には `NET_ADMIN` / `NET_RAW` capability が必要であり、それ自体は Claude Code 必須条件ではないと説明されています。([Claude Code][3])

---

## 選択肢 3: 組み込み sandbox を使うが、`socat` を「固定・監査」する

どうしても Linux / WSL2 の組み込み Bash sandbox を使う必要がある場合、`socat` を完全に避けるのではなく、**会社管理の `socat` バイナリだけを使わせる**のが現実的な妥協策です。

Claude Code には managed settings 専用で `sandbox.socatPath` があり、Linux / WSL2 の sandbox network proxy に使う `socat` の絶対パスを固定できます。この設定は managed settings からのみ有効で、`PATH` による自動検出を上書きします。([Claude API Docs][4])

```json
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "allowUnsandboxedCommands": false,
    "bwrapPath": "/opt/company/claude-code/bin/bwrap",
    "socatPath": "/opt/company/claude-code/bin/socat",
    "filesystem": {
      "denyRead": [
        "~/.aws",
        "~/.ssh",
        "~/.gnupg",
        "~/.kube",
        "~/.docker"
      ]
    },
    "network": {
      "allowedDomains": [
        "github.example.com",
        "registry.npmjs.example.com",
        "pypi.example.com"
      ],
      "allowManagedDomainsOnly": true,
      "allowAllUnixSockets": false
    }
  },
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "disableAutoMode": "disable",
    "deny": [
      "Bash(socat *)",
      "Bash(nc *)",
      "Bash(ncat *)",
      "Bash(netcat *)",
      "Bash(curl *)",
      "Bash(wget *)"
    ]
  }
}
```

この場合の補強策は次のとおりです。

1. `/usr/bin/socat` ではなく、会社が配布・検証した `/opt/company/claude-code/bin/socat` を使う。
2. `socat` パッケージのバージョンと hash をソフトウェア配布基盤で固定する。
3. バイナリは `root:root` 所有、一般ユーザー書き込み不可にする。
4. EDR / AppArmor / SELinux / auditd で `socat` の直接実行を監視する。
5. Claude Code の Bash tool から `socat` を直接実行することは permission deny で防ぐ。
6. `sandbox.network.allowedDomains` を最小化し、`allowManagedDomainsOnly: true` でユーザーやプロジェクトからの domain 追加を防ぐ。

ただし、これは **`socat` を使わない解決策ではありません**。PATH hijack や未知の `socat` バイナリ利用を避けるための統制策です。

---

## `httpProxyPort` / `socksProxyPort` だけでは回避策として弱い

Claude Code には `sandbox.network.httpProxyPort` と `sandbox.network.socksProxyPort` があり、独自 proxy を使う設定があります。公式ドキュメントでは、指定しない場合は Claude が proxy を起動し、指定した場合は独自 proxy を使う設定として説明されています。([Claude API Docs][4])

ただし、同じ設定表で `socatPath` は「sandbox network proxy に使われる `socat` バイナリ」と説明されているため、**独自 proxy を指定しても `socat` 依存が完全に消えるとは公式には読めません**。([Claude API Docs][4])

そのため、`socat` 禁止ポリシーがある場合に `httpProxyPort` / `socksProxyPort` で回避できると考えるのは危険です。導入判断としては、実機で `ps`, `auditd`, `execve` tracing などを使って確認する必要があります。

---

## 私ならこう設計します

### macOS 端末

Claude Code 組み込み Bash sandbox を使う。

```json
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "allowUnsandboxedCommands": false
  }
}
```

macOS では Linux / WSL2 の `socat` 依存を避けられます。([Claude Code][1])

### Linux / WSL2 端末

`/etc/claude-code/managed-settings.json` で Claude Code 組み込み sandbox を無効化し、**会社標準の dev container / VM / remote development environment からのみ Claude Code を使わせる**。

```json
{
  "sandbox": {
    "enabled": false
  },
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "disableAutoMode": "disable"
  },
  "allowedMcpServers": [],
  "allowManagedMcpServersOnly": true,
  "disableAllHooks": true,
  "disableRemoteControl": true
}
```

そのうえで、端末管理・EDR・MDM・software allowlisting で、ホスト OS 直下の `claude` 実行を禁止または検知します。公式ドキュメントでも、dev container は標準化には使える一方、Claude Code 自体はコンテナ外実行を強制しないため、組織として強制するには device management や software allowlisting が必要とされています。([Claude Code][2])

### 高リスク / 未信頼 repository

VM または remote execution environment に寄せる。公式ドキュメントでも、未信頼 repository では dedicated VM や Claude Code on the web が候補として示されています。([Claude Code][2])

---

## 結論

`Linux / WSL2 + Claude Code 組み込み Bash sandbox + socat 不使用` という組み合わせは、現時点の公式仕様を見る限り難しいです。

現実的な推奨は次です。

| 要件                            | 推奨                                                               |
| ----------------------------- | ---------------------------------------------------------------- |
| `socat` を完全に使いたくない            | dev container / custom container / VM を sandbox 境界にする            |
| macOS 中心の会社                   | 組み込み Bash sandbox を使う                                            |
| Linux / WSL2 で組み込み sandbox 必須 | 会社管理の `socatPath` に固定し、監査・hash 固定・Bash deny・egress allowlist で補強 |
| 未信頼コードを扱う                     | VM / remote development environment を使う                          |

企業標準としては、**「macOS は組み込み sandbox、Linux / WSL2 はコンテナまたは VM」**という OS 別プロファイルにするのが一番バランスが良いです。

[1]: https://code.claude.com/docs/en/sandboxing "Configure the sandboxed Bash tool - Claude Code Docs"
[2]: https://code.claude.com/docs/en/sandbox-environments "Choose a sandbox environment - Claude Code Docs"
[3]: https://code.claude.com/docs/en/devcontainer "Development containers - Claude Code Docs"
[4]: https://docs.anthropic.com/en/docs/claude-code/settings "Claude Code settings - Claude Code Docs"
