---
name: herdr-agent
description: >-
  Spawn a headless Claude Code sub-agent in a new herdr workspace, send it a
  prompt, and collect results. Use when user says "spawn agent",
  "エージェント起動", "サブエージェントで", "delegate task", "タスク委任",
  "バックグラウンドで実行", or when another skill needs parallel task execution
  in a herdr session. herdr counterpart of the cmux-agent skill.
allowed-tools: Bash
argument-hint: "<prompt> [--name task-name] [--wait]"
---

# herdr Sub-Agent

Spawn a Claude Code sub-agent in a dedicated herdr workspace, send a task prompt, and
optionally wait for completion. Terminal-native counterpart of `cmux-agent`.

Unlike cmux (which greps the screen for an idle prompt), herdr tracks **per-pane
`agent_status`** natively, so use `herdr wait agent-status --status idle` for reliable
completion detection.

## Your Task

1. Parse args: the prompt, optional `--name` (default `agent-{timestamp}`), and `--wait`.
2. Run the spawn sequence.
3. If `--wait`: block on `agent-status idle`, then read and return results.
4. If no `--wait`: report the workspace/pane refs so the user can check later.

## Spawn Sequence

```bash
TASK_NAME="${NAME:-agent-$(date +%s)}"

# 1. Create a dedicated workspace; capture workspace + root pane refs
CREATE=$(herdr workspace create --label "$TASK_NAME" --no-focus)
WS=$(echo "$CREATE" | jq -r '.result.workspace.workspace_id')
P=$(echo  "$CREATE" | jq -r '.result.root_pane.pane_id')

# 2. Launch Claude Code (headless, autonomous)
herdr pane run "$P" "claude --dangerously-skip-permissions"

# 3. Wait until Claude is ready to accept input
herdr wait output "$P" --match '(❯|>|Claude Code)' --regex --timeout 30000 || \
  echo "warning: prompt not detected within 30s — check with: herdr pane read $P"

# 4. Send the task prompt and submit
herdr pane send-text "$P" "$PROMPT"
herdr pane send-keys "$P" Enter

echo "Agent spawned: workspace=$WS pane=$P task=$TASK_NAME"
```

## Wait for Completion (--wait)

```bash
# Block until the agent goes idle (finished responding)
herdr wait agent-status "$P" --status idle --timeout 1800000

# Collect the result (recent scrollback)
herdr pane read "$P" --source recent --lines 500
```

## Collect Results (no --wait, check later)

```bash
herdr pane read "$P" --source recent --lines 500

# Or poll status once
herdr pane get "$P" | jq -r '.result.pane.agent_status // .result.agent_status'
```

## Cleanup

```bash
herdr workspace close "$WS"
```

## Multi-Agent Pattern

```bash
declare -a PANES
for TASK in "review models/" "review controllers/" "review middleware/"; do
  TASK_NAME="review-$(echo "$TASK" | tr ' /' '-')"
  CREATE=$(herdr workspace create --label "$TASK_NAME" --no-focus)
  P=$(echo "$CREATE" | jq -r '.result.root_pane.pane_id')
  herdr pane run "$P" "claude --dangerously-skip-permissions"
  herdr wait output "$P" --match '(❯|>|Claude Code)' --regex --timeout 30000
  herdr pane send-text "$P" "$TASK"
  herdr pane send-keys "$P" Enter
  PANES+=("$P")
  echo "$TASK_NAME: pane=$P"
done

# Later: wait for all, then read each
for P in "${PANES[@]}"; do
  herdr wait agent-status "$P" --status idle --timeout 1800000
  echo "=== $P ==="; herdr pane read "$P" --source recent --lines 200
done
```

## Notes

- `pane send-text` writes **literal text only**; always follow with `pane send-keys Enter`
  to submit. Use `pane run` for a command that should include Enter automatically.
- If the `claude` integration is installed (`herdr integration install claude`), herdr
  will label the pane's agent automatically and `herdr agent list` will show it; you can
  then target it by name via `herdr agent send/read/wait`.

## Error Handling

- `herdr` not found → report that herdr CLI is not installed.
- `workspace create` returns `{"error":...}` → run `herdr status server`; start with
  `herdr` if the server is down, then retry.
- Prompt not detected in 30s → report timeout; inspect with `herdr pane read $P --lines 40`.
- `wait agent-status` times out → the agent may be blocked on input; read the pane and
  send any required response with `pane send-text` + `pane send-keys Enter`.

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../herdr-core/SKILL.md](../herdr-core/SKILL.md) | Core topology control (workspaces, tabs, panes, worktrees) |
| [../herdr-fork/SKILL.md](../herdr-fork/SKILL.md) | Fork the current session (interactive, not headless) |
| [../herdr-team/SKILL.md](../herdr-team/SKILL.md) | Multi-agent orchestration (4-layer hierarchy) |
| [../cmux-agent/SKILL.md](../cmux-agent/SKILL.md) | Same role, but for the cmux GUI app |
