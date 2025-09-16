---
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Glob, Grep
description: Comprehensively handle GitHub PR fixes (CI failures, conflicts, reviews)
---

# Fix PR

Comprehensively handle GitHub PR fixes (CI failures, conflicts, review comments, etc.).

## Usage
```
Fix PR #<pr-number>
```

## Steps

1.  **Check PR details and status**
    ```bash
    # Get PR information
    gh pr view <pr-number>
    
    # Check PR diff
    gh pr diff <pr-number>
    
    # Check CI status
    gh pr checks <pr-number>
    
    # Check if mergeable
    gh pr view <pr-number> --json mergeable,mergeStateStatus
    ```

2.  **Checkout PR branch**
    ```bash
    # Fetch and checkout the PR branch
    gh pr checkout <pr-number>
    ```

3.  **Check for and resolve conflicts**
    ```bash
    # Fetch the latest from the base branch
    git fetch origin
    
    # Check for conflicts by merging or rebasing
    git merge origin/main  # or master
    # or
    git rebase origin/main
    
    # If there are conflicts
    git status  # Check the conflicting files
    
    # After resolving conflicts
    git add .
    git rebase --continue  # if rebasing
    # or
    git commit  # if merging
    ```

4.  **Check review comments**
    ```bash
    # View review comments
    gh pr view <pr-number> --comments
    
    # Check for unresolved reviews
    gh pr view <pr-number> --json reviews
    ```

5.  **Analyze CI failure cause**
    ```bash
    # Check the details of the failed checks
    gh pr checks <pr-number> --verbose
    
    # View the log for a specific job
    gh run view --job=<job-id> --log
    ```

6.  **Implement the fix**
    *   Fix based on the error message
    *   Follow existing coding conventions
    *   Solve the problem with minimal changes
    *   Modify tests as needed

7.  **Final local verification**
    > **Important:** Before committing, run all checks equivalent to the CI pipeline.
    > To find the correct commands, check CI configuration files in `.github/workflows/`, `scripts` in `package.json`, `Makefile`, etc.

    ```bash
    # (Example) Check the commands run in the project's CI
    # Check .github/workflows/ci.yml
    cat .github/workflows/ci.yml

    # Check scripts in package.json
    cat package.json

    # Run the identified commands
    npm run format && npm run lint && npm run typecheck && npm test
    # or
    cargo fmt && cargo clippy && cargo check && cargo test
    ```

8.  **Commit the fix**
    > Only commit the changes if all local verifications have passed.
    ```bash
    git add .
    git commit -m "fix: resolve issues for PR #<pr-number>"
    # Example: git commit -m "fix: resolve linting errors and merge conflicts for PR #123"
    ```

9.  **Push and re-run CI**
    ```bash
    # Push to the current branch
    git push
    
    # Watch the CI results
    gh pr checks <pr-number> --watch
    ```

10. **Confirm CI success**
    ```bash
    # Check if all checks have passed
    gh pr checks <pr-number>
    
    # Check the PR status
    gh pr view <pr-number>
    ```

## Common CI Failure Patterns

### Test Failures
- Existing tests broken by new code
- Incorrect environment variable or mock configuration
- Asynchronous timing issues

### Linting Errors
- ESLint/Clippy warnings
- Unused variables or imports
- Code convention violations

### Type Errors
- TypeScript/Rust type mismatches
- Handling of null/undefined
- Generics issues

### Formatting Errors
- Forgetting to apply Prettier/rustfmt
- Indentation or spacing issues

### Build Errors
- Dependency problems
- Environment-specific configurations
- Version mismatches

## Notes

- Direct commits to the PR branch may be restricted depending on the PR author's settings.
- In that case, create a new branch and open a separate PR.
- Detailed CI logs can be found on the GitHub Actions page.
- The `--watch` option allows real-time monitoring of CI progress.
- Always ensure all local checks pass before pushing changes.
