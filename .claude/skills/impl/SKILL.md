---
name: impl
description: >-
  Implements features or fixes bugs following TDD methodology with strict
  RED→GREEN→REFACTOR cycle. Use when implementing features, fixing bugs
  with TDD, or when the user says "implement", "build feature", or "TDD".
argument-hint: "[task description]"
---

# /impl - TDD Development Command

This command follows Kent Beck's TDD methodology.
Strictly adheres to the RED→GREEN→REFACTOR cycle with a test-first approach.

**Integrated commands**: Uses `/check` and `/review` internally.

## Usage

```bash
/impl Add validation to login form
/impl  # Start interactively
```

---

## [1/4] Task Preparation

### Get Task Description

- If `$ARGUMENTS` exists: Use as-is
- If empty: Ask with AskUserQuestion

### Branch Guard

This command commits during the TDD cycle. Before starting, check the current branch:
if on `main`/`master`, create a feature branch first
(`git switch -c feat/<short-description>` or `fix/<short-description>`).
Never commit directly to the base branch.

### Check Existing Documents

Check for `docs/DESIGN.md` and `docs/TODO.md` using Read tool.

**If docs/TODO.md exists**:
- Read content and understand phase structure
- Check RED/GREEN/REFACTOR tasks in each phase

TODO.md structure example:
```markdown
### Phase 1: Implement version calculation

- [ ] [RED] Write test for calculate_latest
- [ ] [GREEN] Implement calculate_latest
- [ ] [REFACTOR] Refactor calculate_latest
```

---

## [2/4] Phase Execution

### Manage Tasks with TodoWrite

Manage current phase tasks with TodoWrite.

### RED-GREEN-REFACTOR Cycle

#### RED (Write Test)

1. Update TodoWrite to `in_progress`
2. Write test based on expected input/output
3. Run `/check --test`, **confirm failure**
4. **Verify the test fails for the RIGHT reason**:
   - Correct: assertion failure (expected vs actual mismatch)
   - Wrong: compile error, import error, syntax error, missing fixture
   - If it fails for the wrong reason, fix the test setup and re-run until the
     failure is an assertion failure
5. Commit on failure (proves test is correct). Commit message: `test: <what the test verifies>`
6. Update TodoWrite to `completed`

#### GREEN (Implement)

1. Update TodoWrite to `in_progress`
2. Write **minimal implementation** to pass test
3. Run `/check --test`, **confirm success**
4. **Do NOT modify the test to make it pass.** If the test itself looks wrong,
   stop and confirm with the user before changing it
5. If tests still fail after 3 fix attempts, stop and report the failure output to the user
6. Update TodoWrite to `completed`

#### REFACTOR

1. Update TodoWrite to `in_progress`
2. Improve code quality following design principles
3. Run `/check --test`, **maintain success** (tests must not be modified)
4. If nothing needs refactoring, state so explicitly and skip (do not invent changes)
5. Update TodoWrite to `completed`

**Design Principles Checklist**:

| Category | Check Items |
|----------|-------------|
| SOLID | Single Responsibility, Dependency Inversion |
| Testability | Dependency Injection, Pure Functions |
| Structure | High Cohesion, Low Coupling, DRY |
| Simplicity | YAGNI, KISS |

---

## [3/4] Phase Approval

After completing all RED/GREEN/REFACTOR tasks in phase:

### Step 1: Self Review

Run `/review --uncommitted --brief`:

```
Review changed files.
Report Critical/Warning issues only.
```

**If issues found**:
1. Fix issues
2. Confirm success with `/check --test`
3. Run self review again
4. Repeat until no issues (max 3 rounds — if issues remain after 3 rounds,
   report the remaining issues to the user and ask how to proceed)

### Step 2: Quality Check

Run `/check`:

```bash
# Run all checks (lint, format, build, test)
```

**On failure**:
1. Fix issues
2. Run `/check` again
3. Repeat until passed

### Step 3: Phase Completion

Ask for approval with AskUserQuestion:

```
Phase X completed.

Implemented:
- [Features implemented]

Changed files:
- [File list]

Test results: X tests passed
Review results: PASSED

Proceed to next phase?
```

---

## [4/4] Completion

### Completion Summary

```
✓ Development completed

Implemented:
- [List of features/fixes]

Created/Modified files:
- [File path list]

Test results:
- X tests passed

Quality checks:
- lint: PASSED
- format: PASSED
- build: PASSED
```

### Next Action

Ask with AskUserQuestion:
- **Commit**: Run `/commit`
- **Done**: End development

---

## TDD Absolute Rules

1. **Never write code without tests**
2. **Follow RED→GREEN→REFACTOR cycle**
3. **Minimal implementation** - Only code to pass current test
4. **Refactor only when GREEN**
5. **Commit on RED** - Proves test is correct

## Anti-patterns

- Write tests "later"
- Implement before writing tests
- Refactor when RED
- Implement multiple phases simultaneously
- Skip quality checks
