# Gemini Chat

Execute Gemini CLI and interact with it from Claude for AI-powered conversations and code assistance.

## Arguments

- `mode`: Interaction mode
  - `chat`: Interactive conversation mode (default)
  - `single`: Single prompt execution
  - `context`: Include file context in conversation
- `--model`: Gemini model to use (default: gemini-2.5-pro)
- `--prompt`: Initial prompt or question
- `--all-files`: Include all files in current directory as context
- `--yolo`: Auto-accept all suggested actions (use with caution)
- `--debug`: Enable debug mode for troubleshooting

## Basic Usage

### Start interactive chat
```bash
# Basic chat session
gemini

# With specific model
gemini -m gemini-2.5-pro

# With initial prompt
gemini -p "Help me understand this codebase"
```

### Single prompt execution
```bash
# Quick question without entering interactive mode
echo "What is the purpose of this function?" | gemini -p "$(cat utils.js)"

# Or using file input
cat README.md | gemini -p "Summarize this documentation"
```

### With file context
```bash
# Include all files in context
gemini --all_files -p "Review this codebase and suggest improvements"

# Include specific files via stdin
cat src/*.js | gemini -p "Find potential bugs in these files"
```

## Advanced Examples

### Code review session
```bash
# Review recent changes
git diff | gemini -p "Review these changes and suggest improvements"

# Review specific commit
git show HEAD | gemini -p "Explain what this commit does"
```

### Debug assistance
```bash
# Debug with error context
cat error.log | gemini -p "Help me understand and fix this error"

# Interactive debugging session
gemini --debug -p "I'm getting an undefined error in my React component"
```

### Project analysis
```bash
# Analyze project structure
find . -name "*.js" -o -name "*.ts" | head -20 | gemini -p "Analyze this project structure"

# Generate documentation
gemini --all_files -p "Generate API documentation for this codebase"
```

### YOLO mode (auto-accept actions)
```bash
# Automatically accept all suggested file changes
gemini --yolo -p "Refactor this code to use modern JavaScript"

# BE CAREFUL: This will make changes without confirmation
gemini --yolo --all_files -p "Update all imports to use ES6 modules"
```

## Integration with Claude

### Passing context between Claude and Gemini
```bash
# 1. First, use Claude to analyze the issue
# 2. Then use Gemini for a second opinion:
echo "Claude identified XYZ issue in the code. Can you verify and suggest alternatives?" | gemini

# Compare approaches
gemini -p "Claude suggested using approach A. What are the pros/cons compared to approach B?"
```

### Collaborative workflow
```bash
# Use Claude for planning, Gemini for implementation
gemini -p "Implement the feature that Claude designed in the previous conversation"

# Use Gemini for exploration, Claude for refinement
gemini --all_files -p "Explore possible optimizations" > optimizations.md
# Then review optimizations.md with Claude
```

## Session Management

### Save conversation
```bash
# Redirect output to file
gemini -p "Explain the architecture" > architecture-discussion.md

# Append to existing session
gemini -p "Continue from where we left off" >> architecture-discussion.md
```

### Resume conversation
```bash
# Include previous context
cat previous-session.md | gemini -p "Based on our previous discussion, let's continue with implementation"
```

## Troubleshooting

### Installation check
```bash
# Verify Gemini is installed
which gemini || echo "Gemini not found"

# Check version
gemini --version

# Test basic functionality
echo "Hello" | gemini -p "Respond with 'Hi' if you're working"
```

### Common issues

1. **Command not found**
   ```bash
   # Install via npm/volta
   volta install @google/gemini-cli
   # or
   npm install -g @google/gemini-cli
   ```

2. **Authentication errors**
   - Ensure you have valid credentials configured
   - Check environment variables for API keys

3. **Context too large**
   - Use specific file patterns instead of --all_files
   - Filter files before passing to Gemini

4. **Debug mode**
   ```bash
   # Enable debug output
   gemini --debug -p "Your prompt"
   
   # Check configuration
   gemini --help
   ```

## Best Practices

- Use `--all_files` sparingly - it can overwhelm the context
- Save important conversations for future reference
- Be specific with prompts for better results
- Use YOLO mode only when you're confident about the changes
- Combine with git to track changes made by Gemini
- Review Gemini's suggestions before accepting (unless in YOLO mode)

## Notes

- Gemini CLI requires authentication - ensure you're logged in
- Different models have different capabilities and token limits
- The CLI maintains conversation context within a session
- Use Ctrl+C to exit interactive mode
- Output can be piped to other commands for processing
- Consider using checkpointing (-c) for long sessions with file edits