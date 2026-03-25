---
name: fix-pr
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Glob, Grep, AskUserQuestion
disable-model-invocation: true
argument-hint: "<pr-number>"
description: >-
  Comprehensively handles GitHub PR fixes including CI failures, merge conflicts,
  and review comments (including Copilot code review). Resolves all issues until
  the PR is merge-ready. Use when fixing PRs, resolving CI failures, handling
  review comments, or when the user says "fix PR", "fix CI", "resolve PR issues",
  "PRを直して", or "CIを直して".
---

# Fix PR

## Context

- Current repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repository"`
- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Project standards: @.claude/CLAUDE.md

## Your task

Comprehensively handle GitHub PR fixes including CI failures, merge conflicts, review comments (human and Copilot), and other PR-related issues. Iterate until ALL issues are resolved and the PR is merge-ready.

## Steps

### Phase 1: Assess PR State

1.  **Check PR details, status, and mergeability**
    ```bash
    gh pr view <pr-number>
    gh pr checks <pr-number>
    gh pr view <pr-number> --json mergeable,mergeStateStatus,baseRefName,headRefName
    ```

2.  **Checkout PR branch**
    ```bash
    gh pr checkout <pr-number>
    ```

### Phase 2: Resolve Merge Conflicts

3.  **Check for conflicts and resolve them**
    ```bash
    # Determine base branch from PR
    BASE_BRANCH=$(gh pr view <pr-number> --json baseRefName -q .baseRefName)
    git fetch origin
    git merge origin/$BASE_BRANCH
    ```

    If conflicts occur:
    - Review each conflicting file carefully
    - Understand the intent of both sides before resolving
    - Resolve conflicts preserving the correct logic from both branches
    - After resolving all conflicts:
      ```bash
      git add <resolved-files>
      git commit -m "fix: resolve merge conflicts with $BASE_BRANCH"
      ```
    - If conflicts are too complex to resolve automatically, use AskUserQuestion to confirm resolution strategy

### Phase 3: Handle Review Comments

4.  **Fetch all review threads (including Copilot)**

    Get repository owner/repo:
    ```bash
    REPO_INFO=$(gh repo view --json owner,name -q '.owner.login + "/" + .name')
    OWNER=$(echo $REPO_INFO | cut -d/ -f1)
    REPO=$(echo $REPO_INFO | cut -d/ -f2)
    ```

    Fetch all review threads with resolution status:
    ```bash
    gh api graphql \
      -F owner="$OWNER" \
      -F repo="$REPO" \
      -F prNumber=<pr-number> \
      -f query='
        query($owner: String!, $repo: String!, $prNumber: Int!) {
          repository(owner: $owner, name: $repo) {
            pullRequest(number: $prNumber) {
              reviewThreads(first: 100) {
                nodes {
                  id
                  isResolved
                  isOutdated
                  path
                  line
                  comments(first: 50) {
                    nodes {
                      id
                      databaseId
                      body
                      createdAt
                      author {
                        login
                      }
                    }
                  }
                }
              }
            }
          }
        }
      '
    ```

5.  **Process each UNRESOLVED review thread**

    Filter to unresolved threads only (`isResolved: false`). For each thread:

    **a) Identify the commenter:**
    - Copilot: `author.login` contains `copilot` (e.g., `copilot-pull-request-reviewer`)
    - Human reviewer: any other login

    **b) Classify the comment type and handle:**

    | Type | Action |
    |------|--------|
    | **Code change request** (Copilot or human) | Implement the fix in the specified file/line |
    | **Question from human reviewer** | Use AskUserQuestion, then reply with their answer |
    | **Nitpick / style suggestion** | Implement if straightforward; otherwise ask user |
    | **False positive / unnecessary suggestion** | Ask user whether to address or dismiss |

    **c) After implementing fixes, reply to the comment:**
    Use the `databaseId` of the first (top-level) comment in the thread:
    ```bash
    gh api --method POST repos/$OWNER/$REPO/pulls/<pr-number>/comments/<databaseId>/replies \
      -f body="Fixed: <brief description of what was changed>"
    ```

    **d) Resolve the thread:**
    Use the thread `id` (GraphQL node ID) from step 4:
    ```bash
    gh api graphql \
      -F threadId="<thread-id>" \
      -f query='
        mutation($threadId: ID!) {
          resolveReviewThread(input: { threadId: $threadId }) {
            thread {
              id
              isResolved
            }
          }
        }
      '
    ```

    > **Important:** Process ALL unresolved review threads before proceeding. Skip threads where `isOutdated: true` unless they contain still-relevant feedback.

### Phase 4: Fix CI Failures

6.  **Analyze CI failure cause**
    ```bash
    gh pr checks <pr-number> --verbose
    ```
    For failed checks, get detailed logs:
    ```bash
    gh run view <run-id> --log-failed
    ```
    For common failure patterns, see [references/ci-failure-patterns.md](references/ci-failure-patterns.md).

7.  **Implement the fix**
    - Fix based on the error message
    - Follow existing coding conventions
    - Solve with minimal changes

8.  **Final local verification**
    > **Important:** Before committing, run all checks equivalent to the CI pipeline.
    > Check `.github/workflows/`, `package.json` scripts, or `Makefile` for correct commands.

### Phase 5: Commit, Push, and Verify

9.  **Commit all fixes**
    ```bash
    git add <changed-files>
    git commit -m "fix: resolve issues for PR #<pr-number>"
    ```

10. **Push and monitor CI**
    ```bash
    git push
    gh pr checks <pr-number> --watch
    ```

11. **Verify all issues are resolved**
    ```bash
    gh pr checks <pr-number>
    gh pr view <pr-number> --json mergeable,mergeStateStatus
    ```

    Re-fetch review threads to confirm all are resolved:
    ```bash
    gh api graphql \
      -F owner="$OWNER" \
      -F repo="$REPO" \
      -F prNumber=<pr-number> \
      -f query='
        query($owner: String!, $repo: String!, $prNumber: Int!) {
          repository(owner: $owner, name: $repo) {
            pullRequest(number: $prNumber) {
              reviewThreads(first: 100) {
                nodes {
                  id
                  isResolved
                }
              }
            }
          }
        }
      ' | jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length'
    ```

    **If unresolved threads or CI failures remain, loop back to the appropriate phase.**

12. **Request re-review (if review comments were addressed)**
    ```bash
    gh pr view <pr-number> --json reviews --jq '[.reviews[].author.login] | unique | .[]'
    gh pr edit <pr-number> --add-reviewer <reviewer1>,<reviewer2>
    ```

## Notes

- Direct commits to the PR branch may be restricted depending on the PR author's settings. In that case, create a new branch and open a separate PR.
- The `--watch` option allows real-time monitoring of CI progress.
- Always ensure all local checks pass before pushing changes.
- Copilot review comments should be treated with the same priority as human reviews — implement fixes where valid, and reply explaining the resolution.
- When resolving threads, always reply BEFORE resolving so the reviewer can see what was done.
