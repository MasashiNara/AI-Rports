#!/usr/bin/env bash
#
# create_sudo_user.bash
# 新規ユーザー "${USERNAME}" を作成し、ホームディレクトリ作成と sudo 権限付与まで行うスクリプト
#
# 対応ディストリビューション:
#   - Debian / Ubuntu 系 (sudo グループ)
#   - RHEL / CentOS / Rocky / AlmaLinux 系 (wheel グループ)
#
# 使い方:
#   sudo ./create_sudo_user.bash
#

set -euo pipefail

USERNAME=""
if [[ "${USERNAME}"x == x ]]; then
    echo "スクリプト内で定義している、USERNAMEに値を設定してください。" >&2
    exit 1
fi

HOME_DIR="/home/${USERNAME}"
LOGIN_SHELL="/bin/bash"

# ---- 1. root 権限の確認 ----------------------------------------------------
if [[ "${EUID}" -ne 0 ]]; then
    echo "エラー: このスクリプトは root 権限で実行してください (sudo ./create_sudo_user.bash)" >&2
    exit 1
fi

# ---- 2. sudo グループ名の判定 ----------------------------------------------
# Debian/Ubuntu 系は "sudo"、RHEL 系は "wheel"
if getent group sudo >/dev/null 2>&1; then
    SUDO_GROUP="sudo"
elif getent group wheel >/dev/null 2>&1; then
    SUDO_GROUP="wheel"
else
    echo "エラー: sudo グループ (sudo / wheel) が見つかりません。" >&2
    exit 1
fi

# ---- 3. ユーザーの存在確認 --------------------------------------------------
if id "${USERNAME}" >/dev/null 2>&1; then
    echo "警告: ユーザー '${USERNAME}' は既に存在します。作成処理をスキップします。"
else
    # ---- 4. ユーザー作成 (ホームディレクトリ込み) --------------------------
    # -m : ホームディレクトリを作成
    # -d : ホームディレクトリのパスを指定
    # -s : ログインシェルを指定
    useradd -m -d "${HOME_DIR}" -s "${LOGIN_SHELL}" "${USERNAME}"
    echo "ユーザー '${USERNAME}' を作成しました (home: ${HOME_DIR})。"

    # ---- 5. パスワード設定 -------------------------------------------------
    echo "ユーザー '${USERNAME}' のパスワードを設定してください:"
    passwd "${USERNAME}"
fi

# ---- 6. sudo グループへの登録 ----------------------------------------------
# -a -G : 既存のグループを保持したまま追加グループに追加
usermod -aG "${SUDO_GROUP}" "${USERNAME}"
echo "ユーザー '${USERNAME}' を '${SUDO_GROUP}' グループに追加しました。"

# ---- 7. 結果確認 -----------------------------------------------------------
echo ""
echo "===== 設定結果 ====="
id "${USERNAME}"
echo "ホームディレクトリ: $(getent passwd "${USERNAME}" | cut -d: -f6)"
echo "===================="
echo "完了しました。'su - ${USERNAME}' でログインして 'sudo -v' で権限を確認できます。"
