**Dockerfile 単体ではなく、Dockerfile + docker-compose.yml + entrypoint firewall script** の構成にしました。`iptables` はコンテナ起動後の network namespace に対して設定する必要があるため、runtime capability を指定できる `docker-compose.yml` もセットにしています。

## 作成した構成の要点

`Dockerfile` は Ubuntu 24.04 ベースで、Claude Code は Anthropic の署名付き apt repository から入れるようにしています。公式ドキュメントでは Ubuntu / Debian 向けに `downloads.claude.ai` の apt repository と GPG fingerprint 検証手順が示されているため、それに沿っています。([Claude Code][1])

`docker-compose.yml` 側で `NET_ADMIN` / `NET_RAW` を付け、entrypoint が root で `iptables` / `ipset` を設定したあと、`gosu` で非 root ユーザー `claude` に降格します。Claude Code 公式の devcontainer ドキュメントでも、コンテナ内 firewall には `NET_ADMIN` / `NET_RAW` が必要で、これらは Claude Code 自体の必須権限ではないと説明されています。([Claude Code][2])

Claude Code の組み込み Bash sandbox は `managed-settings.json` で **無効化**しています。これは Linux / WSL2 の組み込み sandbox で `socat` を使わせないためです。代わりに、Docker コンテナ境界と `iptables` egress 制御を sandbox 境界にしています。

`/etc/claude-code/managed-settings.json` に managed settings を配置しています。Linux / WSL では `/etc/claude-code/` が file-based managed settings の配置先で、managed settings はユーザー設定やプロジェクト設定より優先され、上書きできない設定層として扱われます。([Claude Code][3])

## egress 制御の動作

`config/egress-allow-domains.txt` に 1 行 1 FQDN で許可先を書きます。

コンテナ起動時に `scripts/init-firewall.sh` が以下を実行します。

1. allowlist の FQDN を起動時に名前解決する。
2. 解決された IPv4 を `ipset` に登録する。
3. `FIREWALL_BLOCK_DNS_AFTER_INIT=1` の場合、解決結果を `/etc/hosts` に追記する。
4. `iptables` の default policy を `DROP` にする。
5. allowlist IP 宛ての TCP 443 のみ許可する。
6. IPv6 はデフォルトで遮断する。
7. `example.com:443` が到達不能であることを起動時に検証する。

Claude Code の公式 network requirements では、Anthropic API 利用時に `api.anthropic.com`、Claude.ai 認証に `claude.ai`、Console 認証に `platform.claude.com`、installer / updater / plugin downloads に `downloads.claude.ai` などが挙げられています。今回の allowlist はその情報を初期値にしつつ、社内 GitHub Enterprise、npm mirror、PyPI mirror、proxy に差し替えられるようにしています。([Claude Code][4])

## 基本的な使い方

```bash
unzip claude-code-docker-iptables.zip
cd claude-code-docker-iptables

# 必要に応じて allowlist を編集
vi config/egress-allow-domains.txt

# build
docker compose build --pull

# プロジェクトの root を /workspace に mount して起動
HOST_UID=$(id -u) HOST_GID=$(id -g) WORKSPACE=$PWD docker compose run --rm claude-code
```

コンテナ内で:

```bash
check-firewall
claude
```

`check-firewall` では、`socat` が存在しないこと、`example.com:443` がブロックされること、allowlist の先頭ドメインが到達可能かを確認します。

## 重要な注意点

この構成は **Claude Code とその子プロセスの事故・過剰動作をコンテナ内に閉じ込める** ためのものです。Linux で Docker socket を自由に使えるユーザーは、実質的にホスト root 相当の操作ができるため、悪意あるローカルユーザーに対する完全な強制境界にはなりません。

運用管理部署が仮想マシンを配布する方式なら、コンテナ内 firewall に加えて、ホスト側の `DOCKER-USER` chain、VM firewall、社内 proxy、DNS logging、EDR でも制御するのがより堅牢です。Docker の公式ドキュメントでも、Docker 管理ルールより前に独自ルールを適用したい場合は `DOCKER-USER` chain を使うことが説明されています。([Docker Japanese Docs][5])

## 検証状況

こちらでは、ファイル生成後に以下の静的検証を行いました。

```bash
bash -n scripts/init-firewall.sh
bash -n scripts/entrypoint.sh
bash -n scripts/check-firewall.sh
jq . config/managed-settings.json
docker-compose.yml の YAML parse
```

この実行環境では Docker build と Claude Code への実ログインまでは実行していないため、社内 proxy、DNS、GitHub Enterprise、認証方式に合わせて、まず検証用 VM で `docker compose build` と `check-firewall` を試してください。

[1]: https://code.claude.com/docs/ja/setup "高度なセットアップ - Claude Code Docs"
[2]: https://code.claude.com/docs/en/devcontainer "Development containers - Claude Code Docs"
[3]: https://code.claude.com/docs/en/settings "Claude Code settings - Claude Code Docs"
[4]: https://code.claude.com/docs/en/network-config "Enterprise network configuration - Claude Code Docs"
[5]: https://docs.docker.jp/network/iptables.html "Docker と iptables — Docker-docs-ja 24.0 ドキュメント"
