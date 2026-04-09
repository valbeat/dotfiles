---
name: cmux-agent
description: >-
  Spawn a headless Claude Code sub-agent in a new cmux workspace, send it a
  prompt, and collect results. Use when user says "spawn agent",
  "エージェント起動", "サブエージェントで", "delegate task", "タスク委任",
  "バックグラウンドで実行", or when another skill needs parallel task execution.
allowed-tools: Bash
argument-hint: "<prompt> [--name task-name] [--wait]"
---

# cmux Sub-Agent

Spawn a Claude Code sub-agent in a dedicated cmux workspace, send a task prompt, and optionally wait for results.

## Your Task

When invoked by the user:

1. Parse arguments: extract the prompt, optional task name (default: `agent-{timestamp}`), and whether to wait for results.
2. Run the spawn sequence below.
3. If `--wait`: poll for completion and return results.
4. If no `--wait`: report the workspace/surface refs so the user can check later.

## Spawn Sequence

```bash
TASK_NAME="${NAME:-agent-$(date +%s)}"

# 1. Create dedicated workspace
WS=$(cmux --json new-workspace "$TASK_NAME" | jq -r '.workspace')

# 2. Get the surface in the new workspace
S=$(cmux --json list-pane-surfaces --workspace "$WS" | jq -r '.[0].surface')

# 3. Label the tab with surface ref for identification
cmux rename-tab --surface "$S" "$S $TASK_NAME"

# 4. Launch Claude Code (headless, skip permissions for autonomous execution)
cmux send --surface "$S" "claude --dangerously-skip-permissions\n"

# 5. Wait for Claude to be ready (prompt detection)
for i in $(seq 1 30); do
  SCREEN=$(cmux read-screen --surface "$S" --lines 5)
  if echo "$SCREEN" | grep -qE '(>|❯|claude)'; then
    break
  fi
  sleep 1
done

# 6. Send the task prompt
cmux send --surface "$S" "${PROMPT}"
cmux send-key --surface "$S" return

echo "Agent spawned: workspace=$WS surface=$S task=$TASK_NAME"
```

## Collect Results

```bash
# Read the agent's screen output (last 500 lines of scrollback)
cmux read-screen --surface "$S" --scrollback 500

# Or check if the agent is still running
SCREEN=$(cmux read-screen --surface "$S" --lines 3)
if echo "$SCREEN" | grep -qE '(>|❯|claude)'; then
  echo "Agent idle — task likely complete"
fi
```

## Cleanup

```bash
# Close the workspace when done
cmux close-workspace "$WS"
```

## Programmatic Usage

Other skills can spawn sub-agents by running the commands directly:

```bash
# Minimal: spawn and fire
TASK_NAME="review-auth"
WS=$(cmux --json new-workspace "$TASK_NAME" | jq -r '.workspace')
S=$(cmux --json list-pane-surfaces --workspace "$WS" | jq -r '.[0].surface')
cmux rename-tab --surface "$S" "$S $TASK_NAME"
cmux send --surface "$S" "claude --dangerously-skip-permissions\n"
sleep 5
cmux send --surface "$S" "Review the auth middleware for security issues\n"

# Later: collect results
RESULT=$(cmux read-screen --surface "$S" --scrollback 500)

# Cleanup
cmux close-workspace "$WS"
```

### Multi-Agent Pattern

```bash
# Spawn multiple agents in parallel
for TASK in "review models/" "review controllers/" "review middleware/"; do
  TASK_NAME="review-$(echo "$TASK" | tr ' /' '-')"
  WS=$(cmux --json new-workspace "$TASK_NAME" | jq -r '.workspace')
  S=$(cmux --json list-pane-surfaces --workspace "$WS" | jq -r '.[0].surface')
  cmux rename-tab --surface "$S" "$S $TASK_NAME"
  cmux send --surface "$S" "claude --dangerously-skip-permissions\n"
  sleep 5
  cmux send --surface "$S" "${TASK}\n"
  echo "$TASK_NAME: workspace=$WS surface=$S"
done
```

## Error Handling

- If `cmux` is not found: report that cmux CLI is not installed
- If `cmux new-workspace` fails: check `cmux list-workspaces` for capacity, report the error
- If Claude prompt not detected within 30s: report timeout, suggest checking the surface manually with `cmux read-screen`
- If `cmux send` fails: report the surface ref and suggest manual execution
- If `cmux read-screen` returns empty: the agent may still be processing — retry after a delay

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../cmux/SKILL.md](../cmux/SKILL.md) | Core topology control (windows, workspaces, panes, surfaces) |
| [../cmux-fork/SKILL.md](../cmux-fork/SKILL.md) | Fork current session (interactive, not headless) |
| [../cmux-browser/SKILL.md](../cmux-browser/SKILL.md) | Browser automation in cmux webviews |
| [../cmux-markdown/SKILL.md](../cmux-markdown/SKILL.md) | Markdown viewer panel with live reload |
| [../cmux-team/SKILL.md](../cmux-team/SKILL.md) | Multi-agent orchestration (4-layer hierarchy) |
