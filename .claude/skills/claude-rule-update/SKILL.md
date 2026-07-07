---
name: claude-rule-update
allowed-tools: Read, Edit
argument-hint: "[new rule or convention]"
description: >-
  Updates CLAUDE.md based on conversation learnings and new patterns.
  Use when updating project rules, adding conventions, or when the user
  says "update rules", "update CLAUDE.md", "add convention", "ルール追加", or "規約を更新".
---

# Update CLAUDE.md

## Context

- Current CLAUDE.md: @.claude/CLAUDE.md

## Your task

会話から得られた新しいルール・規約・ワークフローを CLAUDE.md に反映する。

## Steps

1. **候補の抽出**
   - `$ARGUMENTS` があればそれをルール候補とする
   - なければ、この会話の中から「今後も適用すべき合意事項」を抽出する
     （ユーザーからの修正指示、確立した手順、判明した制約など）
   - 一時的な作業内容・このタスク限りの事情は候補にしない

2. **重複チェック**
   - 既存の CLAUDE.md を読み、同じ内容・矛盾する内容のルールがないか確認する
   - 既存ルールと重複 → 追加しない（必要なら既存側を更新）
   - 既存ルールと矛盾 → どちらを残すかユーザーに確認する

3. **配置先の決定**
   - 既存セクションに属する内容 → そのセクションに追記
   - 属するセクションがない → 新しい `##` セクションを作成（既存の見出しスタイルに合わせる）

4. **記述ルール**
   - 1ルール = 1箇条書き。背景説明が必要な場合のみ1-2文補足する
   - 既存の言語（日本語）・トーン・フォーマットに合わせる
   - 「なぜ」が自明でないルールには理由を添える
   - Edit ツールで最小限の差分のみ変更する（無関係なセクションを書き換えない）

5. **報告**
   - 追加・変更したルールを引用してユーザーに報告する

## しないこと

- 会話に根拠のないルールの創作
- 既存ルールの無断削除・言い換え
- ファイル全体の再構成やリライト
