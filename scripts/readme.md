# Linux sudo ユーザー作成スクリプト

Linux 上で sudo 権限を持つ新規ユーザーを作成し、必要に応じてパスワードなし（NOPASSWD）で sudo を実行できるように設定するための Bash スクリプト集です。Debian/Ubuntu 系と RHEL 系の両方に対応しています。

## 動作環境

- Bash
- root 権限で実行できる環境
- 対応ディストリビューション
  - Debian / Ubuntu 系（`sudo` グループ）
  - RHEL / CentOS / Rocky / AlmaLinux 系（`wheel` グループ）

`sudo` グループと `wheel` グループのどちらが存在するかを自動判定するため、ディストリビューションごとにスクリプトを書き換える必要はありません。

## 含まれるスクリプト

| スクリプト | 役割 |
| --- | --- |
| `create_sudo_user.bash` | 新規ユーザーをホームディレクトリ込みで作成し、sudo グループへ登録する |
| `setup_nopasswd_sudo_user.bash` | 既存ユーザーが sudo 実行時にパスワードを求められないように設定する |

`setup_nopasswd_sudo_user.bash` は対象ユーザーが既に存在していることを前提とするため、通常は `create_sudo_user.bash` を先に実行します。

## 事前準備：ユーザー名の設定

どちらのスクリプトも、ファイル冒頭の `USERNAME` 変数に対象ユーザー名を設定してから実行します。空のまま実行するとエラーメッセージを表示して終了します。

```bash
# スクリプト冒頭のこの行を編集する
USERNAME=""        # 例: USERNAME="nara"
```

両方のスクリプトで **同じユーザー名** を設定してください。

## 使い方

### 1. 新規ユーザーの作成（`create_sudo_user.bash`）

新規ユーザーを作成し、ホームディレクトリの作成から sudo グループへの登録までを行います。

```bash
# USERNAME を設定後
chmod +x create_sudo_user.bash
sudo ./create_sudo_user.bash
```

実行内容は次のとおりです。

1. root 権限で実行されているか確認する
2. `sudo` / `wheel` のどちらのグループが存在するか判定する
3. 対象ユーザーが既に存在する場合は作成をスキップする
4. `useradd -m -d /home/<USERNAME> -s /bin/bash` でホームディレクトリ込みでユーザーを作成する
5. `passwd` でパスワードを対話的に設定する
6. `usermod -aG` で sudo グループへ追加する
7. `id` などで設定結果を表示する

実行後は次のコマンドで権限を確認できます。

```bash
su - <USERNAME>
sudo -v
```

### 2. パスワードなし sudo の設定（`setup_nopasswd_sudo_user.bash`）

対象ユーザーが sudo 実行時にパスワードを求められないように設定します。**実行ユーザーは root** です。

```bash
# USERNAME を設定後
chmod +x setup_nopasswd_sudo_user.bash
./setup_nopasswd_sudo_user.bash
```

実行内容は次のとおりです。

1. root 権限で実行されているか確認する
2. 対象ユーザーが存在するか確認する
3. 設定内容を一時ファイルに書き出し、`visudo -cf` で構文を検証する
4. 検証に成功した場合のみ `/etc/sudoers.d/<USERNAME>` へ配置する（パーミッション `0440`、所有者 `root:root`）
5. 配置後に `visudo -c` で sudoers 全体の整合性を再検証する
6. 異常があれば配置したファイルを自動削除してロールバックする
7. 設定内容とパーミッション、`sudo -lU` の結果を表示する

実行後は次のコマンドでパスワードなしで sudo が使えることを確認できます。

```bash
su - <USERNAME>
sudo whoami    # パスワードを求められず root と表示されれば成功
```

## 安全設計について

`setup_nopasswd_sudo_user.bash` は `/etc/sudoers` を直接編集しません。`/etc/sudoers.d/` にドロップインファイルを配置する方式を採り、書き込み前後に `visudo` で構文を検証します。これにより、設定ミスで sudo 自体が壊れて権限昇格できなくなる事態を防ぎます。

## 注意事項

- `setup_nopasswd_sudo_user.bash` は対象ユーザーがパスワードなしですべてのコマンドを root 実行できる状態（`NOPASSWD:ALL`）にします。利便性が高い一方、認証情報が漏れた場合の影響範囲も大きくなります。
- 特定のコマンドのみパスワードなしにしたい場合は、スクリプト内の `NOPASSWD:ALL` の部分を対象コマンドのフルパスに置き換えてください。

  ```
  <USERNAME> ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/bin/apt
  ```

- 本番環境やセキュリティ要件の高い環境では、パスワードなし sudo の利用範囲を必要最小限にとどめることを推奨します。
