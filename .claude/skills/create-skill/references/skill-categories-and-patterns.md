# Skill Categories and Patterns

## Three Categories

### 1. Document & Asset Creation

Skills that produce artifacts — documents, configs, code files, reports.

**Examples**: generate PRD, create migration script, write test suite, build config file

**Key traits**:
- Clear output artifact
- Often uses templates
- Result is a file or document

### 2. Workflow Automation

Skills that orchestrate multi-step processes — CI/CD, deployment, review flows.

**Examples**: deploy to staging, run full test suite with reporting, PR review workflow

**Key traits**:
- Multiple sequential or parallel steps
- Often interacts with external tools (git, gh, npm)
- May require user confirmation at checkpoints

### 3. MCP Enhancement

Skills that leverage MCP servers for extended capabilities.

**Examples**: Figma-to-code, Slack notification, database query helper

**Key traits**:
- Depends on specific MCP server availability
- Bridges Claude with external services
- May need connection validation

## Five Patterns

### 1. Sequential Workflow

Steps execute in a fixed order. Each step depends on the previous.

```
Step 1 → Step 2 → Step 3 → Output
```

**Best for**: deployment pipelines, document generation, migration scripts

### 2. Multi-MCP Coordination

Combines multiple MCP servers or tools in a single workflow.

```
MCP-A (read) → Process → MCP-B (write) → Verify
```

**Best for**: cross-service automation, data sync, integration tasks

### 3. Iterative Refinement

Produces output, gets feedback, and improves in a loop.

```
Generate → Review → Refine → (repeat until satisfied)
```

**Best for**: code review, document drafting, design iteration

### 4. Context-Aware Tool Selection

Inspects the environment to decide which tools/approaches to use.

```
Detect context → Select strategy → Execute → Verify
```

**Best for**: polyglot tools, environment-adaptive scripts, smart defaults

### 5. Domain-Specific Intelligence

Encodes deep domain knowledge into structured guidance.

```
Gather input → Apply domain rules → Generate expert output
```

**Best for**: security audits, accessibility checks, performance optimization

## Problem-First vs Tool-First

### Problem-First (Recommended)

Start from the user's problem, then find the right tools.

> "Users need to review PRs efficiently" → design the workflow → select tools

### Tool-First

Start from available tools and build a skill around them.

> "We have Figma MCP" → build a Figma-to-code skill

**When to use Tool-First**: only when a new MCP server or tool creates an obvious capability that users will want.
