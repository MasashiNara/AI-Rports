#!/usr/bin/env bash
#
# setup_nopasswd_sudo_user.bash
# ユーザー "${USERNAME}" が sudo 実行時にパスワードを求められないように設定するスクリプト
#
# 安全のため /etc/sudoers は直接編集せず、/etc/sudoers.d/ にドロップインファイルを
# 配置する。書き込み前に visudo -c で構文を検証し、不正な内容を反映しない。
#
# 実行ユーザー: root
#
# 使い方:
#   ./setup_nopasswd_sudo_user.bash
#

set -euo pipefail

USERNAME=""
if [[ "${USERNAME}"x == x ]]; then
    echo "スクリプト内で定義している、USERNAMEに値を設定してください。" >&2
    exit 1
fi

SUDOERS_FILE="/etc/sudoers.d/${USERNAME}"

# ---- 1. root 権限の確認 ----------------------------------------------------
if [[ "${EUID}" -ne 0 ]]; then
    echo "エラー: このスクリプトは root で実行してください。" >&2
    exit 1
fi

# ---- 2. ユーザーの存在確認 --------------------------------------------------
if ! id "${USERNAME}" >/dev/null 2>&1; then
    echo "エラー: ユーザー '${USERNAME}' が存在しません。先にユーザーを作成してください。" >&2
    exit 1
fi

# ---- 3. ドロップインファイルを一時ファイルに作成 ----------------------------
# 一旦テンポラリに書き出して visudo で検証し、問題なければ本番へ移動する
TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

cat > "${TMP_FILE}" <<EOF
# ${USERNAME} がパスワードなしで sudo を実行できるようにする設定
# このファイルは setup_nopasswd_sudo_user.sh により生成されました
${USERNAME} ALL=(ALL) NOPASSWD:ALL
EOF

# ---- 4. 構文チェック -------------------------------------------------------
# visudo -cf で対象ファイルの構文のみを検証する
if ! visudo -cf "${TMP_FILE}" >/dev/null 2>&1; then
    echo "エラー: sudoers 設定の構文チェックに失敗しました。設定を反映しません。" >&2
    exit 1
fi

# ---- 5. 本番ファイルへ配置 -------------------------------------------------
# sudoers.d 配下のファイルは 0440 / root:root が必須
install -m 0440 -o root -g root "${TMP_FILE}" "${SUDOERS_FILE}"
echo "設定ファイルを配置しました: ${SUDOERS_FILE}"

# ---- 6. 反映後の最終検証 ---------------------------------------------------
# /etc/sudoers 全体 (include 含む) の整合性を確認
if ! visudo -c >/dev/null 2>&1; then
    echo "エラー: 反映後の sudoers 全体検証に失敗しました。配置したファイルを削除します。" >&2
    rm -f "${SUDOERS_FILE}"
    exit 1
fi

# ---- 7. 結果確認 -----------------------------------------------------------
echo ""
echo "===== 設定結果 ====="
echo "--- ${SUDOERS_FILE} の内容 ---"
cat "${SUDOERS_FILE}"
echo "--- パーミッション ---"
ls -l "${SUDOERS_FILE}"
echo "--- sudo -l (${USERNAME}) ---"
sudo -lU "${USERNAME}" || true
echo "===================="
echo "完了しました。'su - ${USERNAME}' でログイン後、'sudo whoami' でパスワードなしで実行できることを確認してください。"
