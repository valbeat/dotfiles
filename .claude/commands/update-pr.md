---
allowed-tools: Bash(git:*), Bash(gh:*)
description: Update GitHub PR title and description based on changes
---

# Update PR

GitHub PRのタイトルと説明を、ベースブランチとの差分やコミットメッセージを基に自動更新する。

## Usage
```
Update PR #<pr-number>
```

## Steps

1. **PRの現在の情報を取得**
   ```bash
   # PR情報を取得
   gh pr view <pr-number> --json title,body,baseRefName,headRefName
   
   # PRブランチにチェックアウト
   gh pr checkout <pr-number>
   ```

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
   ```bash
   # Conventional Commit形式でタイトルを生成
   # 例: "feat: add user authentication system"
   #     "fix: resolve memory leak in data processor"
   #     "refactor: improve database query performance"
   ```

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
   ```bash
   # タイトルのみ更新
   gh pr edit <pr-number> --title "<new-title>"
   
   # 説明のみ更新
   gh pr edit <pr-number> --body "<new-body>"
   
   # タイトルと説明を同時に更新
   gh pr edit <pr-number> --title "<new-title>" --body "<new-body>"
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
- 既存の説明を完全に置き換えるため、手動で追加した情報は保持されない
- 必要に応じて `--editor` オプションで手動編集が可能
- コミットメッセージが適切に書かれていると、より良い説明が生成される