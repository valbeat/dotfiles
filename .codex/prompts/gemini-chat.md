---
allowed-tools: Bash(agy:*)
description: Ask Gemini via Antigravity CLI (agy) for web search, documentation lookup, and codebase research
---

# Gemini Chat (Antigravity CLI)

## Context

- Current project: !`pwd`

## Your task

Antigravity CLI（`agy`）で Gemini に調査・検索させ、結果を統合して報告する。
Gemini の役割は Web 検索、ドキュメント調査、コードベースの読み取り調査に限る。実装・修正・レビューは Codex 自身が行う。

Gemini CLI（`gemini`）は使わない。2026-06-18 以降、Google AI Pro/Ultra のサブスク枠では応答しない。

## Execution

- `--mode plan` を付ける（ファイルを書き換えさせない）
- コードベースを読ませるときは `--add-dir "$(pwd)"` を付け、プロンプトにも作業ディレクトリの絶対パスを書く（欠けると読み取りが拒否され、応答が空になる）
- プロンプトは `-p` の引数で渡し、`-p` は最後に置く。標準入力は読まない

```bash
agy --mode plan --add-dir "$(pwd)" --output-format json -p "$(cat <<PROMPT
作業ディレクトリ: $(pwd)（ファイルは必ずこの絶対パス配下で指定する）
タスク: [調べること]
制約条件: 調査のみ。確認や質問は不要
出力形式: [期待する形式]。根拠のファイルパスや URL を付ける
PROMPT
)" 2>/dev/null | jq -r '.status, (.denied_actions // "no denied actions"), .response'
```

Web 検索だけなら `--add-dir` は不要:

```bash
agy --mode plan -p "Find the official documentation about X and summarize key points with source URLs"
```

| 目的 | オプション |
|------|-----------|
| 重い調査 | `--model gemini-3.8-flash-high` |
| 速さ優先 | `--model gemini-3.8-flash-low` |
| 長時間 | `--print-timeout 15m` |

## Troubleshooting

| 出力 | 対処 |
|------|------|
| `Please sign in` | ユーザーに `agy` を対話起動してサインインしてもらう |
| `denied_actions` あり / `permission that headless mode cannot prompt for` | `--add-dir` と絶対パスの指示を確認。読み取り専用コマンドの許可リストは dotfiles の `darwin/claude.nix`（`antigravitySettings`） |
| quota / rate limit のエラー | Gemini の枠切れ。自分で調べる方法に切り替えてユーザーに伝える |

`--dangerously-skip-permissions` は使わない。
