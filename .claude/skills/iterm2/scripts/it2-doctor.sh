#!/usr/bin/env bash
# it2-doctor: iTerm2 cmux互換スキルの前提を決定的に診断する。
# 各チェックを OK/NG で出力し、NG には具体的な修復手順を添える。
# 終了コード: 0=全チェック通過, 1=ブロッキングな問題あり。
set -uo pipefail

ok()   { printf '  [OK] %s\n' "$1"; }
ng()   { printf '  [NG] %s\n' "$1"; BLOCK=1; }
info() { printf '       %s\n' "$1"; }

BLOCK=0
IT2="$(command -v it2 || echo "$HOME/.local/bin/it2")"

echo "== it2-doctor: iTerm2 Python API 前提診断 =="

# 1. iTerm2 内で実行されているか
if [ "${TERM_PROGRAM:-}" = "iTerm.app" ] || [ -n "${ITERM_SESSION_ID:-}" ]; then
  ok "iTerm2 内で実行中 (ITERM_SESSION_ID=${ITERM_SESSION_ID:-?})"
else
  ng "iTerm2 内で実行されていない (TERM_PROGRAM=${TERM_PROGRAM:-unset})"
  info "iTerm2 のターミナルから起動し直してください。"
fi

# 2. it2 CLI の有無
if [ -x "$IT2" ]; then
  ok "it2 CLI: $IT2 ($($IT2 --version 2>/dev/null))"
else
  ng "it2 CLI が見つからない"
  info "インストール: uv tool install it2   (または pipx install it2)"
fi

# 3. Python API サーバが有効か
if [ "$(defaults read com.googlecode.iterm2 EnableAPIServer 2>/dev/null)" = "1" ]; then
  ok "Enable Python API 設定 = 有効"
else
  ng "Enable Python API が無効"
  info "iTerm2 > Settings > General > Magic > 'Enable Python API' をオンにする。"
fi

# 4. 実接続テスト（Automation 権限 / cookie の最終確認）
if [ -x "$IT2" ]; then
  OUT="$(timeout 20 "$IT2" session list 2>&1)"
  if printf '%s' "$OUT" | grep -qiE 'not running inside|not enabled|connection error'; then
    ng "it2 が iTerm2 に接続できない (Automation 権限 / cookie 未取得)"
    info "初回のみ次の許可が必要:"
    info "  1) it2 を一度手で実行し、表示される 2つのダイアログを許可する"
    info "     ('X wants to control iTerm2' と Automation の許可)"
    info "  2) それでも失敗する場合: System Settings > Privacy & Security >"
    info "     Automation で、ターミナル/claude が iTerm2 を制御するのを許可"
    info "  3) 代替: iTerm2 の Scripts メニュー経由なら ITERM2_COOKIE が注入され確実"
    info "  --- it2 の生出力 ---"
    printf '%s\n' "$OUT" | sed 's/^/       | /'
  else
    ok "it2 → iTerm2 接続 OK (session list 応答あり)"
  fi
fi

echo
if [ "$BLOCK" -eq 0 ]; then
  echo "== 結果: 全チェック通過。iterm2 スキルを使用可能 =="
  exit 0
else
  echo "== 結果: 上記 [NG] を解消してください =="
  exit 1
fi
