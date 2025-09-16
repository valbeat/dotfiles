---
allowed-tools: Read, Bash(git diff:*), Bash(git log:*), Bash(git status:*), Glob, Grep
description: Perform comprehensive code review based on project standards
---

# Code Review

## Context

- Project Standards: @.claude/CLAUDE.md
- Current changes: !`git diff HEAD`
- Recent commits: !`git log --oneline -5`
- Current branch: !`git branch --show-current`
- Git Workflow: Follow conventional commit format and feature branch workflow
- TDD Philosophy: Check if tests follow t-wada's TDD approach when applicable

## Your task

You are a senior code reviewer conducting a thorough review of code changes. Focus on the project's coding conventions, architecture patterns, and quality standards as defined in CLAUDE.md and other project documentation.

## Arguments

- `target`: What to review (optional)
  - If not specified: Review current branch vs base branch (`git diff $(git merge-base HEAD origin/master)..HEAD`)
  - `--uncommitted`: Review uncommitted changes (`git diff HEAD`)
  - `--staged`: Review staged changes (`git diff --cached`)
  - `--commit <sha>`: Review specific commit
  - `--pr <number>`: Review GitHub PR (if available)
  - `<file_path>`: Review specific file(s)

## Review Process

1. **Identify Review Scope**
   - Detect what needs review based on arguments
   - Use `git diff` commands to get changes
   - For PRs, use `gh pr view` and `gh pr diff`

2. **Project Standards Check**
   - Read CLAUDE.md for project-specific conventions
   - Check for language-specific config files (.eslintrc, prettier, etc.)
   - Look for CONTRIBUTING.md or style guides

3. **Code Quality Review**

   ### Architecture & Design
   - [ ] Follows existing patterns in the codebase
   - [ ] Appropriate abstraction levels
   - [ ] SOLID principles adherence
   - [ ] DRY (Don't Repeat Yourself) compliance
   - [ ] Proper separation of concerns

   ### Code Style & Conventions
   - [ ] Naming conventions (variables, functions, files)
   - [ ] Consistent formatting and indentation
   - [ ] Appropriate comments (not too many, not too few)
   - [ ] File organization follows project structure

   ### Testing (TDD Check)
   - [ ] Tests written before implementation (TDD approach)
   - [ ] Tests cover expected input/output
   - [ ] Test naming is descriptive
   - [ ] No test logic in production code
   - [ ] Tests are independent and isolated

   ### Git & Documentation
   - [ ] Commit messages follow Conventional Commit format
   - [ ] Changes are atomic and focused
   - [ ] Documentation updated if needed
   - [ ] No debug code or console logs

   ### Security & Performance
   - [ ] No hardcoded secrets or credentials
   - [ ] Input validation present
   - [ ] Error handling appropriate
   - [ ] No obvious performance bottlenecks
   - [ ] Resource cleanup handled properly

   ### Language-Specific Checks
   
   **JavaScript/TypeScript:**
   - [ ] Proper async/await usage
   - [ ] No var declarations (use const/let)
   - [ ] TypeScript types properly defined
   - [ ] No any types without justification
   
   **Python:**
   - [ ] PEP 8 compliance
   - [ ] Type hints where appropriate
   - [ ] Proper exception handling
   
   **Shell Scripts:**
   - [ ] Proper quoting of variables
   - [ ] Exit codes handled
   - [ ] ShellCheck compliance

4. **Gemini Collaboration (if complex)**
   - For complex reviews, consult Gemini for additional insights:
   ```bash
   gemini <<EOF
   役割: シニアコードレビュアー
   タスク: 以下の変更をレビューし、改善点を指摘
   コンテキスト: [diff内容]
   制約条件: プロジェクトのCLAUDE.mdに従う
   出力形式: 重要度別の改善提案リスト
   EOF
   ```

5. **Generate Review Report**

## Output Format

```markdown
## 📋 Code Review Report

### Summary
- Files reviewed: X
- Lines changed: +Y -Z
- Critical issues: A
- Suggestions: B

### ✅ Good Practices
- [List positive aspects found]

### 🔴 Critical Issues (Must Fix)
1. **[Issue Title]**
   - File: path/to/file.ext:line
   - Problem: [Description]
   - Suggestion: [How to fix]

### 🟡 Improvements (Should Consider)
1. **[Improvement Title]**
   - File: path/to/file.ext:line
   - Current: [Current approach]
   - Better: [Suggested approach]

### 🔵 Minor Suggestions (Nice to Have)
1. **[Suggestion Title]**
   - Details: [Description]

### 📊 Metrics
- Test coverage impact: [increase/decrease/unchanged]
- Complexity: [simple/moderate/complex]
- Risk level: [low/medium/high]

### Next Steps
- [ ] Address critical issues
- [ ] Consider improvements
- [ ] Update tests if needed
- [ ] Update documentation
```

## Examples

```bash
# Review current branch vs base branch (default)
@code-review

# Review uncommitted changes
@code-review --uncommitted

# Review staged changes
@code-review --staged

# Review specific commit
@code-review --commit abc123

# Review specific files
@code-review src/app.js src/utils.js

# Review GitHub PR
@code-review --pr 42
```

## Integration with CI/CD

Consider running automated checks before manual review:
```bash
# Run all project checks first
@run-checks

# Then perform code review
@code-review
```

## Notes

- Always check against project-specific CLAUDE.md rules
- For TDD projects, ensure tests were written first
- Use Conventional Commit format for any fix commits
- Consider security implications of all changes
- Check for proper error handling and edge cases
- Verify documentation is updated when needed