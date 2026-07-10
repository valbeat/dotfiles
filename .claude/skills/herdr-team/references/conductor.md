# Conductor Script

Full conductor script for `.herdr-team/conductor.sh`.

## Script

```bash
#!/usr/bin/env bash
set -euo pipefail

TASK_FILE="$1"
TASK_ID=$(grep '^id:'      "$TASK_FILE" | tr -d '"' | awk '{print $2}')
TASK_NAME=$(grep '^name:'   "$TASK_FILE" | awk '{print $2}')
BRANCH=$( grep '^branch:'    "$TASK_FILE" | awk '{print $2}')
# optional fields — awk (not grep) so a missing field doesn't abort under set -e
TIMEOUT_MIN=$(awk '/^timeout_min:/{print $2}' "$TASK_FILE")
TIMEOUT_MIN="${TIMEOUT_MIN:-30}"
TIMEOUT_MS=$((TIMEOUT_MIN * 60 * 1000))
MODEL=$(awk '/^model:/{print $2}' "$TASK_FILE")
MODEL_FLAG=""
[ -n "$MODEL" ] && MODEL_FLAG=" --model $MODEL"

LOG=".herdr-team/logs/conductor-${TASK_ID}.log"
RESULT_FILE=".herdr-team/results/${TASK_ID}.md"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

log "Starting conductor for task $TASK_ID ($TASK_NAME)"

# --- 1. Update task status ---
sed -i '' "s/^status: pending/status: running/" "$TASK_FILE"
log "Status → running"

# --- 2. Create worktree + its workspace (herdr does both in one call) ---
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

CREATE=$(herdr worktree create --branch "$BRANCH" --base "$BASE_BRANCH" --label "agent-$TASK_ID" --no-focus 2>>"$LOG") || {
  log "ERROR: Failed to create worktree/workspace"
  sed -i '' "s/^status: running/status: failed/" "$TASK_FILE"
  printf '# Task %s: FAILED\n\nFailed to create worktree for branch %s\n' "$TASK_ID" "$BRANCH" > "$RESULT_FILE"
  exit 1
}
WS=$(echo "$CREATE" | jq -r '.result.workspace.workspace_id // .result.workspace_id')
P=$( echo "$CREATE" | jq -r '.result.root_pane.pane_id // .result.pane.pane_id')
log "Worktree workspace $WS, pane $P"

# --- 3. Launch the Agent ---
herdr pane run "$P" "claude --dangerously-skip-permissions${MODEL_FLAG}"

# --- 4. Wait for Claude to be ready ---
if ! herdr wait output "$P" --match '(❯|>|Claude Code)' --regex --timeout 30000 >>"$LOG" 2>&1; then
  log "ERROR: Claude not ready within 30s"
  sed -i '' "s/^status: running/status: failed/" "$TASK_FILE"
  printf '# Task %s: FAILED\n\nClaude Code did not start within 30s\n' "$TASK_ID" > "$RESULT_FILE"
  herdr workspace close "$WS"
  exit 1
fi
log "Claude ready"

# --- 5. Send task prompt (body after the second ---) ---
PROMPT=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$TASK_FILE")

herdr pane send-text "$P" "$(cat <<AGENT_PROMPT
You are an Agent in a herdr-team hierarchy. Work autonomously.

## Task
${PROMPT}

## Rules
- Work only in this directory (git worktree)
- Commit your changes with descriptive messages
- Do not push — the Master will handle PR creation
- When done, exit cleanly
AGENT_PROMPT
)"
herdr pane send-keys "$P" Enter
log "Prompt sent"

# --- 6. Wait for completion (native agent-status, with timeout) ---
if ! herdr wait agent-status "$P" --status idle --timeout "$TIMEOUT_MS" >>"$LOG" 2>&1; then
  log "TIMEOUT after ${TIMEOUT_MIN}min"
  sed -i '' "s/^status: running/status: failed/" "$TASK_FILE"
  herdr pane read "$P" --source recent --lines 500 > "$RESULT_FILE"
  printf '\n\n---\n**TIMEOUT** after %s minutes\n' "$TIMEOUT_MIN" >> "$RESULT_FILE"
  herdr workspace close "$WS"
  exit 1
fi

# --- 7. Collect results ---
herdr pane read "$P" --source recent --lines 500 > "$RESULT_FILE"
log "Results collected to $RESULT_FILE"

# --- 8. Update status ---
sed -i '' "s/^status: running/status: done/" "$TASK_FILE"
log "Status → done"

# --- 9. Cleanup workspace (worktree kept for review) ---
herdr workspace close "$WS"
log "Workspace closed. Worktree preserved (herdr worktree list)."
```

## Usage

```bash
bash .herdr-team/conductor.sh .herdr-team/tasks/001-implement-auth.md
```

## Notes

- herdr's `worktree create` makes the branch **and** its workspace in one call, so there is
  no separate `git worktree add` step (contrast with cmux-team).
- Completion is detected via native per-pane `agent_status` (`herdr wait agent-status
  --status idle`), not by screen-scraping for a shell prompt — more reliable.
- The worktree is preserved after completion so the Master can review and create PRs; remove
  it later with `herdr worktree remove --workspace <ID> --force`.
- `sed -i ''` is macOS-compatible; on Linux use `sed -i`.
- Timeout is per-task via the task file's `timeout_min` field (default 30).
- The Agent model is per-task via the optional `model` field (`sonnet` / `opus` / `fable`) — see SKILL.md § Model Selection.
- Logs are per-conductor at `.herdr-team/logs/conductor-<id>.log`.
