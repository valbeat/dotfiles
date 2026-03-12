# Validation Checklist

## Pre-Development

- [ ] Defined 2-3 concrete use cases with expected inputs and outputs
- [ ] Identified which tools the skill needs (`allowed-tools`)
- [ ] Determined skill location (project `.claude/skills/` vs user `~/.claude/skills/`)
- [ ] Checked for existing similar skills to avoid duplication
- [ ] Classified into category (Document & Asset / Workflow Automation / MCP Enhancement)

## During Development

### Frontmatter

- [ ] Folder name is kebab-case (e.g., `create-skill`, not `createSkill`)
- [ ] Main file is named exactly `SKILL.md` (case-sensitive)
- [ ] Frontmatter delimiters are `---` on their own lines
- [ ] `name` field is present and matches folder name
- [ ] `description` follows WHAT + WHEN + triggers formula
- [ ] `description` is under 1024 characters
- [ ] No XML angle brackets (`<`, `>`) in frontmatter values
- [ ] `allowed-tools` lists only necessary tools (principle of least privilege)

### Content

- [ ] Instructions are clear and actionable (no vague guidance)
- [ ] Uses Markdown headers, not XML tags, for structure
- [ ] Includes at least one concrete example
- [ ] Has error handling guidance for common failure modes
- [ ] References are linked with `@references/filename.md` syntax
- [ ] No orphaned closing tags or broken markup
- [ ] SKILL.md body is under 500 lines (use progressive disclosure for larger content)
- [ ] File references are one level deep from SKILL.md (no nested reference chains)
- [ ] No time-sensitive information (or in "old patterns" section)
- [ ] Consistent terminology throughout (e.g., always "API endpoint", not mix of "URL"/"route")
- [ ] Only includes context Claude doesn't already know (concise is key)

### Naming

- [ ] Skill name does not contain "claude" or "anthropic"
- [ ] Skill name is descriptive and unambiguous

## Post-Development Testing

### Trigger Test

1. Say a trigger phrase from the description — does the skill activate?
2. Say a related but different phrase — does it still trigger appropriately?
3. Say something unrelated — does it correctly NOT trigger?

### Functional Test

1. Run the skill with typical input — does it produce expected output?
2. Run with edge case input — does it handle gracefully?
3. Run with no arguments — does it prompt or error clearly?

### Tool Integration Test

1. Verify all `allowed-tools` are sufficient for the skill's tasks
2. Confirm no tool calls fail due to missing permissions
3. Test with `@references/` links — do they resolve correctly?

## Post-Upload Monitoring

- [ ] Tested in a real conversation (not just the creation session)
- [ ] Trigger accuracy is acceptable (no false positives/negatives)
- [ ] Collected initial user feedback
- [ ] Documented any needed improvements for next iteration
