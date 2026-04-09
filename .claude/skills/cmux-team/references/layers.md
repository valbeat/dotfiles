# Layer Specifications

## Master (This Session)

The user-facing layer. Runs in the current Claude Code session.

### Responsibilities

- Receive goal from user
- Decompose into discrete, parallelizable tasks
- Write task files to `.cmux-team/tasks/`
- Launch Manager workspace
- Monitor progress and report to user
- Integrate results when all tasks complete

### Task Decomposition Guidelines

- Each task should be independently executable
- Tasks should map to a single git branch
- Include clear acceptance criteria
- Avoid inter-task dependencies where possible
- If dependencies exist, use `depends_on` field in task frontmatter

### Task File Format

```yaml
---
id: "001"
name: implement-auth
status: pending          # pending | running | done | failed
branch: team/001-implement-auth
depends_on: []           # list of task IDs that must complete first
timeout_min: 30          # max execution time
---

<Task description in markdown>

## Acceptance Criteria
- <criterion 1>
- <criterion 2>
```

## Manager (Daemon Workspace)

Long-running process in a dedicated cmux workspace. Event-driven via polling.

### Responsibilities

- Poll `.cmux-team/tasks/` for pending tasks (10s interval)
- Respect `depends_on` — only start tasks whose dependencies are "done"
- Enforce concurrency limit (default: 3 concurrent Conductors)
- Launch Conductor for each ready task
- Track Conductor lifecycle (running → done/failed)
- Enforce task timeouts
- Write summary on completion

### State Machine

```
pending → running → done
                  → failed (on error or timeout)
```

### Concurrency Control

The Manager tracks active Conductors by counting tasks with `status: running`.
Before spawning a new Conductor, it checks:

```bash
RUNNING=$(grep -rl '^status: running' .cmux-team/tasks/ | wc -l)
if [ "$RUNNING" -ge "$MAX_CONCURRENT" ]; then
  # Wait for a slot
  continue
fi
```

## Conductor (Per-Task)

Short-lived process that manages a single task's lifecycle.

### Responsibilities

- Create git worktree for task isolation
- Spawn Agent (Claude Code) in the worktree
- Send task prompt to Agent
- Poll for Agent completion
- Collect results to `.cmux-team/results/<task-id>.md`
- Clean up workspace (worktree persists for review)

### Worktree Strategy

```bash
# Base branch: current HEAD of main/master
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

# Create worktree with task-specific branch
git worktree add ".cmux-team/worktrees/$TASK_ID" -b "$BRANCH" "origin/$BASE_BRANCH"
```

Benefits:
- Full git isolation — no conflicts between parallel tasks
- Each task gets its own branch for clean PRs
- Worktrees share object store — fast, disk-efficient

## Agent (Claude Code in Worktree)

The actual worker. Runs `claude --dangerously-skip-permissions` in the worktree directory.

### Responsibilities

- Execute the task described in the prompt
- Work autonomously within the worktree
- Commit changes to the task branch
- Exit when complete (returns to shell prompt)

### Agent Prompt Template

The Conductor constructs the prompt from the task file:

```
You are an Agent in a cmux-team hierarchy. Work autonomously.

## Task
<task description from file>

## Rules
- Work only in this directory (git worktree)
- Commit your changes with descriptive messages
- Do not push — the Master will handle PR creation
- When done, exit cleanly
```
