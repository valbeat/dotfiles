# Description Writing Guide

## Formula

```
[What it does] + [When to use it] + [Trigger phrases]
```

A good description has three parts:

1. **WHAT**: One sentence explaining the skill's core function
2. **WHEN**: Conditions or scenarios that should activate this skill
3. **TRIGGERS**: Specific phrases users might say to invoke it

## Constraints

- Maximum 1024 characters
- No XML tags (`<`, `>`) in frontmatter
- Keep it scannable — Claude reads this to decide whether to invoke the skill

## Good Examples

```yaml
description: >-
  Generate a comprehensive code review for the current branch. Use when the
  user asks to "review my code", "check this PR", "audit changes", or
  "review for quality". Covers correctness, security, performance, and style.
```

```yaml
description: >-
  Create a new GitHub issue with structured labels and assignees. Use when
  user says "file an issue", "create a bug report", "open a feature request",
  or "track this problem".
```

## Bad Examples

```yaml
# Too vague — no WHEN or triggers
description: Helps with code

# Too long — buries the key info
description: >-
  This skill is designed to help users who want to perform code reviews.
  It can handle many different types of reviews including security reviews,
  performance reviews, and general code quality reviews. Users can invoke
  this skill whenever they need a review done on their code changes...

# Contains XML — will break frontmatter parsing
description: Use <review> tags to trigger this skill
```

## Tips

- Front-load the most important information
- Use concrete trigger phrases that match natural language
- Test: if you read only the description, would you know exactly when to use this skill?
- Include both formal ("generate a code review") and casual ("check my code") triggers
