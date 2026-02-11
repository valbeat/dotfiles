---
allowed-tools: Read, Bash(ls:*), Glob, Grep
description: Create new Claude skills
---

## Context

- Current project skills: !`ls -la .claude/skills/`
- User skills available: !`ls -la ~/.claude/skills/ 2>/dev/null || echo "No user skills directory"`
- Project guidelines: !`head -50 .claude/CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found"`

### Skill Structure Specifications

**Directory Structure:**
```
.claude/skills/<skill-name>/
├── SKILL.md           # Main instructions (required)
├── reference.md       # Additional documentation (optional)
├── examples.md        # Usage examples (optional)
└── scripts/           # Supporting scripts (optional)
```

**Frontmatter Options:**
```yaml
---
allowed-tools: Bash(git add:*), Bash(git status:*)  # Restrict available tools
argument-hint: [commit message]                      # Describe expected arguments
description: Create a git commit                     # Brief skill explanation
model: sonnet                                        # Specify AI model (sonnet, opus, haiku)
disable-model-invocation: true                       # Only user can invoke (optional)
user-invocable: false                                # Only Claude can invoke (optional)
context: fork                                        # Run in isolated subagent (optional)
---
```

**Argument Handling:**
- `$ARGUMENTS`: All passed arguments as a single string
- `$1`, `$2`, etc.: Individual positional arguments

**Special Syntax:**
- `!command`: Execute bash command and include output in context
- `@file.md`: Reference file contents

**Skill Locations:**
- `.claude/skills/<name>/SKILL.md`: Project-specific skills
- `~/.claude/skills/<name>/SKILL.md`: Personal skills (available in all projects)
- Nested directories supported for namespacing

This meta-skill helps create other skills by:
1. Understanding the skill's purpose
2. Determining its category and pattern
3. Choosing skill location (project vs user)
4. Generating the skill directory and SKILL.md
5. Creating supporting resources
6. Updating documentation

## Your task

You are a skill creation specialist. Help create new Claude skills by understanding requirements, determining the appropriate pattern, and generating well-structured skills that follow established conventions.

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
## Before Creating: Study Similar Skills

1. **List existing skills in target directory**:
   ```bash
   # For project skills
   ls -la .claude/skills/

   # For user skills
   ls -la ~/.claude/skills/
   ```

2. **Read similar skills for patterns**:
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

## Phase 4: Skill Location

🎯 **Critical Decision: Where should this skill live?**

**Project Skill** (`.claude/skills/<name>/SKILL.md`)
- Specific to this project's workflow
- Uses project conventions
- References project documentation
- Integrates with project tools

**User Skill** (`~/.claude/skills/<name>/SKILL.md`)
- General-purpose utility
- Reusable across projects
- Personal productivity tool
- Not project-specific

Ask: "Should this be:
1. A project skill (specific to this codebase)
2. A user skill (available in all projects)?"

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
1. **Create Skill Directory and SKILL.md**
   - Create `.claude/skills/<skill-name>/` directory
   - Create `SKILL.md` with proper frontmatter
   - Generate content following established patterns
   - Include all required sections

2. **Create Supporting Files** (if needed)
   - Additional .md files for reference documentation
   - Scripts or templates in the skill directory
   - Example files for complex skills

3. **Update Documentation** (if project skill)
   - Add to skill list/guide
   - Update workflow documentation if applicable
   - Add to README if user-facing

4. **Test the Skill**
   - Create example usage scenarios
   - Verify argument handling
   - Check tool integration
</implementation_steps>

<creation_checklist>
Before finalizing:
- [ ] Studied similar skills in the category
- [ ] Skill follows naming conventions (kebab-case directory name)
- [ ] Includes proper frontmatter and context structure
- [ ] References relevant documentation
- [ ] Uses appropriate tools and patterns
- [ ] Includes review sections where needed
- [ ] Has clear examples like other skills
- [ ] Updates documentation appropriately
- [ ] Follows established patterns from similar skills
- [ ] Correct skill location (project vs user)
</creation_checklist>

<example_session>
User: "I need a skill to help run database migrations"

🔍 **Research**: Let me check existing utility skills...

*List existing skills: ls -la .claude/skills/*

I notice we have deployment and setup skills that might be similar.

🤔 **Question**: Can you tell me more about these database migrations?
- What database system are you using?
- Do you have existing migration tools/scripts?
- Should it handle rollbacks?
- Any pre/post migration checks needed?

User: "Using PostgreSQL with migrate tool, need to handle staging and production"

💡 **Category**: This is a Utility skill with environment modes.

🎯 **Location Question**: Should this be:
1. A project skill (specific to this project's database)
2. A user skill (useful for all your projects)

User: "Project skill - it uses our specific migration setup"

✅ Creating project skill: `.claude/skills/run-migrations/SKILL.md`

Generated skill:
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

1. **Skill Created**:
   - Location: {chosen location}
   - Name: {skill-name}
   - Category: {category}
   - Pattern: {specialized/generic}

2. **Resources Created**:
   - Supporting files: {list}
   - Documentation updates: {list}

3. **Usage Instructions**:
   - Command: `/{skill-name}`
   - Example: {example usage}

4. **Next Steps**:
   - Test the skill
   - Refine based on usage
   - Add to skill documentation
</final_output>
