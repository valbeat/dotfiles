---
name: gemini
allowed-tools: Bash(gemini:*)
argument-hint: "<prompt>"
description: >-
  Executes Gemini CLI for search, research, and information gathering.
  Use when searching codebases, looking up documentation, investigating issues,
  or when the user says "gemini", "ask gemini", "調べて", or "検索して".
---

# Gemini Search

## Context

- Current project: !`pwd`
- Collaboration patterns: See CLAUDE.md for Gemini integration workflow

## Your task

Gemini CLI を使用して検索・調査・情報収集を行い、結果をClaude側で統合・報告する。
Gemini の役割は検索と調査に限定する。レビューや修正は行わない。

## Execution

```bash
# CLAUDE.md standard prompt template
gemini <<EOF
役割: [調査・検索の専門家]
タスク: [検索・調査すべき内容]
コンテキスト: [対象ファイルや関連情報]
制約条件: [検索・調査のみ。レビューや修正提案は不要]
出力形式: [期待する出力の形式]
EOF
```

### Common patterns

```bash
# Codebase search with context
gemini -p "Search for all usages of X and explain the patterns"

# Documentation / API lookup
gemini -p "Find documentation about X and summarize key points"

# Issue investigation
gemini -p "Investigate how X is implemented and trace the call chain"

# Dependency analysis
gemini --all_files -p "List all files that depend on X and explain why"
```

## Integration with Claude

結果を以下の形式で報告:

```markdown
**Gemini ➜** [Geminiの調査結果]

**Claude ➜** [Claudeの分析・判断・次のアクション]
```

## Notes

- 未インストール時: `npm install -g @google/gemini-cli`
- `--all_files` は控えめに使用（コンテキスト過多に注意）
- レビューや修正はCodexに委譲すること