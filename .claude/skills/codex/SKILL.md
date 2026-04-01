---
name: codex
allowed-tools: Bash(codex:*)
description: >-
  Executes Codex CLI (OpenAI) for code review, fixes, and final polish.
  Use for reviewing changes, fixing issues, refactoring, or final finishing touches.
  Use when the user says "codex", "codex review", "仕上げ", or "codexで直して".
argument-hint: "<prompt>"
---

# Codex

## Context

- Current project: !`pwd`

## Your task

Codex CLI を使用してコードのレビュー・修正・最終仕上げを行い、結果をClaude側で統合・報告する。

## Execution

### Review (read-only)

```bash
codex exec \
  --full-auto \
  --sandbox read-only \
  --cd "$(pwd)" \
  "$ARGUMENTS 確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

### Fix / Polish (writable)

```bash
codex exec \
  --full-auto \
  --cd "$(pwd)" \
  "$ARGUMENTS 確認や質問は不要です。修正が必要な箇所は直接修正してください。"
```

### Common patterns

```bash
# Diff review
git diff | codex exec --full-auto --sandbox read-only --cd "$(pwd)" \
  "Review these changes for bugs, logic errors, and security issues."

# Fix specific issues
codex exec --full-auto --cd "$(pwd)" \
  "Fix the failing test in path/to/test.go and ensure all tests pass."

# Final polish
codex exec --full-auto --cd "$(pwd)" \
  "Review and polish the code: fix any remaining issues, improve naming, simplify logic."
```

## Integration with Claude

Codexの出力を受け取った後：

```markdown
**Codex ➜** [Codexのレビュー結果 or 修正内容の要約]

**Claude ➜** [Claudeの補足分析・最終確認]
```

## Notes

- レビュー時は `--sandbox read-only` を使用
- 修正・仕上げ時はサンドボックスなしで実行
- プロンプト末尾に「確認や質問は不要です」を必ず付加
- 未インストールの場合: `npm install -g @openai/codex`
