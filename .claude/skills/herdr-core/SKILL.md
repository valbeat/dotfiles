---
name: herdr-core
description: >-
  Control herdr topology and routing — sessions, workspaces, tabs, panes,
  focus, splits, moves, swaps, zoom, and worktrees over the socket API.
  Use when user says "split pane", "new workspace", "move pane",
  "list workspaces", "レイアウト変更", or needs deterministic placement in a
  herdr terminal session. herdr counterpart of the cmux skill.
allowed-tools: Bash
---

# herdr Core Control

Use this skill to control herdr topology and routing via the socket API (`herdr <sub>`).
This is the terminal-native counterpart of the `cmux` skill.

## When to prefer this over cmux

- Inside a herdr session, over SSH (`herdr --remote`), or any headless/terminal-only
  context. Confirm the server with `herdr status server` (expect `status: running`).
- If `CMUX_WORKSPACE_ID` is set, you are inside cmux — prefer the `cmux` skill instead.

## Core Concepts

- **Session**: persistent server-backed session (survives detach). Named via `--session`.
- **Workspace**: top-level group with its own cwd (≈ cmux workspace).
- **Tab**: a tab within a workspace (≈ cmux surface).
- **Pane**: split container inside a tab where a shell/agent runs.

## Handle Model

- Refs look like `w1` (workspace), `w1:t1` (tab), `w1:p1` (pane).
- All socket-API subcommands emit JSON as `{"id":...,"result":{...}}`. Parse with `jq`
  under `.result`. Errors come back as `{"error":{"code","message"}}`.

## Fast Start

```bash
# status / topology
herdr status server
herdr workspace list | jq -c '.result.workspaces[] | {workspace_id,label,agent_status}'
herdr tab list       | jq -c '.result.tabs[]       | {tab_id,label}'
herdr pane list      | jq -c '.result.panes[]      | {pane_id,cwd,agent_status,focused}'

# create / focus
WS=$(herdr workspace create --label mytask --no-focus | jq -r '.result.workspace.workspace_id')
herdr workspace focus "$WS"
herdr tab create --workspace "$WS" --label build --no-focus

# split / navigate / arrange
P=$(herdr pane split w1:p1 --direction right --ratio 0.5 --no-focus | jq -r '.result.pane.pane_id')
herdr pane focus --direction left
herdr pane swap  --direction right
herdr pane zoom  --toggle
herdr pane resize --direction right --amount 0.1

# move a pane to a new tab / workspace
herdr pane move "$P" --new-tab --label logs
herdr pane move "$P" --new-workspace --label scratch

# read / send into a pane
herdr pane read "$P" --source recent --lines 80
herdr pane send-text "$P" "echo hi"
herdr pane send-keys "$P" Enter
herdr pane run "$P" "make check"     # command text + Enter in one call

# attention cue (herdr's flash equivalent)
herdr notification show "Done" --sound done
```

## Worktree Helpers

herdr has first-class git worktree support — the core of parallel-branch workflows.

```bash
herdr worktree list | jq -c '.result.worktrees[] | {branch,path,open_workspace_id}'

# create a worktree + its workspace in one shot
herdr worktree create --branch feat/foo --base main --label foo --focus
# open an existing branch/path as a workspace
herdr worktree open --branch feat/foo --focus
# remove
herdr worktree remove --workspace <ID> --force
```

## Cleanup

```bash
herdr pane close <pane_id>
herdr tab close <tab_id>
herdr workspace close <workspace_id>
```

## Error Handling

- `herdr` not found → report that herdr CLI is not installed.
- Command returns `{"error":...}` → run `herdr status server`; if not running, `herdr` (or
  `herdr --session <name>`) starts it. Then re-list refs and retry.
- Invalid ref → re-discover with `herdr workspace list` / `herdr pane list`.
- Pass **raw ref strings** (e.g. `w1:p1`), never a jq-extracted JSON object.

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../herdr-agent/SKILL.md](../herdr-agent/SKILL.md) | Spawn a headless sub-agent in a new workspace |
| [../herdr-fork/SKILL.md](../herdr-fork/SKILL.md) | Fork the current Claude session into a split pane |
| [../herdr-team/SKILL.md](../herdr-team/SKILL.md) | Multi-agent orchestration (4-layer hierarchy) |
| [../cmux/SKILL.md](../cmux/SKILL.md) | Same role, but for the cmux GUI app |

> No herdr equivalent of `cmux-browser` (herdr is terminal-only, no webview).
> For browser automation use the `claude-in-chrome` MCP tools instead.
