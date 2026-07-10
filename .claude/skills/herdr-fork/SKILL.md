---
name: herdr-fork
description: >-
  Fork the current Claude Code session into a new herdr split pane with
  --continue --fork-session. Use when user says "fork", "split claude",
  "別ペインで", "フォーク", "並列セッション", or needs a parallel Claude session
  in a herdr terminal. herdr counterpart of the cmux-fork skill.
allowed-tools: Bash
argument-hint: "[direction: right|down] (default: right)"
---

# herdr Fork Session

Fork the current Claude Code session into a new herdr split pane. Terminal-native
counterpart of `cmux-fork`.

> Note: herdr splits are `right` or `down` only (no `left`/`up` at split time — use
> `herdr pane swap`/`move` afterward to reposition). Default: `right`.

## Your Task

1. Parse the direction argument (default `right`; valid: `right`, `down`).
2. Determine the current pane, split it, and launch a forked session in the new pane.
3. Report the new pane ref to the user.

## Commands

```bash
DIR="${DIRECTION:-right}"

# Current pane ref (the pane this session runs in)
CUR=$(herdr pane current --current | jq -r '.result.pane.pane_id // .result.pane_id')

# Split and capture the new pane ref
P=$(herdr pane split "$CUR" --direction "$DIR" --ratio 0.5 --focus | jq -r '.result.pane.pane_id')

# Fork the current session in the new pane
herdr pane run "$P" "claude --continue --fork-session"

echo "Forked session on pane $P (split $DIR)"
```

## Examples

```bash
# Split right (default)
P=$(herdr pane split "$(herdr pane current --current | jq -r '.result.pane.pane_id // .result.pane_id')" \
      --direction right --focus | jq -r '.result.pane.pane_id')
herdr pane run "$P" "claude --continue --fork-session"

# Split down
P=$(herdr pane split "$(herdr pane current --current | jq -r '.result.pane.pane_id // .result.pane_id')" \
      --direction down --focus | jq -r '.result.pane.pane_id')
herdr pane run "$P" "claude --continue --fork-session"
```

## Error Handling

- `herdr` not found → report that herdr CLI is not installed.
- `pane current` fails → you may not be running inside a herdr pane; fall back to
  `herdr pane list` and pick the focused pane (`.result.panes[] | select(.focused)`).
- `pane split` returns `{"error":...}` → run `herdr pane list` to verify topology, report
  the error.
- `pane run` fails → report the pane ref and suggest launching `claude --continue
  --fork-session` there manually.

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../herdr-core/SKILL.md](../herdr-core/SKILL.md) | Topology control (workspaces, tabs, panes, worktrees) |
| [../herdr-agent/SKILL.md](../herdr-agent/SKILL.md) | Spawn a headless sub-agent in a new workspace |
| [../herdr-team/SKILL.md](../herdr-team/SKILL.md) | Multi-agent orchestration (4-layer hierarchy) |
| [../cmux-fork/SKILL.md](../cmux-fork/SKILL.md) | Same role, but for the cmux GUI app |
