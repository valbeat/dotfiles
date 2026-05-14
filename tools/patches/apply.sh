#!/usr/bin/env bash
#
# Claude Code プラグインキャッシュ内の `claude -p` 呼び出しを書き換えるパッチ群を適用する。
#
# 対応方針:
#   - improve_description.py  : codex CLI へ完全置換（テキスト生成のみで意味的に等価）
#   - run_eval.py             : CLAUDE_ALLOW_PRINT=1 を要求する guard を挿入（claude 挙動テストが目的のため codex 置換不可）
#   - benchmark-runner.ts     : 同じく guard を挿入
#
# 適用は冪等。再実行しても二重適用しない（各パッチ内で marker チェック）。
# プラグインアップデートで上書きされたら再実行する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 が必要です" >&2
  exit 1
fi

applied=0
skipped=0
missing=0

apply_patch() {
  local label="$1" script="$2"
  shift 2
  echo "--- $label ---"
  if python3 "$SCRIPT_DIR/$script" "$@"; then
    case "$?" in
      0) applied=$((applied + 1)) ;;
    esac
  else
    local rc=$?
    case "$rc" in
      10) skipped=$((skipped + 1)) ;;
      20) missing=$((missing + 1)) ;;
      *)  echo "  ERROR: rc=$rc" >&2 ;;
    esac
  fi
}

# skill-creator (marketplaces 配下、バージョン無しパス)
SKILL_CREATOR_ROOT="$HOME/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/scripts"

apply_patch "skill-creator/improve_description.py (codex 置換)" \
  patch-improve-description.py \
  "$SKILL_CREATOR_ROOT/improve_description.py"

apply_patch "skill-creator/run_eval.py (env guard)" \
  patch-run-eval.py \
  "$SKILL_CREATOR_ROOT/run_eval.py"

# vercel (cache 配下、バージョン付き)
VERCEL_GLOB="$HOME/.claude/plugins/cache/claude-plugins-official/vercel"
if [ -d "$VERCEL_GLOB" ]; then
  for runner in "$VERCEL_GLOB"/*/scripts/benchmark-runner.ts; do
    [ -e "$runner" ] || continue
    apply_patch "vercel/$(basename "$(dirname "$(dirname "$runner")")")/benchmark-runner.ts (env guard)" \
      patch-benchmark-runner.py \
      "$runner"
  done
else
  echo "skip: vercel プラグインキャッシュなし ($VERCEL_GLOB)"
  missing=$((missing + 1))
fi

echo ""
echo "=== Summary ==="
echo "  applied: $applied"
echo "  already patched (skipped): $skipped"
echo "  missing target: $missing"
