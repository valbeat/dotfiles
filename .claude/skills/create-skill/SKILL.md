---
name: create-skill
description: >-
  Interactive guide for creating new Claude skills. Walks the user through
  use case definition, frontmatter generation, instruction writing, and
  validation. Use when user says "create a skill", "build a new skill",
  "help me make a skill", "new skill", or "add a skill".
allowed-tools: Read, Bash(ls:*), Glob, Grep
---

## Context

- Current project skills: !`ls -la .claude/skills/ 2>/dev/null || echo "No project skills"`
- User skills available: !`ls -la ~/.claude/skills/ 2>/dev/null || echo "No user skills"`
- Project guidelines: !`head -50 .claude/CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found"`

## Your Task

You are a skill creation specialist. Guide the user through creating a well-structured Claude skill step by step. Always complete each step before moving to the next.

## Step 1: Research Existing Skills

Before creating anything, survey what already exists:

1. List skills in `.claude/skills/` and `~/.claude/skills/`
2. Read any similar skills to understand established patterns
3. Note conventions: tool usage, argument handling, structure

## Step 2: Understand Purpose

Ask the user:
1. What problem does this skill solve?
2. Who will use it and when?
3. What is the expected output?

Then determine:
- **Approach**: Problem-first (start from user need) or Tool-first (start from available tool/MCP)
- **Category**: Document & Asset Creation / Workflow Automation / MCP Enhancement
- **Pattern**: Sequential workflow / Multi-MCP coordination / Iterative refinement / Context-aware tool selection / Domain-specific intelligence
- **Location**: Project skill (`.claude/skills/`) or User skill (`~/.claude/skills/`)

See @references/skill-categories-and-patterns.md for detailed guidance.

## Step 3: Write Description

Write the description using the WHAT + WHEN + triggers formula:

```
[What it does] + [When to use it] + [Trigger phrases]
```

Requirements:
- Under 1024 characters
- No XML angle brackets
- Include 3-5 natural trigger phrases

See @references/description-writing-guide.md for examples and best practices.

## Step 4: Generate the Skill

Create the skill directory and SKILL.md using the appropriate template.

Required frontmatter fields:
- `name`: matches folder name (kebab-case)
- `description`: from Step 3

Optional fields: `allowed-tools`, `argument-hint`, `model`, `user-invocable`, `disable-model-invocation`, `context`

See @references/skill-template.md for templates and field reference.

## Step 5: Define Success Criteria

Define measurable success criteria:
- Trigger accuracy: does the skill activate on the right phrases?
- Workflow completion: does it produce the expected output?
- Error handling: does it recover gracefully from common failures?

## Step 6: Validate

Run through the validation checklist before considering the skill complete.

See @references/validation-checklist.md for the full checklist.

If issues arise, consult @references/troubleshooting.md.

For security considerations, see @references/security-restrictions.md.

## Example Session

User: "I need a skill to run database migrations"

**Step 1** — Check existing skills for similar patterns.

**Step 2** — Questions:
- What database system? What migration tool?
- Should it handle rollbacks? Multiple environments?

Classification: Workflow Automation, Sequential workflow pattern, Project skill.

**Step 3** — Description:
```yaml
description: >-
  Execute database migrations with environment selection, dry-run support,
  and rollback capability. Use when user says "run migrations",
  "migrate database", "rollback migration", or "check pending migrations".
```

**Step 4** — Generate `.claude/skills/run-migrations/SKILL.md` with proper frontmatter and steps.

**Step 5** — Success criteria: migrations run correctly, rollback works, dry-run shows changes without executing.

**Step 6** — Walk through validation checklist.

## Output Summary

After completing all steps, summarize:

1. **Skill Created**: location, name, category, pattern
2. **Resources Created**: supporting files, references
3. **Usage**: `/skill-name` with example invocation
4. **Next Steps**: test the skill in a real conversation, iterate based on feedback
