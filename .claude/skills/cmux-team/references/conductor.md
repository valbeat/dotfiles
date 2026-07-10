# Conductor Script

Full conductor script for `.cmux-team/conductor.sh`.

## Script

```bash
#!/usr/bin/env bash
set -euo pipefail

TASK_FILE="$1"
TASK_ID=$(grep '^id:' "$TASK_FILE" | tr -d '"' | awk '{print $2}')
TASK_NAME=$(grep '^name:' "$TASK_FILE" | awk '{print $2}')
BRANCH=$(grep '^branch:' "$TASK_FILE" | awk '{print $2}')
# optional fields — awk (not grep) so a missing field doesn't abort under set -e
TIMEOUT_MIN=$(awk '/^timeout_min:/{print $2}' "$TASK_FILE")
TIMEOUT_MIN="${TIMEOUT_MIN:-30}"
MODEL=$(awk '/^model:/{print $2}' "$TASK_FILE")
MODEL_FLAG=""
[ -n "$MODEL" ] && MODEL_FLAG=" --model $MODEL"

LOG=".cmux-team/logs/conductor-${TASK_ID}.log"
WORKTREE=".cmux-team/worktrees/$TASK_ID"
RESULT_FILE=".cmux-team/results/${TASK_ID}.md"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

log "Starting conductor for task $TASK_ID ($TASK_NAME)"

# --- 1. Update task status ---
sed -i '' "s/^status: pending/status: running/" "$TASK_FILE"
log "Status → running"

# --- 2. Create git worktree ---
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

if [ -d "$WORKTREE" ]; then
  log "Worktree already exists at $WORKTREE"
else
  git worktree add "$WORKTREE" -b "$BRANCH" "origin/$BASE_BRANCH" 2>>"$LOG" || {
    log "ERROR: Failed to create worktree"
    sed -i '' "s/^status: running/status: failed/" "$TASK_FILE"
    echo "# Task $TASK_ID: FAILED\n\nFailed to create git worktree for branch $BRANCH" > "$RESULT_FILE"
    exit 1
  }
fi
log "Worktree created at $WORKTREE"

# --- 3. Spawn Agent in new workspace ---
WS=$(cmux --json new-workspace "agent-$TASK_ID" | jq -r '.workspace')
S=$(cmux --json list-pane-surfaces --workspace "$WS" | jq -r '.[0].surface')
cmux rename-tab --surface "$S" "$S agent-$TASK_ID"
log "Workspace $WS, surface $S (tab labeled)"

WORKTREE_ABS=$(cd "$WORKTREE" && pwd)
cmux send --surface "$S" "cd ${WORKTREE_ABS} && claude --dangerously-skip-permissions${MODEL_FLAG}\n"

# --- 4. Wait for Claude to be ready ---
READY=false
for i in $(seq 1 30); do
  SCREEN=$(cmux read-screen --surface "$S" --lines 5)
  if echo "$SCREEN" | grep -qE '(>|❯|claude)'; then
    READY=true
    break
  fi
  sleep 1
done

if [ "$READY" = false ]; then
  log "ERROR: Claude not ready within 30s"
  sed -i '' "s/^status: running/status: failed/" "$TASK_FILE"
  echo "# Task $TASK_ID: FAILED\n\nClaude Code did not start within 30s" > "$RESULT_FILE"
  cmux close-workspace "$WS"
  exit 1
fi
log "Claude ready"

# --- 5. Send task prompt ---
# Extract body (everything after second ---) as the prompt
PROMPT=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$TASK_FILE")

cmux send --surface "$S" "$(cat <<AGENT_PROMPT
You are an Agent in a cmux-team hierarchy. Work autonomously.

## Task
${PROMPT}

## Rules
- Work only in this directory (git worktree)
- Commit your changes with descriptive messages
- Do not push — the Master will handle PR creation
- When done, exit cleanly
AGENT_PROMPT
)\n"

log "Prompt sent"

# --- 6. Wait for completion (with timeout) ---
DEADLINE=$(($(date +%s) + TIMEOUT_MIN * 60))
DONE=false

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  SCREEN=$(cmux read-screen --surface "$S" --lines 3)
  # Detect idle prompt (agent finished and returned to shell)
  if echo "$SCREEN" | grep -qE '^\$\s*$'; then
    DONE=true
    break
  fi
  sleep 10
done

if [ "$DONE" = false ]; then
  log "TIMEOUT after ${TIMEOUT_MIN}min"
  sed -i '' "s/^status: running/status: failed/" "$TASK_FILE"
  cmux read-screen --surface "$S" --scrollback 500 > "$RESULT_FILE"
  echo -e "\n\n---\n**TIMEOUT** after ${TIMEOUT_MIN} minutes" >> "$RESULT_FILE"
  cmux close-workspace "$WS"
  exit 1
fi

# --- 7. Collect results ---
cmux read-screen --surface "$S" --scrollback 500 > "$RESULT_FILE"
log "Results collected to $RESULT_FILE"

# --- 8. Update status ---
sed -i '' "s/^status: running/status: done/" "$TASK_FILE"
log "Status → done"

# --- 9. Cleanup workspace (worktree kept for review) ---
cmux close-workspace "$WS"
log "Workspace closed. Worktree preserved at $WORKTREE"
```

## Usage

```bash
# Make executable
chmod +x .cmux-team/conductor.sh

# Run for a single task
bash .cmux-team/conductor.sh .cmux-team/tasks/001-implement-auth.md
```

## Notes

- The worktree is preserved after completion so the Master can review changes and create PRs
- `sed -i ''` is macOS-compatible; for Linux use `sed -i`
- The timeout is per-task, configured in the task file's `timeout_min` field
- The Agent model is per-task via the optional `model` field (`sonnet` / `opus` / `fable`) — see SKILL.md § Model Selection
- Logs are per-conductor at `.cmux-team/logs/conductor-<id>.log`
