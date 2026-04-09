# Communication Protocol

## Design Principle: Pull-Based, File-Driven

All communication between layers is through the filesystem. No push notifications, no sockets, no shared memory. Each layer polls for changes at its own cadence.

Benefits:
- Crash-resilient: state survives process restarts
- Debuggable: `cat` any file to see current state
- Idempotent: Manager can restart and resume from file state

## Directory Structure

```
.cmux-team/
├── tasks/                    # Task definitions (Master → Manager)
│   ├── 001-implement-auth.md
│   ├── 002-add-tests.md
│   └── 003-update-docs.md
├── results/                  # Task outputs (Conductor → Master)
│   ├── 001.md
│   ├── 002.md
│   └── summary.md            # Manager writes on all-done
├── logs/                     # Operational logs (all layers)
│   ├── manager.log
│   ├── conductor-001.log
│   └── conductor-002.log
├── worktrees/                # Git worktrees (Conductor creates)
│   ├── 001/
│   └── 002/
└── conductor.sh              # Conductor launch script
```

## Task File Format

```yaml
---
id: "001"
name: implement-auth
status: pending
branch: team/001-implement-auth
depends_on: []
timeout_min: 30
created_at: "2026-04-10T07:45:00+09:00"
started_at: ""
completed_at: ""
---

<Task body in markdown>
```

## Status Transitions

```
pending ──→ running ──→ done
                    └──→ failed
```

| Transition | Who | When |
|-----------|-----|------|
| → pending | Master | Task file created |
| pending → running | Conductor | Conductor starts execution |
| running → done | Conductor | Agent completes successfully |
| running → failed | Conductor | Agent error, timeout, or worktree conflict |

## Result File Format

```markdown
# Task 001: implement-auth

## Status: done

## Agent Output
<scrollback capture from cmux read-screen>

## Changes
<git log --oneline from worktree>

## Branch
team/001-implement-auth
```

## Summary File

Written by Manager when all tasks are complete:

```markdown
# Team Run Summary

## Tasks: 3 total, 2 done, 1 failed

| ID | Name | Status | Branch | Duration |
|----|------|--------|--------|----------|
| 001 | implement-auth | done | team/001-implement-auth | 12m |
| 002 | add-tests | done | team/002-add-tests | 8m |
| 003 | update-docs | failed | team/003-update-docs | 30m (timeout) |

## Next Steps
- Review branches and create PRs for completed tasks
- Investigate failed tasks
```

## Polling Intervals

| Layer | Polls | Interval |
|-------|-------|----------|
| Manager | `.cmux-team/tasks/` for pending tasks | 10s |
| Conductor | Agent screen for idle prompt | 10s |
| Master | `.cmux-team/results/` for completed tasks | On-demand |
