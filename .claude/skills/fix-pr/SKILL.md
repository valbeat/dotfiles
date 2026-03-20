---
name: fix-pr
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Glob, Grep, AskUserQuestion
disable-model-invocation: true
argument-hint: "<pr-number>"
description: >-
  Comprehensively handles GitHub PR fixes including CI failures, merge conflicts,
  and review comments. Use when fixing PRs, resolving CI failures, or when the
  user says "fix PR", "fix CI", or "resolve PR issues".
---

# Fix PR

## Context

- Current repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repository"`
- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Project standards: @.claude/CLAUDE.md

## Your task

Comprehensively handle GitHub PR fixes including CI failures, merge conflicts, review comments, and other PR-related issues. Analyze the PR state and implement appropriate fixes.

## Steps

1.  **Check PR details and status**
    ```bash
    gh pr view <pr-number>
    gh pr diff <pr-number>
    gh pr checks <pr-number>
    gh pr view <pr-number> --json mergeable,mergeStateStatus
    ```

2.  **Checkout PR branch**
    ```bash
    gh pr checkout <pr-number>
    ```

3.  **Check for and resolve conflicts**
    ```bash
    git fetch origin
    git merge origin/main  # or rebase
    ```

4.  **Check and handle review comments**
    ```bash
    gh pr view <pr-number> --comments
    gh api repos/{owner}/{repo}/pulls/<pr-number>/comments
    gh pr view <pr-number> --json reviews,reviewDecision
    ```

    For each unresolved review comment, classify and handle:

    **a) Change request:** Implement the fix, then reply:
    ```bash
    gh api repos/{owner}/{repo}/pulls/<pr-number>/comments/<comment-id>/replies \
      -f body="Fixed: <description>"
    ```

    **b) Question from reviewer:** Ask user via AskUserQuestion, then reply with their answer.

    **c) Nitpick:** Implement if straightforward, or ask the user.

    > **Important:** Process ALL review comments before proceeding.

5.  **Analyze CI failure cause**
    ```bash
    gh pr checks <pr-number> --verbose
    gh run view --job=<job-id> --log
    ```
    For common failure patterns, see [references/ci-failure-patterns.md](references/ci-failure-patterns.md).

6.  **Implement the fix**
    - Fix based on the error message
    - Follow existing coding conventions
    - Solve with minimal changes

7.  **Final local verification**
    > **Important:** Before committing, run all checks equivalent to the CI pipeline.
    > Check `.github/workflows/`, `package.json` scripts, or `Makefile` for correct commands.

8.  **Commit the fix**
    ```bash
    git add .
    git commit -m "fix: resolve issues for PR #<pr-number>"
    ```

9.  **Push and re-run CI**
    ```bash
    git push
    gh pr checks <pr-number> --watch
    ```

10. **Confirm CI success**
    ```bash
    gh pr checks <pr-number>
    gh pr view <pr-number>
    ```

11. **Request re-review (if review comments were addressed)**
    ```bash
    gh pr view <pr-number> --json reviews --jq '[.reviews[].author.login] | unique | .[]'
    gh pr edit <pr-number> --add-reviewer <reviewer1>,<reviewer2>
    gh pr comment <pr-number> --body "All review comments have been addressed. Requesting re-review."
    ```

## Notes

- Direct commits to the PR branch may be restricted depending on the PR author's settings.
- In that case, create a new branch and open a separate PR.
- The `--watch` option allows real-time monitoring of CI progress.
- Always ensure all local checks pass before pushing changes.
