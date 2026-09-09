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
- Collaboration mode: see 協業モード below

## Your task

Gemini CLI を使用して検索・調査・情報収集を行い、結果をClaude側で統合・報告する。
Gemini の役割は検索と調査に限定する。レビューや修正は行わない。

## Execution

```bash
# 標準プロンプトテンプレート
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

## 協業モード

ユーザーが「Geminiと相談しながら進めて」と指示したら協業モードに入り、
「Geminiコラボ終了」「ひとまずOK」等の明示的な終了指示まで継続する。

1. 最新のユーザー要件とこれまでの議論要約をプロンプトに含める
2. `gemini <<EOF ... EOF` で Gemini CLI を呼び出す
3. 応答を「**Gemini ➜**」、Claude の分析・統合案を「**Claude ➜**」に記載
4. ユーザー入力またはプラン継続で 1〜3 を繰り返す

### エラーハンドリング

- エラーが返されたら内容を分析し原因を特定する
- コンテキスト不足が原因なら、プロンプトを修正して再試行する
- 解決できなければ代替案を検討し、ユーザーに状況を報告する

### 役割分担

- **Claude（オーケストレーター）**: ユーザーとの対話、タスク分解と計画、Gemini / Codex への指示、結果の統合と報告、進捗管理
- **Gemini（検索・調査）**: コードベース検索、ドキュメント・API の情報収集、依存関係・呼び出しチェーンの調査。レビューや修正は担当しない
- **Codex（レビュー・仕上げ）**: コードレビュー、修正・リファクタリング、最終仕上げ（`codex` スキル）

## Notes

- 未インストール時: `npm install -g @google/gemini-cli`
- `--all_files` は控えめに使用（コンテキスト過多に注意）
- レビューや修正はCodexに委譲すること