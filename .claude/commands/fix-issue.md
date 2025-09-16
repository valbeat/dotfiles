---
allowed-tools: Read, Write, Edit, Bash(gh:*), Bash(git:*), Glob, Grep
description: Analyze and fix a GitHub issue by its issue number
---

# Fix GitHub Issue

Analyze and fix a GitHub issue by its issue number.

## Usage
```
Fix issue #<issue-number>
```

## Steps

1. **View the issue details**
   ```bash
   gh issue view <issue-number>
   gh issue view <issue-number> --comments  # Include comments for more context
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b fix/issue-<issue-number>
   # Or for features: git checkout -b feat/issue-<issue-number>
   ```

3. **Analyze the problem**
   - Read issue description and acceptance criteria
   - Check linked issues or PRs
   - Review any provided error messages or logs
   - Understand the expected vs actual behavior

4. **Search the codebase**
   - Use grep/glob to find relevant files
   - Look for error messages mentioned in the issue
   - Find related tests and documentation

5. **Implement the fix**
   - Follow TDD principles if requested
   - Make minimal changes to fix the issue
   - Follow existing code conventions
   - Add comments only if explicitly needed

6. **Run quality checks**
   ```bash
   # Format code
   npm run format || cargo fmt
   
   # Run linter
   npm run lint || cargo clippy
   
   # Type check
   npm run typecheck || cargo check
   
   # Run tests
   npm test || cargo test
   ```

7. **Create commit**
   ```bash
   git add .
   git commit -m "fix: <description> (#<issue-number>)"
   # Example: git commit -m "fix: handle null response in API client (#123)"
   ```

8. **Push and create PR**
   ```bash
   git push -u origin fix/issue-<issue-number>
   gh pr create --title "fix: <description>" --body "Fixes #<issue-number>" --assignee @me
   ```

## Commit Message Format
- Use `fix:` prefix for bug fixes
- Use `feat:` prefix for new features
- Reference the issue: `(#123)` or in body: `Fixes #123`
- Keep subject line under 50 characters

## Notes
- Always link the PR to the issue using "Fixes #123" in the PR body
- The issue will automatically close when the PR is merged
- If the issue is in a different repo, use full reference: "Fixes owner/repo#123"
- Run all checks locally before pushing to avoid CI failures
