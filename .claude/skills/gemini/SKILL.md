---
name: gemini
allowed-tools: Bash(gemini:*)
argument-hint: "<prompt>"
description: >-
  Executes Gemini CLI for AI-powered conversations and code assistance.
  Use when consulting Gemini, starting collaboration, or when the user says
  "gemini", "ask gemini", "gemini chat", or "Geminiと相談".
---

# Gemini Chat

## Context

- Current project: !`pwd`
- Collaboration patterns: See CLAUDE.md for Gemini integration workflow

## Your task

Execute Gemini CLI for AI-powered conversations and code assistance. Follow the collaboration patterns defined in CLAUDE.md.

## Execution

```bash
# CLAUDE.md standard prompt template
gemini <<EOF
役割: [専門家の役割]
タスク: [具体的なタスク]
コンテキスト: [対象ファイルや関連情報]
制約条件: [遵守すべきルール]
出力形式: [期待する出力の形式]
EOF
```

### Common patterns

```bash
# Code review
git diff | gemini -p "Review these changes and suggest improvements"

# Single prompt with file context
gemini --all_files -p "Review this codebase"

# Interactive chat
gemini -p "Help me understand this codebase"
```

## Integration with Claude

結果を以下の形式で報告:

```markdown
**Gemini ➜** [Geminiの分析結果]

**Claude ➜** [Claudeの補足分析・統合案]
```

## Notes

- 未インストール時: `npm install -g @google/gemini-cli`
- `--all_files` は控えめに使用（コンテキスト過多に注意）
- `--yolo` は変更を確認なしで適用するため慎重に使用