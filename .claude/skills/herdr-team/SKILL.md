---
name: herdr-team
description: >-
  Multi-agent orchestration framework with 4-layer hierarchy —
  Master, Manager, Conductor, Agent. Manages parallel sub-agents in
  git worktrees via herdr. Use when user says "team start", "チーム起動",
  "マルチエージェント", "parallel tasks", "並列タスク実行", or needs to run
  multiple autonomous agents on separate tasks in a herdr session.
  herdr counterpart of the cmux-team skill.
allowed-tools: Bash
argument-hint: "<task-list or goal> [--agents N]"
---

# herdr Team Orchestration

4-layer agent hierarchy for autonomous multi-task execution, built on herdr's native
worktree + agent-status support. Terminal-native counterpart of `cmux-team`.

```
Master（this session — user interaction, task creation）
  └── Manager（idle-wait loop, task detection → Conductor spawn）
        └── Conductor（herdr worktree isolation, autonomous execution）
              └── Agent（actual work: impl, test, research, etc.）
```

## Architecture Overview

| Layer | Role | Lifecycle | Communication |
|-------|------|-----------|---------------|
| **Master** | Decomposes goal into task files | This session | Writes `.herdr-team/tasks/*.md` |
| **Manager** | Daemon: polls tasks, spawns Conductors | Long-running herdr workspace | Reads task dir, writes status |
| **Conductor** | Per-task: worktree + Agent + result collection | Spawned by Manager, exits on completion | Reads task file, writes result |
| **Agent** | Claude Code in a worktree workspace | Spawned by Conductor | Reads prompt from Conductor |

## Why herdr fits this well

- `herdr worktree create --branch … --base …` makes the branch **and** its workspace in
  one call — Conductor isolation is one command.
- Per-pane `agent_status` + `herdr wait agent-status --status idle` gives reliable
  completion detection (no screen-scraping for prompts).

## Your Task

1. **Initialize** — create `.herdr-team/` structure.
2. **Decompose** — break the goal into discrete, independent task files.
3. **Launch Manager** — spawn the Manager in a dedicated herdr workspace.
4. **Monitor** — report progress as tasks complete.

### Decomposition Rules

- **Independent**: parallel worktrees must never touch the same files. If they would,
  merge into one task.
- **Self-contained**: each task file is executable by an agent with NO access to this
  conversation — include all paths, constraints, and decisions in the body.
- **Verifiable**: every task has Acceptance Criteria as checkable statements (commands,
  expected behavior).
- **Right-sized**: one task = one PR-sized change.

## Quick Start

### 1. Initialize

```bash
mkdir -p .herdr-team/tasks .herdr-team/results .herdr-team/logs
```

### 2. Create Task Files

```bash
cat > .herdr-team/tasks/001-implement-auth.md << 'TASK'
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
CREATE=$(herdr workspace create --label team-manager --no-focus)
WS=$(echo "$CREATE" | jq -r '.result.workspace.workspace_id')
P=$(echo  "$CREATE" | jq -r '.result.root_pane.pane_id')
herdr pane run "$P" "claude --dangerously-skip-permissions"
herdr wait output "$P" --match '(❯|>|Claude Code)' --regex --timeout 30000

herdr pane send-text "$P" "$(cat <<'PROMPT'
You are the Manager in a herdr-team hierarchy.

## Your Loop
1. Poll .herdr-team/tasks/ every 10s for files with status: pending
2. For each pending task:
   a. Update status to "running"
   b. Run: bash .herdr-team/conductor.sh <task-file>
3. When the conductor exits, check .herdr-team/results/<task-id>.md
4. Update task status to "done" or "failed"
5. Continue until no pending tasks remain
6. Write a summary to .herdr-team/results/summary.md

## Rules
- Max 3 concurrent Conductors
- On Conductor failure, mark task "failed" and continue
- Log all actions to .herdr-team/logs/manager.log
PROMPT
)"
herdr pane send-keys "$P" Enter
```

### 4. Monitor Progress

```bash
for f in .herdr-team/tasks/*.md; do
  echo "$(basename "$f"): $(grep '^status:' "$f" | cut -d' ' -f2)"
done
cat .herdr-team/results/summary.md
tail -20 .herdr-team/logs/manager.log
```

## Conductor Script

See @references/conductor.md for the full script. Core flow (herdr worktree does the
isolation in one call):

```bash
# .herdr-team/conductor.sh <task-file>
TASK_FILE="$1"
TASK_ID=$(grep '^id:'     "$TASK_FILE" | tr -d '"' | awk '{print $2}')
BRANCH=$( grep '^branch:'  "$TASK_FILE" | awk '{print $2}')

# 1. Create worktree + its workspace in one shot
CREATE=$(herdr worktree create --branch "$BRANCH" --base main --label "agent-$TASK_ID" --no-focus)
WS=$(echo "$CREATE" | jq -r '.result.workspace.workspace_id // .result.workspace_id')
P=$( echo "$CREATE" | jq -r '.result.root_pane.pane_id // .result.pane.pane_id')

# 2. Launch the Agent
herdr pane run "$P" "claude --dangerously-skip-permissions"
herdr wait output "$P" --match '(❯|>|Claude Code)' --regex --timeout 30000

# 3. Send the task body as the prompt
PROMPT=$(sed '1,/^---$/d; /^---$/d' "$TASK_FILE")
herdr pane send-text "$P" "$PROMPT"
herdr pane send-keys "$P" Enter

# 4. Wait for completion, then collect results
herdr wait agent-status "$P" --status idle --timeout 1800000
herdr pane read "$P" --source recent --lines 500 > ".herdr-team/results/${TASK_ID}.md"

# 5. Cleanup
herdr workspace close "$WS"
```

## Communication Protocol

Pull-based, file-driven — no push notifications needed.

```
.herdr-team/
├── tasks/            # Master writes, Manager reads (pending → running → done/failed)
├── results/          # Conductor writes, Master reads (+ summary.md)
├── logs/             # All layers append
└── (worktrees managed by herdr; list with: herdr worktree list)
```

## Error Handling

- **Manager crash**: relaunch — it resumes from task file statuses (idempotent).
- **Conductor timeout**: `herdr wait agent-status` returns non-zero after `--timeout`;
  mark the task "failed" and close the workspace.
- **Agent blocked**: read the pane, send the required input via `pane send-text` + `Enter`.
- **Worktree conflict**: `herdr worktree create` errors → skip task, mark "failed".
- **herdr not found**: abort with installation instructions.

## Cleanup

```bash
# Close team workspaces
herdr workspace list | jq -r '.result.workspaces[] | select(.label|test("team-manager|^agent-")) | .workspace_id' \
  | xargs -I{} herdr workspace close {}

# Remove team worktrees (herdr-created)
herdr worktree list | jq -r '.result.worktrees[] | select(.branch|test("^team/")) | .open_workspace_id // empty' \
  | xargs -I{} herdr worktree remove --workspace {} --force

# Remove state directory
rm -rf .herdr-team/
```

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../herdr-agent/SKILL.md](../herdr-agent/SKILL.md) | Single sub-agent spawn (simpler, no hierarchy) |
| [../herdr-core/SKILL.md](../herdr-core/SKILL.md) | Core topology + worktree control |
| [../herdr-fork/SKILL.md](../herdr-fork/SKILL.md) | Fork the current session (interactive) |
| [../cmux-team/SKILL.md](../cmux-team/SKILL.md) | Same role, but for the cmux GUI app |
