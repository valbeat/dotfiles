# Security Restrictions

## Frontmatter Safety

- **No XML angle brackets** (`<`, `>`) in any frontmatter field — they break YAML parsing
- Use `>-` for multi-line strings in YAML to avoid injection risks
- Frontmatter is rendered into the system prompt — treat it as security-sensitive

## Naming Restrictions

- Skill names must **not** contain "claude" or "anthropic" (reserved names)
- Use kebab-case for folder names: `my-skill`, not `mySkill` or `my_skill`

## Prompt Injection Risk

The `description` field appears in Claude's system prompt. A malicious description could attempt to override Claude's behavior.

**Mitigations**:
- Keep descriptions factual and focused on WHAT/WHEN/triggers
- Do not include instructions or behavioral directives in the description
- All behavioral instructions belong in the SKILL.md body, not frontmatter

## Tool Permissions

- Use `allowed-tools` to restrict which tools the skill can access
- Follow the principle of least privilege — only grant tools the skill actually needs
- Avoid granting `Bash(*)` (unrestricted shell) unless absolutely necessary
- Prefer specific patterns: `Bash(git add:*)`, `Bash(npm test:*)`

## Sensitive Data

- Never hardcode secrets, API keys, or credentials in SKILL.md
- Use environment variables or external secret managers
- Be cautious with `!command` — output is included in the prompt context
- Avoid `!cat ~/.env` or similar commands that might expose secrets
