# Create New Command

Create a new command template in the .claude/commands directory.

## Steps

1. Determine the command name and purpose
2. Create a new markdown file in `.claude/commands/` directory
3. Use the following template structure:

```markdown
# [Command Name]

[Brief description of what this command does]

## Steps

1. [First step]
2. [Second step]
3. [Additional steps as needed]

## Example

```bash
[Example command or code snippet]
```

## Notes

- [Any important notes or considerations]
- [Additional tips or warnings]
```

## Example Usage

To create a new command for database migrations:

```bash
# Create the file
touch .claude/commands/run-migrations.md

# Edit with the template
# Add content following the structure above
```

## Command Naming Convention

- Use kebab-case for file names (e.g., `deploy-to-production.md`)
- Keep names descriptive but concise
- Group related commands with common prefixes (e.g., `test-unit.md`, `test-integration.md`)