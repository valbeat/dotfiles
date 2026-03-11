# Skill Templates

## Minimal Template

```markdown
---
name: skill-name
description: >-
  [What it does]. Use when user says "[trigger 1]", "[trigger 2]",
  or "[trigger 3]".
allowed-tools: Read, Glob, Grep
---

## Your Task

[Clear description of what this skill does]

## Steps

1. [First step]
2. [Second step]
3. [Third step]

## Example

User: "[example input]"
Result: [expected output description]

## Error Handling

- If [condition], then [recovery action]
```

## Template with References

```markdown
---
name: skill-name
description: >-
  [What it does]. [When to use it]. Use when user says "[trigger 1]",
  "[trigger 2]", or "[trigger 3]".
allowed-tools: Read, Bash(specific-command:*), Glob, Grep
argument-hint: [description of expected arguments]
---

## Context

- Relevant state: !`command-to-check-state`
- Existing resources: !`ls relevant/directory/`

## Your Task

[Clear description of what this skill does]

For detailed guidance on [topic], see @references/topic-guide.md

## Steps

1. **[Phase name]**: [description]
   - Detail A
   - Detail B

2. **[Phase name]**: [description]
   - See @references/detailed-guide.md for specifics

3. **[Phase name]**: [description]

## Example

User: "/skill-name some-argument"
Result:
- [output 1]
- [output 2]

## Error Handling

- If [common error], then [recovery]
- If [edge case], then [fallback]

## Success Criteria

- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
```

## Frontmatter Field Reference

### Required

| Field | Description |
|-------|-------------|
| `name` | Skill identifier, must match folder name (kebab-case) |
| `description` | WHAT + WHEN + triggers (max 1024 chars, no XML) |

### Optional

| Field | Description |
|-------|-------------|
| `allowed-tools` | Comma-separated list of permitted tools |
| `argument-hint` | Describes expected arguments (shown in help) |
| `model` | Preferred model: `sonnet`, `opus`, or `haiku` |
| `user-invocable` | `false` to make skill only callable by Claude |
| `disable-model-invocation` | `true` to make skill only callable by user |
| `context` | `fork` to run in isolated subagent context |
