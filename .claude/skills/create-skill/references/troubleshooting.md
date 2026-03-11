# Troubleshooting

## Skill Won't Upload / Parse Errors

**Symptoms**: Skill doesn't appear in the skill list, or frontmatter values are garbled.

**Common causes**:
- Frontmatter delimiters (`---`) missing or malformed
- XML angle brackets (`<`, `>`) in description or other frontmatter fields
- YAML syntax error (unescaped colons, missing quotes on special characters)
- File not named exactly `SKILL.md` (case-sensitive)

**Fix**: Validate frontmatter manually. Use `>-` for multi-line description. Escape special YAML characters.

## Skill Doesn't Trigger

**Symptoms**: Saying trigger phrases doesn't activate the skill.

**Common causes**:
- Description is too vague — Claude can't match intent
- Missing trigger phrases in description
- Another skill's description is a closer match

**Fix**: Add explicit trigger phrases to description. Test with exact phrases. Check competing skills.

## Skill Triggers Too Often (False Positives)

**Symptoms**: Skill activates on unrelated requests.

**Common causes**:
- Description is too broad ("helps with code")
- Trigger phrases overlap with common requests
- Missing "Use when" qualifier to narrow scope

**Fix**: Add "Use when" conditions. Make trigger phrases more specific. Add "Do NOT use when" if needed.

## Instructions Not Followed

**Symptoms**: Skill activates but doesn't follow the defined steps.

**Common causes**:
- Instructions are too vague or ambiguous
- Too many instructions (context overload)
- Conflicting instructions between skill and CLAUDE.md
- Missing concrete examples

**Fix**: Simplify instructions. Add explicit examples of expected behavior. Use numbered steps. Move detailed reference to `@references/` files.

## Context Too Large

**Symptoms**: Skill works but is slow, or referenced files aren't fully loaded.

**Common causes**:
- Too many `@references/` files loaded eagerly
- Referenced files are very large
- `!command` outputs are verbose

**Fix**: Split into smaller reference files. Only `@reference` what's needed per step. Use progressive disclosure — load details only when that step is reached.

## Arguments Not Parsed

**Symptoms**: `$ARGUMENTS`, `$1`, `$2` are empty or wrong.

**Common causes**:
- User invoked skill without arguments
- Argument format doesn't match `argument-hint`

**Fix**: Add fallback behavior when arguments are empty. Document expected format in `argument-hint`. Add examples showing correct invocation.
