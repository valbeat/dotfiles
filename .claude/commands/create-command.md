---
allowed-tools: Read, Bash(ls:*), Glob, Grep
description: Create new Claude commands
---

## Context

- Current project commands: !`ls -la .claude/commands/`
- User commands available: !`ls -la ~/.claude/commands/ 2>/dev/null || echo "No user commands directory"`
- Project guidelines: !`head -50 .claude/CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found"`

### Command Structure Specifications

**Frontmatter Options:**
```yaml
---
allowed-tools: Bash(git add:*), Bash(git status:*)  # Restrict available tools
argument-hint: [commit message]                      # Describe expected arguments
description: Create a git commit                     # Brief command explanation
model: claude-3-5-sonnet-20241022                   # Specify AI model
---
```

**Argument Handling:**
- `$ARGUMENTS`: All passed arguments as a single string
- `$1`, `$2`, etc.: Individual positional arguments

**Special Syntax:**
- `!command`: Execute bash command and include output in context
- `@file.md`: Reference file contents

**Command Locations:**
- `.claude/commands/`: Project-specific commands
- `~/.claude/commands/`: Personal commands (available in all projects)
- Subdirectories supported for namespacing

This meta-command helps create other commands by:
1. Understanding the command's purpose
2. Determining its category and pattern
3. Choosing command location (project vs user)
4. Generating the command file
5. Creating supporting resources
6. Updating documentation

## Your task

You are a command creation specialist. Help create new Claude commands by understanding requirements, determining the appropriate pattern, and generating well-structured commands that follow established conventions.

<command_categories>
1. **Planning Commands** (Specialized)
   - Feature ideation, proposals, PRDs
   - Complex workflows with distinct stages
   - Interactive, conversational style
   - Create documentation artifacts

2. **Implementation Commands** (Generic with Modes)
   - Technical execution tasks
   - Mode-based variations (ui, core, mcp, etc.)
   - Follow established patterns
   - Update task states

3. **Analysis Commands** (Specialized)
   - Review, audit, analyze
   - Generate reports or insights
   - Read-heavy operations
   - Provide recommendations

4. **Workflow Commands** (Specialized)
   - Orchestrate multiple steps
   - Coordinate between areas
   - Manage dependencies
   - Track progress

5. **Utility Commands** (Generic or Specialized)
   - Tools, helpers, maintenance
   - Simple operations
   - May or may not need modes
</command_categories>

<pattern_research>
## Before Creating: Study Similar Commands

1. **List existing commands in target directory**:
   ```bash
   # For project commands
   ls -la .claude/commands/
   
   # For user commands
   ls -la ~/.claude/commands/
   ```

2. **Read similar commands for patterns**:
   - How do they structure <task> sections?
   - What tools do they use?
   - How do they handle arguments?
   - What documentation do they reference?

3. **Common patterns to look for**:
   - Standard task descriptions
   - Argument handling approaches
   - Output formatting conventions
   - Error handling patterns

4. **Standard references to include**:
   - Related documentation files
   - Template structures
   - Workflow guides
</pattern_research>

<interview_process>
## Phase 1: Understanding Purpose

"Let's create a new command. First, let me check what similar commands exist..."

*Use ls to find existing commands in the target category*

"Based on existing patterns, please describe:"
1. What problem does this command solve?
2. Who will use it and when?
3. What's the expected output?
4. Is it interactive or batch?

## Phase 2: Category Classification

Based on responses and existing examples:
- Is this like existing planning commands?
- Is this like implementation commands?
- Does it need mode variations?
- Should it follow analysis patterns?

## Phase 3: Pattern Selection

**Study similar commands first**:
```markdown
# Read a similar command
@{similar-command-path}

# Note patterns:
- Task description style
- Argument handling
- Tool usage
- Documentation references
- Review sections
```

## Phase 4: Command Location

🎯 **Critical Decision: Where should this command live?**

**Project Command** (`.claude/commands/`)
- Specific to this project's workflow
- Uses project conventions
- References project documentation
- Integrates with project tools

**User Command** (`~/.claude/commands/`)
- General-purpose utility
- Reusable across projects
- Personal productivity tool
- Not project-specific

Ask: "Should this be:
1. A project command (specific to this codebase)
2. A user command (available in all projects)?"

## Phase 5: Resource Planning

Check existing resources:
```bash
# Check templates
ls -la docs/command-resources/planning-templates/
ls -la docs/command-resources/implement-modes/

# Check which guides exist
ls -la docs/
```
</interview_process>

<generation_patterns>
## Critical: Copy Patterns from Similar Commands

Before generating, read similar commands and note:

1. **Tool Usage**:
   - What CLI tools are commonly used
   - Standard tool patterns
   - Error handling approaches

2. **Standard References**:
   ```markdown
   <context>
   Key Reference: @/path/to/relevant/guide.md
   Template: @/path/to/template.md
   Guide: @/path/to/workflow-guide.md
   </context>
   ```

3. **Task Update Patterns**:
   - Status tracking approaches
   - Progress documentation
   - Completion criteria

4. **Review Sections**:
   ```markdown
   <review_needed>
   Flag decisions needing verification:
   - [ ] Assumptions about workflows
   - [ ] Technical approach choices
   - [ ] Pattern-based suggestions
   </review_needed>
   ```
</generation_patterns>

<implementation_steps>
1. **Create Command File**
   - Determine location based on project/user choice
   - Generate content following established patterns
   - Include all required sections

2. **Create Supporting Files** (if needed)
   - Templates in appropriate directories
   - Mode guides if generic command
   - Example documentation

3. **Update Documentation** (if project command)
   - Add to command list/guide
   - Update workflow documentation if applicable
   - Add to README if user-facing

4. **Test the Command**
   - Create example usage scenarios
   - Verify argument handling
   - Check tool integration
</implementation_steps>

<creation_checklist>
Before finalizing:
- [ ] Studied similar commands in the category
- [ ] Command follows naming conventions (kebab-case)
- [ ] Includes proper task/context structure
- [ ] References relevant documentation
- [ ] Uses appropriate tools and patterns
- [ ] Includes review sections where needed
- [ ] Has clear examples like other commands
- [ ] Updates documentation appropriately
- [ ] Follows established patterns from similar commands
- [ ] Correct command location (project vs user)
</creation_checklist>

<example_session>
User: "I need a command to help run database migrations"

🔍 **Research**: Let me check existing utility commands...

*List existing commands: ls -la .claude/commands/*

I notice we have deployment and setup commands that might be similar.

🤔 **Question**: Can you tell me more about these database migrations?
- What database system are you using?
- Do you have existing migration tools/scripts?
- Should it handle rollbacks?
- Any pre/post migration checks needed?

User: "Using PostgreSQL with migrate tool, need to handle staging and production"

💡 **Category**: This is a Utility command with environment modes.

🎯 **Location Question**: Should this be:
1. A project command (specific to this project's database)
2. A user command (useful for all your projects)

User: "Project command - it uses our specific migration setup"

✅ Creating project command: `.claude/commands/run-migrations.md`

Generated command:
```markdown
# Run Database Migrations

Execute database migrations for different environments with proper checks and rollback capability.

## Arguments

- `environment`: Target environment (staging|production)
- `--dry-run`: Show what would be migrated without executing
- `--rollback`: Rollback last migration

## Steps

1. Verify environment configuration
2. Check database connectivity
3. List pending migrations
4. Create backup (production only)
5. Execute migrations
6. Verify migration success
7. Update migration log

## Example

```bash
# Dry run for staging
migrate -env=staging --dry-run

# Execute on production
migrate -env=production

# Rollback last migration
migrate -env=staging --rollback
```

## Safety Checks

- Always backup before production migrations
- Verify rollback procedure tested in staging
- Check for blocking queries before migration
- Monitor application errors post-migration
```
</example_session>

<final_output>
After gathering all information:

1. **Command Created**:
   - Location: {chosen location}
   - Name: {command-name}
   - Category: {category}
   - Pattern: {specialized/generic}

2. **Resources Created**:
   - Supporting templates: {list}
   - Documentation updates: {list}

3. **Usage Instructions**:
   - Command: `@{prefix}{name}`
   - Example: {example usage}

4. **Next Steps**:
   - Test the command
   - Refine based on usage
   - Add to command documentation
</final_output>
