---
name: cmux-team
description: >-
  Multi-agent orchestration framework with 4-layer hierarchy —
  Master, Manager, Conductor, Agent. Manages parallel sub-agents in
  git worktrees via cmux. Use when user says "team start", "チーム起動",
  "マルチエージェント", "parallel tasks", "並列タスク実行",
  or needs to run multiple autonomous agents on separate tasks.
allowed-tools: Bash
argument-hint: "<task-list or goal> [--agents N]"
---

# cmux Team Orchestration

4-layer agent hierarchy for autonomous multi-task execution.

```
Master（this session — user interaction, task creation）
  └── Manager（idle-wait loop, task detection → Conductor spawn）
        └── Conductor（git worktree isolation, autonomous execution）
              └── Agent（actual work: impl, test, research, etc.）
```

## Architecture Overview

| Layer | Role | Lifecycle | Communication |
|-------|------|-----------|---------------|
| **Master** | User-facing. Decomposes goal into tasks, writes task files | This session | Writes `.cmux-team/tasks/*.md` |
| **Manager** | Daemon. Polls for new tasks, spawns Conductors | Long-running cmux workspace | Reads task dir, writes status |
| **Conductor** | Per-task. Creates worktree, launches Agent, collects result | Spawned by Manager, exits on completion | Reads task file, writes result file |
| **Agent** | Claude Code in worktree. Executes the actual work | Spawned by Conductor | Reads prompt from Conductor |

See @references/layers.md for detailed layer specifications.

## Your Task

When invoked:

1. **Initialize** — Create `.cmux-team/` directory structure
2. **Decompose** — Break the user's goal into discrete task files (rules below)
3. **Launch Manager** — Spawn the Manager in a dedicated cmux workspace
4. **Monitor** — Report progress as tasks complete

### Decomposition Rules

- **Independent**: tasks run in parallel worktrees — two tasks must never modify the
  same files. If they would, merge them into one task
- **Self-contained**: each task file must be executable by an agent with NO access to
  this conversation. Include all context (file paths, constraints, relevant decisions)
  in the task body
- **Verifiable**: every task has Acceptance Criteria written as checkable statements
  (commands to run, expected behavior), not vague goals
- **Right-sized**: one task = one PR-sized change. Split anything larger into
  sequential tasks; do not create tasks that depend on another task's uncommitted output

## Quick Start

### 1. Initialize

```bash
mkdir -p .cmux-team/tasks .cmux-team/results .cmux-team/logs
```

### 2. Create Task Files

Each task is a markdown file in `.cmux-team/tasks/`:

```bash
cat > .cmux-team/tasks/001-implement-auth.md << 'TASK'
---
id: "001"
name: implement-auth
status: pending
branch: team/001-implement-auth
---

Implement JWT authentication middleware.

## Acceptance Criteria
- Middleware validates JWT tokens
- Returns 401 on invalid/expired tokens
- Passes user context to downstream handlers
TASK
```

### 3. Launch Manager

```bash
WS=$(cmux --json new-workspace "team-manager" | jq -r '.workspace')
S=$(cmux --json list-pane-surfaces --workspace "$WS" | jq -r '.[0].surface')
cmux rename-tab --surface "$S" "$S manager"
cmux send --surface "$S" "claude --dangerously-skip-permissions\n"
sleep 5
cmux send --surface "$S" "$(cat <<'PROMPT'
You are the Manager in a cmux-team hierarchy.

## Your Loop

1. Poll .cmux-team/tasks/ every 10 seconds for files with status: pending
2. For each pending task:
   a. Update status to "running"
   b. Run the conductor script: bash .cmux-team/conductor.sh <task-file>
3. When conductor exits, check .cmux-team/results/<task-id>.md
4. Update task status to "done" or "failed"
5. Continue polling until no pending tasks remain
6. Report summary to .cmux-team/results/summary.md

## Rules
- Max 3 concurrent Conductors
- If a Conductor fails, mark task as "failed" and continue
- Log all actions to .cmux-team/logs/manager.log
PROMPT
)\n"
```

### 4. Monitor Progress

```bash
# Check task statuses
for f in .cmux-team/tasks/*.md; do
  echo "$(basename "$f"): $(grep '^status:' "$f" | cut -d' ' -f2)"
done

# Read results
cat .cmux-team/results/summary.md

# View Manager logs
tail -20 .cmux-team/logs/manager.log
```

## Conductor Script

See @references/conductor.md for the full script. Core flow:

```bash
# .cmux-team/conductor.sh <task-file>
TASK_FILE="$1"
TASK_ID=$(grep '^id:' "$TASK_FILE" | tr -d '"' | awk '{print $2}')
BRANCH=$(grep '^branch:' "$TASK_FILE" | awk '{print $2}')

# 1. Create git worktree
WORKTREE=".cmux-team/worktrees/$TASK_ID"
git worktree add "$WORKTREE" -b "$BRANCH" 2>/dev/null || git worktree add "$WORKTREE" "$BRANCH"

# 2. Spawn Agent in new workspace
WS=$(cmux --json new-workspace "agent-$TASK_ID" | jq -r '.workspace')
S=$(cmux --json list-pane-surfaces --workspace "$WS" | jq -r '.[0].surface')
cmux rename-tab --surface "$S" "$S agent-$TASK_ID"
cmux send --surface "$S" "cd $WORKTREE && claude --dangerously-skip-permissions\n"
sleep 5

# 3. Send task prompt
PROMPT=$(sed '1,/^---$/d; /^---$/d' "$TASK_FILE")
cmux send --surface "$S" "${PROMPT}\n"

# 4. Wait for completion (poll for idle prompt)
while true; do
  SCREEN=$(cmux read-screen --surface "$S" --lines 3)
  if echo "$SCREEN" | grep -qE '(>|❯)'; then
    break
  fi
  sleep 10
done

# 5. Collect results
cmux read-screen --surface "$S" --scrollback 500 > ".cmux-team/results/${TASK_ID}.md"

# 6. Cleanup
cmux close-workspace "$WS"
```

## Communication Protocol

Pull-based, file-driven — no push notifications required.

```
.cmux-team/
├── tasks/            # Master writes, Manager reads
│   ├── 001-*.md      # status: pending → running → done/failed
│   └── 002-*.md
├── results/          # Conductor writes, Master reads
│   ├── 001.md
│   ├── 002.md
│   └── summary.md    # Manager writes on completion
├── logs/             # All layers append
│   └── manager.log
└── worktrees/        # Conductor creates, auto-cleaned
    ├── 001/
    └── 002/
```

See @references/communication.md for file format specs and status transitions.

## Error Handling

- **Manager crash**: Relaunch — it resumes from task file statuses (idempotent)
- **Conductor timeout**: Manager kills workspace after configurable timeout (default: 30min)
- **Agent failure**: Conductor captures error output to result file, marks task as "failed"
- **Git worktree conflict**: Conductor skips task, marks as "failed" with conflict details
- **cmux not found**: Abort with installation instructions

## Cleanup

```bash
# Remove all worktrees
git worktree list | grep cmux-team | awk '{print $1}' | xargs -I{} git worktree remove {}

# Close all team workspaces
cmux list-workspaces | grep -E '(team-manager|agent-)' | xargs -I{} cmux close-workspace {}

# Remove state directory
rm -rf .cmux-team/
```

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../cmux-agent/SKILL.md](../cmux-agent/SKILL.md) | Single sub-agent spawn (simpler, no hierarchy) |
| [../cmux/SKILL.md](../cmux/SKILL.md) | Core topology control |
| [../cmux-fork/SKILL.md](../cmux-fork/SKILL.md) | Fork current session (interactive) |
