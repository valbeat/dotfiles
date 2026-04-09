---
name: cmux-fork
description: >-
  Fork the current Claude Code session into a new cmux split pane with
  --continue --fork-session. Use when user says "fork", "split claude",
  "別ペインで", "フォーク", "並列セッション", or needs a parallel Claude session.
allowed-tools: Bash
argument-hint: "[direction: right|left|up|down] (default: right)"
---

# cmux Fork Session

Fork the current Claude Code session into a new cmux split pane.

## Your Task

1. Parse the direction argument (default: `right`). Valid values: `right`, `left`, `up`, `down`.
2. Run the fork commands below via Bash.
3. Report the new surface ref to the user.

## Commands

```bash
# Create split and capture surface ref (use --json for reliable parsing)
S=$(cmux --json new-split "${DIRECTION:-right}" | jq -r '.surface')
cmux send --surface "$S" "claude --continue --fork-session\n"
echo "Forked session on $S"
```

## Examples

```bash
# Split right (default)
S=$(cmux --json new-split right | jq -r '.surface')
cmux send --surface "$S" "claude --continue --fork-session\n"

# Split down
S=$(cmux --json new-split down | jq -r '.surface')
cmux send --surface "$S" "claude --continue --fork-session\n"
```

## Error Handling

- If `cmux` is not found: report that cmux CLI is not installed
- If `cmux new-split` fails: check `cmux list-panes` to verify topology, report the error
- If `cmux send` fails: report the surface ref and suggest manual execution

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [cmux](../cmux/SKILL.md) | Topology control (windows, workspaces, panes, surfaces) |
| [cmux-browser](../cmux-browser/SKILL.md) | Browser automation in cmux webviews |
| [cmux-markdown](../cmux-markdown/SKILL.md) | Markdown viewer panel with live reload |
| [cmux-agent](../cmux-agent/SKILL.md) | Spawn headless sub-agent in a new workspace |
