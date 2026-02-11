---
description: "Read DESIGN.md and conduct deep-dive interview on technical implementation, UI/UX, concerns, and trade-offs"
argument-hint: "[DESIGN.md path]"
---

# /interview - Deep-dive Interview Command

## Overview

Read DESIGN.md and conduct deep-dive interview with user.
After interview completion, write collected specifications to DESIGN.md.

## Usage

```bash
/interview                    # Default: docs/DESIGN.md
/interview path/to/DESIGN.md  # Custom path
```

---

## Execution Steps

### 1. Read DESIGN.md

- If `$ARGUMENTS` specified: Use that path
- Otherwise: Use `docs/DESIGN.md`

Read file with Read tool and understand content.

### 2. Conduct Interview

Based on DESIGN.md content, conduct deep-dive interview using AskUserQuestion.

**Interview perspectives**:
- Technical implementation details
- UI/UX considerations
- Concerns and risks
- Trade-off decisions
- Edge case handling
- Error handling
- Performance requirements
- Security considerations

**Important rules**:
- **Don't ask obvious questions** - Skip what's already in DESIGN.md or clearly answered
- **Deep-dive** - Explore implicit assumptions and undecided matters, not surface-level confirmations
- **Continue** - Keep interviewing until user says "done" or sufficient information gathered

### Interview Flow

1. Review DESIGN.md content
2. Identify unclear points or areas needing detail
3. Ask with AskUserQuestion (1-2 questions at a time)
4. Record answers
5. Repeat if more questions
6. End when sufficient information gathered

### Question Example

```javascript
AskUserQuestion({
  questions: [
    {
      question: "[Specific question content]",
      header: "Technical Details",
      options: [
        { label: "Option A", description: "Description A" },
        { label: "Option B", description: "Description B" }
      ],
      multiSelect: false
    }
  ]
})
```

### 3. Write Specifications

After interview completion, append or update collected information to DESIGN.md.

Sections to append:

```markdown
## Specifications from Interview

### Technical Implementation
- [Collected details]

### UI/UX
- [Collected details]

### Concerns and Risks
- [Collected details]

### Decisions
- [Decisions made during interview]
```

---

## Exit Conditions

Exit when any of the following:
- User responds with "done", "complete", "OK", etc.
- Sufficient information gathered, no more questions
- Received "nothing specific" response 3 times consecutively

Exit message:

```
✓ Interview completed

Updated file:
- [DESIGN.md path]

Appended sections:
- [List of appended section names]
```
