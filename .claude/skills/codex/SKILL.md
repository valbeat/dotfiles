---
name: codex
allowed-tools: Bash(codex:*)
description: >-
  Executes Codex CLI (OpenAI) for code review, bug investigation, and
  architectural analysis. Use when consulting Codex, or when the user says
  "codex", "ask codex", or "codex review".
argument-hint: "<prompt>"
---

# Codex

## Context

- Current project: !`pwd`

## Your task

Codex CLI を使用してコードのレビュー・調査・分析を行い、結果をClaude側で統合・報告する。

## Execution

```bash
codex exec \
  --full-auto \
  --sandbox read-only \
  --cd "$(pwd)" \
  "$ARGUMENTS 確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

## Integration with Claude

Codexの出力を受け取った後：

```markdown
**Codex ➜** [Codexの分析結果の要約]

**Claude ➜** [Claudeの補足分析・統合案]
```

## Notes

- `--sandbox read-only` でファイル変更は行わない
- プロンプト末尾に「確認や質問は不要です」を必ず付加
- 未インストールの場合: `npm install -g @openai/codex`
