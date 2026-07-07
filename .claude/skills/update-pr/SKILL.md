---
name: update-pr
allowed-tools: Bash(git:*), Bash(gh:*)
disable-model-invocation: true
argument-hint: "[<pr-number>]"
description: >-
  Updates GitHub PR title and description based on current branch changes.
  Use when updating PRs, refreshing PR descriptions, or when the user says
  "update PR", "refresh PR", or "update PR description".
---

# Update PR

## Context

- Current repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repository"`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`
- Conventional commit format: Follow project standards

## Your task

GitHub PRのタイトルと説明を、ベースブランチとの差分やコミットメッセージを基に自動更新する。変更内容を分析して適切なPR説明を生成する。

## Usage
```
Update PR #<pr-number>
```

## Steps

1. **PRの現在の情報を取得**
   ```bash
   # PR情報を取得（既存本文は必ず保存してから作業する）
   gh pr view <pr-number> --json title,body,baseRefName,headRefName
   gh pr view <pr-number> --json body -q .body > /tmp/pr-body-old.md

   # PRブランチにチェックアウト
   gh pr checkout <pr-number>
   ```

   **重要**: `/tmp/pr-body-old.md` を Read で読み、人間が手動で書いたと思われる内容
   （チェック済みのチェックリスト、レビュー向けの補足、スクリーンショット等）を特定する。
   これらは新しい本文にそのまま引き継ぐこと。

2. **ベースブランチとの差分を分析**
   ```bash
   # ベースブランチの最新を取得
   git fetch origin
   
   # ベースブランチとの差分を確認
   git diff origin/<base-branch>...HEAD --stat
   
   # 変更されたファイルの詳細
   git diff origin/<base-branch>...HEAD --name-status
   ```

3. **コミットメッセージを収集**
   ```bash
   # PRに含まれるコミットを取得
   git log origin/<base-branch>..HEAD --oneline
   
   # 詳細なコミットメッセージを取得
   git log origin/<base-branch>..HEAD --format="- %s%n%b"
   ```

4. **変更内容を分析して要約**
   - 主要な変更の識別
   - 機能追加、バグ修正、リファクタリング等の分類
   - 影響範囲の特定
   - 技術的詳細の抽出

5. **PRタイトルの生成**

   以下のルールで決定する（スクリプトで機械生成しない）:
   1. **単一コミット**: そのコミットメッセージをそのまま使用
   2. **複数コミット・同一タイプ**: タイプを維持して変更全体を要約
   3. **複数コミット・異なるタイプ**: 優先順位 `feat` > `fix` > `refactor` > その他で決定
   4. Conventional Commit形式、50文字以内、英語
   5. 既存タイトルが上記ルールを満たしていれば変更しない

6. **PR説明文の生成**
   ```markdown
   ## Summary
   [変更の概要を1-3文で記載]
   
   ## Changes
   - [主要な変更点をリスト形式で]
   - [機能ごとにグループ化]
   
   ## Technical Details
   - [実装の詳細や技術的な判断]
   - [パフォーマンスへの影響]
   - [破壊的変更がある場合はその説明]
   
   ## Testing
   - [追加/変更されたテスト]
   - [テスト結果]
   
   ## Related Issues
   - Fixes #<issue-number> (該当する場合)
   - Related to #<issue-number>
   ```

7. **PRの更新**

   新しい本文は一時ファイルに書き出してから `--body-file` で渡す
   （インライン `--body` はクォート事故の原因になるため使わない）。
   heredoc の終端 `EOF` は必ず行頭（インデントなし）に置くこと:
   ```bash
   cat > /tmp/pr-body-new.md <<'EOF'
   [生成した本文（Step 1 で特定した手動記載の内容を含める）]
   EOF

   # タイトルと説明を更新
   gh pr edit <pr-number> --title "<new-title>" --body-file /tmp/pr-body-new.md
   ```

8. **更新内容の確認**
   ```bash
   # 更新後のPR情報を表示
   gh pr view <pr-number>
   
   # ブラウザで確認
   gh pr view <pr-number> --web
   ```

## オプション

### インタラクティブモード
```bash
# 生成された内容を確認してから更新
gh pr edit <pr-number> --title "<title>" --body "<body>" --editor
```

### Gemini連携モード
Gemini CLIと連携して、より詳細な説明を生成：
```bash
gemini <<EOF
役割: テクニカルライター
タスク: 以下のgit差分とコミットメッセージから、PRの説明文を生成
コンテキスト: 
- 差分: $(git diff origin/<base>...HEAD)
- コミット: $(git log origin/<base>..HEAD)
制約条件: 
- 技術的に正確であること
- 簡潔で分かりやすいこと
出力形式: Markdown形式のPR説明文
EOF
```

## 自動生成のガイドライン

### タイトル
- Conventional Commit形式を使用
- 50文字以内で要約
- 動詞で始める（add, fix, update, refactor等）

### 説明文
- **Summary**: 何を・なぜ変更したかを簡潔に
- **Changes**: 具体的な変更内容をリスト化
- **Technical Details**: 実装の詳細（必要に応じて）
- **Breaking Changes**: 破壊的変更がある場合は明記
- **Testing**: テスト内容や結果

## Notes

- PRの作成者でない場合、編集権限がない可能性がある
- **既存本文の手動記載（チェックリストの状態、補足、画像等）は必ず新しい本文に引き継ぐ**
- 必要に応じて `--editor` オプションで手動編集が可能
- コミットメッセージが適切に書かれていると、より良い説明が生成される
- プレースホルダー（`[...]`）を残したまま更新しない。書けないセクションは削除する