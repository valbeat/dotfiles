---
allowed-tools: Read, Bash(git diff:*), Bash(git log:*), Bash(git status:*), Glob, Grep
description: Perform comprehensive code review based on project standards
argument-hint: "[--uncommitted|--staged|--brief|<file>]"
---

# Code Review

## Context

- Project Standards: @.claude/CLAUDE.md
- Current changes: !`git diff HEAD --stat`
- Current branch: !`git branch --show-current`

## Arguments

| Argument | Description |
|----------|-------------|
| (none) | Review current branch vs base branch |
| `--uncommitted` | Review uncommitted changes (`git diff HEAD`) |
| `--staged` | Review staged changes (`git diff --cached`) |
| `--brief` | Output Critical/Warning only (for `/impl` integration) |
| `--commit <sha>` | Review specific commit |
| `--pr <number>` | Review GitHub PR |
| `<file_path>` | Review specific file(s) |

## Review Process

### 1. Identify Review Scope

```bash
# Default: branch diff
git diff $(git merge-base HEAD origin/master)..HEAD

# --uncommitted
git diff HEAD

# --staged
git diff --cached
```

### 2. Project Standards Check

- Read CLAUDE.md for conventions
- Check language config files (.eslintrc, biome.json, etc.)
- Look for CONTRIBUTING.md

### 3. Review Checklist

#### Architecture & Design
- [ ] Follows existing patterns
- [ ] Appropriate abstraction
- [ ] SOLID principles
- [ ] DRY compliance

#### Code Quality
- [ ] Clear naming
- [ ] Consistent formatting
- [ ] Appropriate comments
- [ ] No dead code

#### Testing (TDD)
- [ ] Tests written first
- [ ] Tests cover expected I/O
- [ ] Descriptive test names
- [ ] Independent tests

#### Security & Performance
- [ ] No hardcoded secrets
- [ ] Input validation
- [ ] Error handling
- [ ] No obvious bottlenecks

#### Git & Docs
- [ ] Conventional Commit format
- [ ] Atomic changes
- [ ] Docs updated if needed

### 4. Language-Specific

**Go:**
- [ ] Error handling (no ignored errors)
- [ ] Proper context usage
- [ ] No goroutine leaks

**TypeScript/JavaScript:**
- [ ] Proper async/await
- [ ] No `any` without justification
- [ ] Proper error boundaries

**Rust:**
- [ ] Proper Result/Option handling
- [ ] No unsafe without justification
- [ ] Lifetime annotations clear

## Output Format

### Standard Output

```markdown
## Code Review Report

### Summary
- Files reviewed: X
- Lines changed: +Y -Z
- Critical issues: A
- Warnings: B

### ✅ Good Practices
- [Positive aspects]

### 🔴 Critical (Must Fix)
1. **[Issue]**
   - File: path:line
   - Problem: [Description]
   - Fix: [Suggestion]

### 🟡 Warning (Should Fix)
1. **[Issue]**
   - File: path:line
   - Current: [Approach]
   - Better: [Suggestion]

### 🔵 Info (Nice to Have)
1. [Minor suggestions]

### Metrics
- Risk: low/medium/high
- Complexity: simple/moderate/complex
```

### Brief Output (--brief)

For `/impl` integration, output only:

```
PASSED: No critical issues

or

ISSUES FOUND:
- [Critical] path:line - description
- [Warning] path:line - description
```

## Integration with /impl

When called with `--uncommitted --brief`:
- Focus on changed files only
- Report Critical/Warning issues only
- Skip Info-level suggestions
- Used for self-review in TDD cycle

## Examples

```bash
# Review branch changes (default)
/code-review

# Review uncommitted changes
/code-review --uncommitted

# Brief output for /impl
/code-review --uncommitted --brief

# Review staged changes
/code-review --staged

# Review specific files
/code-review src/app.ts src/utils.ts

# Review GitHub PR
/code-review --pr 42
```

## Notes

- Always check against CLAUDE.md rules
- For TDD projects, verify tests were written first
- Use Conventional Commit format for fix commits
- Consider security implications
