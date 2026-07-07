---
name: commit
allowed-tools: Bash(git:*)
disable-model-invocation: true
argument-hint: "[message]"
description: >-
  Creates git commits following the Conventional Commits specification.
  Use when committing changes, writing commit messages, or when the user
  says "commit", "make a commit", or "conventional commit".
---

# Conventional Commit Command

## Context

- Current branch: !`git branch --show-current`
- Current changes: !`git status`
- Staged changes: !`git diff --cached --stat`
- Recent commits: !`git log --oneline -5`

## Your task

Make a commit following the Conventional Commits specification. Check current changes, stage appropriate files, and create a properly formatted commit message.

## Steps

1. **Branch guard**: If the current branch is `main` or `master`, create a feature branch first
   (`git switch -c <type>/<short-description>`). Never commit directly to the base branch.
2. Check `git status` and `git diff` to understand ALL changes
3. **Stage only files related to one logical change**:
   - Stage files individually by path. Do NOT use `git add -A` or `git add .`
   - If the diff contains unrelated changes, split them into separate commits (repeat steps 3-4)
   - Never stage credentials, `.env` files, or generated artifacts
4. Create the commit: `git commit -m "<type>(<scope>): <subject>"`

## Message Rules

- Subject: imperative mood, no trailing period, aim for <= 50 chars
- Scope: optional; use the directory/module name (e.g. `auth`, `api`, `brew`)
- Body: add only when the "why" is not obvious from the subject
- Language: English

### Type selection (decision table)

| Change | Type |
|--------|------|
| New user-facing behavior | `feat` |
| Fixes incorrect behavior | `fix` |
| Code change, behavior unchanged | `refactor` |
| Tests only | `test` |
| Docs only | `docs` |
| Formatting / whitespace only | `style` |
| Performance improvement | `perf` |
| Build, deps, config, tooling | `chore` |

If multiple types apply to a single commit, pick by priority: `feat` > `fix` > `refactor` > others.

### Examples

```bash
git commit -m "feat(auth): add OAuth2 login support"
```

With body:
```bash
git commit -m "fix(api): handle null response from server

- Add null check before parsing response
- Return empty array instead of throwing error"
```

### Breaking Changes

Indicate with `!` before colon or `BREAKING CHANGE:` footer:
```bash
git commit -m "feat(api)!: change response format

BREAKING CHANGE: response now returns array instead of object"
```

## Before finishing, verify

- [ ] Commit was NOT made on `main`/`master`
- [ ] `git status` shows no accidentally staged unrelated files
- [ ] Subject follows `<type>(<scope>): <subject>` and is in English
