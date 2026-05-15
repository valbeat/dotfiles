#!/bin/bash
set -euo pipefail

# PreToolUse guard: 危険なコマンドを BLOCK / WARN で制御
# exit 2 = BLOCK（実行を阻止）
# stderr 出力 = ユーザーへの警告メッセージ
# exit 0 = 通過

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/guard-$(date +%Y-%m-%d).jsonl"

log_event() {
  local level="$1" pattern="$2" detail="$3"
  jq -nc \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg level "$level" \
    --arg pattern "$pattern" \
    --arg detail "$detail" \
    --arg tool "$TOOL_NAME" \
    '{timestamp: $ts, level: $level, tool: $tool, pattern: $pattern, detail: $detail}' \
    >> "$LOG_FILE"
}

case "$TOOL_NAME" in
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    [ -z "$CMD" ] && exit 0

    # === BLOCK: 破壊的 git 操作 ===
    if echo "$CMD" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+--force'; then
      log_event "BLOCK" "git-force-push" "$CMD"
      echo "BLOCKED: git force push は guard により禁止されています: $CMD" >&2
      exit 2
    fi

    if echo "$CMD" | grep -qE 'git\s+reset\s+--hard'; then
      log_event "BLOCK" "git-reset-hard" "$CMD"
      echo "BLOCKED: git reset --hard は guard により禁止されています: $CMD" >&2
      exit 2
    fi

    if echo "$CMD" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
      log_event "BLOCK" "git-clean-force" "$CMD"
      echo "BLOCKED: git clean -f は guard により禁止されています: $CMD" >&2
      exit 2
    fi

    # === BLOCK: hook スキップ ===
    if echo "$CMD" | grep -qE 'git\s+commit.*--no-verify|git\s+push.*--no-verify'; then
      log_event "BLOCK" "no-verify" "$CMD"
      echo "BLOCKED: --no-verify は guard により禁止されています: $CMD" >&2
      exit 2
    fi

    # === BLOCK: GPG 署名スキップ ===
    if echo "$CMD" | grep -qE -- '--no-gpg-sign|commit\.gpgsign=false'; then
      log_event "BLOCK" "no-gpg-sign" "$CMD"
      echo "BLOCKED: GPG署名スキップは guard により禁止されています: $CMD" >&2
      exit 2
    fi

    # === BLOCK: 広範囲の削除 ===
    if echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f?\s+(/|~|\$HOME|\.\.)'; then
      log_event "BLOCK" "rm-recursive-dangerous" "$CMD"
      echo "BLOCKED: 危険な再帰削除が検知されました: $CMD" >&2
      exit 2
    fi

    # === BLOCK: claude -p / --print (サブスク対象外、API 課金) ===
    # 対話モード (claude --dangerously-skip-permissions など) は -p を含まないので素通り。
    # 明示的に許可したい場合のみ CLAUDE_ALLOW_PRINT=1 を付与する。
    if echo "$CMD" | grep -qE '(^|[[:space:]|;&])claude([[:space:]]+[^|;&]*)?[[:space:]]+(-p|--print)([[:space:]]|$)'; then
      if [ "${CLAUDE_ALLOW_PRINT:-0}" != "1" ]; then
        log_event "BLOCK" "claude-print-mode" "$CMD"
        echo "BLOCKED: claude -p / --print はサブスクリプション対象外（API 課金）です。Skill 内なら Task ツールで agent 起動、外部 script なら codex CLI を検討。明示許可は CLAUDE_ALLOW_PRINT=1: $CMD" >&2
        exit 2
      fi
      log_event "WARN" "claude-print-mode-allowed" "$CMD"
    fi

    # === WARN: 本番系キーワード ===
    if echo "$CMD" | grep -qiE '(production|prod)\s.*(deploy|push|release)'; then
      log_event "WARN" "production-operation" "$CMD"
      echo "WARNING: 本番環境への操作が検知されました: $CMD" >&2
      # WARN は通過させる（exit 0）
    fi

    # === WARN: データベース破壊操作 ===
    if echo "$CMD" | grep -qiE '(DROP\s+(TABLE|DATABASE)|TRUNCATE|DELETE\s+FROM)\s'; then
      log_event "WARN" "destructive-sql" "$CMD"
      echo "WARNING: 破壊的SQL操作が検知されました: $CMD" >&2
    fi
    ;;

  Write|Edit|MultiEdit)
    # === BLOCK: 秘匿情報の書き込み検知 ===
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')
    if [ -n "$CONTENT" ]; then
      if echo "$CONTENT" | grep -qE 'sk-[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36}|sk-ant-[a-zA-Z0-9-]{20,}'; then
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
        log_event "BLOCK" "secret-in-content" "$FILE_PATH"
        echo "BLOCKED: API キーまたは秘匿情報がコンテンツに含まれています" >&2
        exit 2
      fi
    fi
    ;;
esac

exit 0
