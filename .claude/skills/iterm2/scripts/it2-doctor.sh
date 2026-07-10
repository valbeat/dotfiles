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

# 4. it2 の websockets バージョン（>=11 は iterm2 2.20 と非互換で RecursionError）
IT2_PY="$HOME/.local/share/uv/tools/it2/bin/python"
WS_VER="$("$IT2_PY" -c 'import importlib.metadata as m; print(m.version("websockets"))' 2>/dev/null)"
if [ -n "$WS_VER" ]; then
  if [ "${WS_VER%%.*}" -lt 11 ] 2>/dev/null; then
    ok "it2 の websockets = $WS_VER (<11, 互換)"
  else
    ng "it2 の websockets = $WS_VER (>=11 は RecursionError で接続不可)"
    info "再インストールで <11 に固定:"
    info "  uv tool install --force it2 --with 'websockets<11'"
  fi
else
  info "it2 の websockets バージョン未取得（uv tool 以外の導入かも）"
fi

# 5. 実接続テスト
if [ -x "$IT2" ]; then
  OUT="$(timeout 20 "$IT2" session list 2>&1)"
  if printf '%s' "$OUT" | grep -qiE 'not running inside|not enabled|connection error|no close frame|recursion'; then
    ng "it2 が iTerm2 に接続できない"
    info "確認順（この順で潰す）:"
    info "  1) 上の websockets が <11 に固定されているか"
    info "  2) Enable Python API をオンにした後、iTerm2 を再起動したか（設定反映に必要）"
    info "  3) 初回接続時に iTerm2 が出す API クライアント許可ダイアログを Allow したか"
    info "  --- it2 の生出力（末尾） ---"
    printf '%s\n' "$OUT" | tail -3 | sed 's/^/       | /'
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
