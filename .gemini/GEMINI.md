# GEMINI.md

## Development Philosophy

### Test-Driven Development (TDD)

- Follow t-wada's recommended approach
- Always proceed with Test-Driven Development (TDD)
- Create tests based on expected input/output first
- Write tests only, no implementation code initially
- Run tests and confirm they fail
- Commit once tests are verified to be correct
- Then proceed with implementation to pass the tests
- Do not modify tests during implementation
- Continue fixing code until all tests pass

## Documentation Maintenance

- Continuously update GEMINI.md
- Add new rules and procedures as they become clear
- Accumulate project-specific knowledge and best practices
- Record frequently used commands and shortcuts
- Update when code conventions change or new tools are introduced

## Important Notes

- Never create files unless absolutely necessary
- Always prioritize editing existing files over creating new ones
- Follow TDD principles when requested

## Git Workflow

- **Feature Branch Creation**: Never commit directly to base branch
- **Commit Messages**: Use Conventional Commit format (e.g., `feat:`, `fix:`, `chore:`)
- **PR Creation Command**: Always use:
  ```bash
  gh pr create --assignee @me --draft 
  ```
- Match documentation language to project
- Return to base branch when starting different tasks

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Claude Code Integration

- ClaudeからGemini CLIが呼び出された際は、対話コンテキストを保ちながら協働する
- Claude Codeの基本的な使用方法:
  ```bash
  Claude <<EOF
  <質問・依頼内容>
  EOF
  ```
- 複数ターンにわたる協業時は、Claudeとの連携を意識して応答する
- Claudeから渡されるコンテキストを活用し、一貫性のある提案を行う