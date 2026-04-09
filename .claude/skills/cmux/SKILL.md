---
name: cmux
description: >-
  Control cmux topology and routing — windows, workspaces, panes, surfaces,
  focus, moves, reorder, identify, and trigger flash. Use when user says
  "split pane", "new workspace", "move surface", "list windows",
  "レイアウト変更", or needs deterministic placement in a multi-pane cmux layout.
allowed-tools: Bash
---

# cmux Core Control

Use this skill to control non-browser cmux topology and routing.

## Core Concepts

- Window: top-level macOS cmux window.
- Workspace: tab-like group within a window.
- Pane: split container in a workspace.
- Surface: a tab within a pane (terminal or browser panel).

## Fast Start

```bash
# identify current caller context
cmux identify --json

# list topology
cmux list-windows
cmux list-workspaces
cmux list-panes
cmux list-pane-surfaces --pane pane:1

# create/focus/move
cmux new-workspace
cmux new-split right --panel pane:1
cmux move-surface --surface surface:7 --pane pane:2 --focus true
cmux reorder-surface --surface surface:7 --before surface:3

# attention cue
cmux trigger-flash --surface surface:7
```

## Handle Model

- Default output uses short refs: `window:N`, `workspace:N`, `pane:N`, `surface:N`.
- UUIDs are still accepted as inputs.
- Request UUID output only when needed: `--id-format uuids|both`.

## Error Handling

- If `cmux` is not found: report that cmux CLI is not installed
- If a command returns an error: run `cmux identify --json` to verify context, then retry
- If a handle ref is invalid: run `cmux list-panes` or `cmux list-windows` to discover valid refs

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../cmux-browser/SKILL.md](../cmux-browser/SKILL.md) | Browser automation on surface-backed webviews |
| [../cmux-markdown/SKILL.md](../cmux-markdown/SKILL.md) | Markdown viewer panel with live file watching |
| [../cmux-fork/SKILL.md](../cmux-fork/SKILL.md) | Fork Claude session into a new split pane |
| [../cmux-agent/SKILL.md](../cmux-agent/SKILL.md) | Spawn headless sub-agent in a new workspace |
| [../cmux-team/SKILL.md](../cmux-team/SKILL.md) | Multi-agent orchestration (4-layer hierarchy) |
