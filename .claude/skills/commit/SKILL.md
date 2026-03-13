---
name: commit
allowed-tools: Bash(git:*)
description: >-
  Creates git commits following the Conventional Commits specification.
  Use when committing changes, writing commit messages, or when the user
  says “commit”, “make a commit”, or “conventional commit”.
---

# Conventional Commit Command

## Context

- Current changes: !`git status`
- Staged changes: !`git diff --cached`
- Recent commits: !`git log --oneline -5`

## Your task

Make a commit following the Conventional Commits specification. Check current changes, stage appropriate files, and create a properly formatted commit message.

## Steps

1. Check git status to see what files have changed
2. Review the changes with git diff
3. Stage the appropriate files
4. Create a commit: `git commit -m “<type>(<scope>): <subject>”`

### Commit Types

`feat` | `fix` | `docs` | `style` | `refactor` | `perf` | `test` | `chore`

### Examples

```bash
git commit -m “feat(auth): add OAuth2 login support”
```

With body:
```bash
git commit -m “fix(api): handle null response from server

- Add null check before parsing response
- Return empty array instead of throwing error”
```

### Breaking Changes

Indicate with `!` before colon or `BREAKING CHANGE:` footer:
```bash
git commit -m “feat(api)!: change response format

BREAKING CHANGE: response now returns array instead of object”
```

