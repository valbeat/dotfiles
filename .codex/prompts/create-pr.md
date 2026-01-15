---
allowed-tools: Bash(git:*), Bash(gh:*)
description: Create PR from current branch with auto-generated content
---

# Create PR

## Context

- Current repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repository"`
- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`
- Git workflow: Follow CLAUDE.md conventions for PR creation

## Your task

現在のブランチから、差分とコミットメッセージを基にPRを自動作成する。**まず、プロジェクトのPRテンプレートが存在するかを確認し、存在する場合はそのフォーマットに従うことを最優先とする。**テンプレートがない場合は、変更内容を分析し、適切なタイトルと説明を生成してドラフトPRを作成する。

## Usage
```
Create PR
```

## Arguments (Optional)
- `--base <branch>`: ベースブランチを指定 (デフォルト: main/master)
- `--draft`: ドラフトPRとして作成
- `--no-draft`: ドラフトではなく通常のPRとして作成

## Steps

0. **PRテンプレートの確認（最優先）**
   ```bash
   # GitHubのPRテンプレートの存在確認（優先順位順）
   # 1. .github/PULL_REQUEST_TEMPLATE.md
   # 2. .github/pull_request_template.md
   # 3. .github/PULL_REQUEST_TEMPLATE/*.md
   # 4. docs/PULL_REQUEST_TEMPLATE.md

   **重要**: テンプレートが存在する場合は、以下のステップで生成する説明文をテンプレートの構造に合わせて調整すること。テンプレートのセクション構成、見出しスタイル、チェックリスト形式などを厳密に踏襲する。

1. **現在のブランチと状態を確認**
   ```bash
   # 現在のブランチ名を取得
   git branch --show-current
   
   # コミット状態を確認
   git status
   
   # リモートとの差分を確認
   git fetch origin
   git status -sb
   ```

2. **ベースブランチを特定**
   ```bash
   # デフォルトブランチを取得
   gh repo view --json defaultBranchRef -q .defaultBranchRef.name
   
   # または明示的に指定されたブランチを使用
   BASE_BRANCH=${base:-$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)}
   ```

3. **変更内容を分析**
   ```bash
   # ベースブランチとの差分統計
   git diff origin/$BASE_BRANCH...HEAD --stat
   
   # 変更ファイル一覧
   git diff origin/$BASE_BRANCH...HEAD --name-status
   
   # 変更の詳細
   git diff origin/$BASE_BRANCH...HEAD
   ```

4. **コミット履歴を収集**
   ```bash
   # コミット一覧
   git log origin/$BASE_BRANCH..HEAD --oneline
   
   # 詳細なコミットメッセージ
   git log origin/$BASE_BRANCH..HEAD --format="%s%n%b" | grep -v '^$'
   ```

5. **PRタイトルを生成**
   - 最新のコミットメッセージまたは複数コミットの要約
   - Conventional Commit形式を維持
   - 例:
     - 単一コミット: そのコミットメッセージを使用
     - 複数コミット: 主要な変更を要約
   ```bash
   # 最新コミットのメッセージを取得
   LATEST_COMMIT=$(git log -1 --format="%s")
   
   # コミット数を確認
   COMMIT_COUNT=$(git rev-list --count origin/$BASE_BRANCH..HEAD)
   
   # タイトル決定
   if [ $COMMIT_COUNT -eq 1 ]; then
     PR_TITLE="$LATEST_COMMIT"
   else
     # 複数コミットの場合は要約を生成
     PR_TITLE="feat: $(git log origin/$BASE_BRANCH..HEAD --format="%s" | head -1 | sed 's/^[^:]*: //')"
   fi
   ```

6. **PR説明文を生成**

   **PRテンプレートの優先**: Step 0 でPRテンプレートが見つかった場合は、そのテンプレートの構造を厳密に踏襲すること。テンプレートがない場合、または補足として、以下も参考にする：

   ```bash
   # 既存のマージ済みPRから学習（プロジェクトのPRスタイルを把握）
   gh pr list --state merged --limit 3 --json number,title,body
   ```

   **デフォルトの構造**（テンプレートがない場合）:
   ```markdown
   ## Summary
   [変更の概要を自動生成]

   ## Changes
   [コミットメッセージから主要な変更を抽出]
   - feat: 新機能の追加
   - fix: バグ修正
   - refactor: リファクタリング
   - docs: ドキュメント更新

   ## Commits
   [すべてのコミットをリスト]

   ## Files Changed
   - [変更されたファイルの要約]
   - Added: X files
   - Modified: Y files
   - Deleted: Z files

   ## Testing
   - [ ] ローカルでテスト済み
   - [ ] CI/CDパイプラインの確認

   ## Related Issues
   [コミットメッセージから Issue 番号を抽出]

   ## Architecture & Flow Diagram
   ```mermaid
   [変更内容に応じて以下のいずれかを自動生成]
   - Architecture changes (if any)
   - Data flow modifications
   - Component relationships
   - Process flows affected by the changes
   ```
   ```

6. **Mermaid図を自動生成**
   変更内容を分析して適切なMermaid図を自動生成する：
   - アーキテクチャ変更図
   - データフロー変更図
   - コンポーネント関係図
   - 影響を受けるプロセスフロー図

7. **ブランチをプッシュ**
   ```bash
   # 現在のブランチをリモートにプッシュ
   git push -u origin HEAD
   ```

8. **PRを作成**
   ```bash
   # CLAUDE.mdの指定に従ってPRを作成
   gh pr create \
     --title "$PR_TITLE" \
     --body "$PR_BODY" \
     --base "$BASE_BRANCH" \
     --assignee @me \
     --draft
   
   # または --no-draft オプションが指定された場合
   gh pr create \
     --title "$PR_TITLE" \
     --body "$PR_BODY" \
     --base "$BASE_BRANCH" \
     --assignee @me
   ```

9. **作成したPRを確認**
   ```bash
   # PRのURLを取得して表示
   PR_URL=$(gh pr view --json url -q .url)
   echo "PR created: $PR_URL"
   
   # ブラウザで開く（オプション）
   gh pr view --web
   ```

## 自動生成ルール

### タイトル生成
1. **単一コミット**: コミットメッセージをそのまま使用
2. **複数コミット（同一タイプ）**: タイプを維持して要約
3. **複数コミット（異なるタイプ）**: 最も重要な変更のタイプを使用
4. **優先順位**: feat > fix > refactor > その他

### 説明文生成
1. **Summary**: 変更の目的と影響を1-3文で要約
2. **Changes**: コミットメッセージをタイプ別にグループ化
3. **Technical Details**: 重要な実装詳細を抽出
4. **Breaking Changes**: "BREAKING CHANGE" を含むコミットを強調
5. **Issue References**: #番号 パターンを自動検出

## Gemini連携オプション

より詳細な説明を生成する場合：
```bash
gemini <<EOF
役割: PRレビュアー/テクニカルライター
タスク: 以下の情報からPRタイトルと説明を生成
入力:
- 差分: $(git diff origin/$BASE_BRANCH...HEAD)
- コミット: $(git log origin/$BASE_BRANCH..HEAD --format="%s%n%b")
- 変更ファイル: $(git diff origin/$BASE_BRANCH...HEAD --name-status)
要件:
- Conventional Commit形式のタイトル
- 変更の意図と影響を明確に説明
- レビュアーが理解しやすい構成
出力: 
- title: [PRタイトル]
- body: [PR説明文（Markdown）]
EOF
```

## エラーハンドリング

### よくある問題と対処
1. **未プッシュのコミット**: 自動的にプッシュ
2. **ブランチ名の重複**: 既存PRの確認と警告
3. **ベースブランチが古い**: fetchして最新化
4. **コンフリクト**: 警告を表示してユーザーに解決を促す

## Notes

- **最優先事項**: プロジェクトのPRテンプレートが存在する場合は、そのフォーマットを厳密に踏襲する
- 既存のマージ済みPRから学習し、プロジェクト固有のPRスタイルを把握する
- CLAUDE.md の Git Workflow セクションに従って `--assignee @me --draft` を使用
- デフォルトでドラフトPRとして作成（CLAUDE.mdの指定通り）
- PR作成後、必要に応じて手動でレビュー準備完了にする
- 既存のPRがある場合は警告を表示
- コミットメッセージが適切に書かれていることが前提
