#!/bin/bash
set -euo pipefail

# PostToolUse logger: 全 ToolUse を JSONL でログ記録
# ~/.claude/logs/tooluse-YYYY-MM-DD.jsonl に追記

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ツール別にログに残す要約を抽出（全 tool_input を保存すると巨大になるため）
case "$TOOL_NAME" in
  Bash)
    SUMMARY=$(echo "$INPUT" | jq -r '.tool_input.command // empty' | head -c 500)
    ;;
  Read)
    SUMMARY=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  Write|Edit|MultiEdit)
    SUMMARY=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  Glob)
    SUMMARY=$(echo "$INPUT" | jq -r '.tool_input.pattern // empty')
    ;;
  Grep)
    SUMMARY=$(echo "$INPUT" | jq -r '(.tool_input.pattern // "") + " in " + (.tool_input.path // ".")')
    ;;
  WebFetch)
    SUMMARY=$(echo "$INPUT" | jq -r '.tool_input.url // empty')
    ;;
  WebSearch)
    SUMMARY=$(echo "$INPUT" | jq -r '.tool_input.query // empty')
    ;;
  *)
    SUMMARY=$(echo "$INPUT" | jq -c '.tool_input // {}' | head -c 300)
    ;;
esac

jq -nc \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg session "$SESSION_ID" \
  --arg summary "$SUMMARY" \
  '{timestamp: $ts, tool: $tool, session: $session, summary: $summary}' \
  >> "$LOG_DIR/tooluse-$(date +%Y-%m-%d).jsonl"

exit 0
