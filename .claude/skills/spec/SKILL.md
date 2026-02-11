---
description: "Interactive planning command. Generate DESIGN.md and TODO.md for task planning"
argument-hint: "[task description]"
---

# /spec - Interactive Planning Command

This command interactively generates DESIGN.md (design document) and
TODO.md (task list) from user's task description.

## Usage

```bash
/spec Add OAuth2 to user authentication
/spec  # Start interactively
```

---

## [1/5] Task Description Preparation

### Get Task Description

- If `$ARGUMENTS` exists: Use as-is
- If empty: Ask with AskUserQuestion

### Check Existing Documents

Check for `docs/DESIGN.md` and `docs/TODO.md` using Read tool.

If existing files found, ask with AskUserQuestion:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Existing planning documents found. How to proceed?",
      header: "Existing Docs",
      options: [
        { label: "Create New", description: "Overwrite existing documents" },
        { label: "Update", description: "Read existing and update incrementally" },
        { label: "Cancel", description: "Exit command" }
      ],
      multiSelect: false
    }
  ]
})
```

---

## [2/5] Generate DESIGN.md

### Codebase Analysis

1. Understand project structure (Glob, Read)
2. Check existing architecture patterns
3. Read related existing code

### Create DESIGN.md

Create `docs/DESIGN.md` with following structure:

```markdown
# Design Document: [Task Name]

## Overview
[Purpose and background]

## Functional Requirements
- [ ] Requirement 1
- [ ] Requirement 2

## Non-Functional Requirements
- Performance
- Security
- Testability

## Architecture
[System structure, component diagram]

## Technology Choices
[Technologies, libraries to use]

## Impact Scope
[Files/modules affected by changes]
```

### User Approval

Get approval with AskUserQuestion:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "DESIGN.md generated. Proceed to interview phase?",
      header: "DESIGN.md Approval",
      options: [
        { label: "Approve", description: "Proceed to next phase" },
        { label: "Reject", description: "Exit command" }
      ],
      multiSelect: false
    }
  ]
})
```

---

## [3/5] Deep-dive Interview

### Conduct Interview

Based on DESIGN.md content, deep-dive with AskUserQuestion:

**Interview perspectives**:
- Technical implementation details
- UI/UX considerations
- Concerns and risks
- Trade-off decisions

**Important rules**:
- Don't ask obvious questions
- Explore implicit assumptions and undecided matters
- Continue until user says "done"

### Update Specifications

Append/update collected information to DESIGN.md.

---

## [4/5] Generate TODO.md

### Task Decomposition

Based on DESIGN.md, decompose into TDD cycles:

```markdown
# Task List: [Task Name]

## Phase 1: [Feature Name]

- [ ] [RED] Write test: [Test content]
- [ ] [GREEN] Implement: [Implementation content]
- [ ] [REFACTOR] Refactor

## Phase 2: [Feature Name]

- [ ] [RED] Write test: [Test content]
- [ ] [GREEN] Implement: [Implementation content]
- [ ] [REFACTOR] Refactor
```

### User Approval

```javascript
AskUserQuestion({
  questions: [
    {
      question: "TODO.md generated. Is this task list acceptable?",
      header: "TODO.md Approval",
      options: [
        { label: "Approve", description: "Complete with this task list" },
        { label: "Reject", description: "Exit command" }
      ],
      multiSelect: false
    }
  ]
})
```

---

## [5/5] Completion and Implementation Start

### Display Summary

```
✓ Planning completed

Generated files:
- docs/DESIGN.md  (Design document)
- docs/TODO.md    (Task list)
```

### Next Action

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Start implementation?",
      header: "Next Action",
      options: [
        { label: "Start Implementation", description: "Run /impl" },
        { label: "Done", description: "End with planning only" }
      ],
      multiSelect: false
    }
  ]
})
```

---

## Important Notes

### MUST Rules
- TDD Compliance: All tasks implemented test-first
- Tidy First: Separate structural and behavioral changes
- Uncertainty Handling: Don't assume, ask questions
