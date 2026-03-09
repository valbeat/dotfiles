---
allowed-tools: Bash(codex:*)
description: Execute Codex CLI for code review, bug investigation, and architectural analysis
argument-hint: "<prompt>"
---

# Codex

## Context

- Current project: !`pwd`
- Codex CLI: OpenAI Codex CLI for code assistance and review

## Your task

Codex CLI（OpenAI）を使用してコードのレビュー・調査・分析を行う。
Codexはサブエージェントとして活用し、結果をClaude側で統合・報告する。

## Trigger

- `codex`, `codexと相談`, `codexに聞いて`, `コードレビュー（codex）`

## Arguments

- `$ARGUMENTS`: Codexに送信するプロンプト（必須）

## Execution

```bash
codex exec \
  --full-auto \
  --sandbox read-only \
  --cd "$(pwd)" \
  "$ARGUMENTS 確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

### Options

| Option | Description |
|--------|-------------|
| `--full-auto` | 自動実行モード（確認なし） |
| `--sandbox read-only` | 読み取り専用サンドボックス |
| `--cd <dir>` | 実行ディレクトリを指定 |

## Use Cases

### 1. コードレビュー
```bash
codex exec --full-auto --sandbox read-only --cd "$(pwd)" \
  "このプロジェクトのコードをレビューして改善点を指摘してください。確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

### 2. バグ調査
```bash
codex exec --full-auto --sandbox read-only --cd "$(pwd)" \
  "認証処理でエラーが発生している原因を調査してください。確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

### 3. アーキテクチャ分析
```bash
codex exec --full-auto --sandbox read-only --cd "$(pwd)" \
  "このプロジェクトの構造を説明し、改善提案をしてください。確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

### 4. リファクタリング提案
```bash
codex exec --full-auto --sandbox read-only --cd "$(pwd)" \
  "技術的負債を特定し、リファクタリング計画を提案してください。確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

### 5. デザイン相談
```bash
codex exec --full-auto --sandbox read-only --cd "$(pwd)" \
  "UIデザイナー視点でこのプロジェクトのUIを評価してください。確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。"
```

## Integration with Claude

Codexの出力を受け取った後、Claudeは以下の形式で結果を報告する：

```markdown
**Codex ➜** [Codexの分析結果の要約]

**Claude ➜** [Claudeの補足分析・統合案]
```

## Notes

- Codexは `--sandbox read-only` で実行するため、ファイル変更は行わない
- 長時間実行される場合があるが、ターミナル出力でリアルタイムに進捗確認可能
- プロンプト末尾に「確認や質問は不要です」を必ず付加し、確認待ちを防止する
- Codex CLIが未インストールの場合: `npm install -g @openai/codex`
