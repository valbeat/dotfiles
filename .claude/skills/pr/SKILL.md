---
name: pr
allowed-tools: Bash(git:*), Bash(gh:*)
disable-model-invocation: true
argument-hint: "[--base <branch>]"
description: >-
  Creates a GitHub pull request from the current branch with auto-generated
  title and description. Use when creating PRs, or when the user says
  "create PR", "open PR", or "make a pull request".
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

   スクリプトで機械的に生成せず、以下のルールで自分で決定する:

   1. **単一コミット**: そのコミットメッセージをそのままタイトルにする
   2. **複数コミット・同一タイプ**: そのタイプを維持し、変更全体を要約する
      （例: `fix(auth): resolve token refresh and session expiry issues`）
   3. **複数コミット・異なるタイプ**: 優先順位 `feat` > `fix` > `refactor` > その他 で
      最上位のタイプを使い、そのタイプに属する主要な変更を要約する
   4. Conventional Commit形式（`<type>(<scope>): <subject>`）、50文字以内、英語

6. **PR説明文を生成**

   **PRテンプレートの優先**: Step 0 でPRテンプレートが見つかった場合は、そのテンプレートの構造を厳密に踏襲すること。テンプレートがない場合、または補足として、以下も参考にする：

   ```bash
   # 既存のマージ済みPRから学習（プロジェクトのPRスタイルを把握）
   gh pr list --state merged --limit 3 --json number,title,body
   ```

   **デフォルトの構造**（テンプレートがない場合）:
   ```markdown
   ## Summary
   [変更の目的と影響を1-3文で。差分から読み取れる事実のみ書く]

   ## Changes
   [コミットメッセージをタイプ別にグループ化して箇条書き]

   ## Testing
   - [実際に実行したテスト・確認内容。未実施なら「未実施」と書く]

   ## Related Issues
   [コミットメッセージ・ブランチ名から #番号 を抽出。なければセクションごと省略]
   ```

   **記述ルール**:
   - プレースホルダー（`[...]`や`TBD`）を残したままPRを作成しない。書けないセクションは削除する
   - Mermaid図は「アーキテクチャ変更・データフロー変更・コンポーネント間の関係変更」が
     差分に含まれる場合のみ追加する。単純な修正・設定変更では追加しない
   - 生成した本文は一時ファイルに保存する:
   ```bash
   # 本文をファイルに書き出す（--body-file で使用。変数展開のクォート事故を防ぐ）
   cat > /tmp/pr-body.md <<'EOF'
   [生成した本文]
   EOF
   ```

7. **ブランチをプッシュ**
   ```bash
   # 現在のブランチをリモートにプッシュ
   git push -u origin HEAD
   ```

8. **PRを作成**
   ```bash
   # CLAUDE.mdの指定に従ってPRを作成（本文は Step 6 の /tmp/pr-body.md を使用）
   gh pr create \
     --title "<Step 5 で決定したタイトル>" \
     --body-file /tmp/pr-body.md \
     --base "$BASE_BRANCH" \
     --assignee @me \
     --draft

   # --no-draft オプションが指定された場合のみ --draft を外す
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

## 完了前チェックリスト

- [ ] PRテンプレートの有無を確認した（存在する場合はその構造に従った）
- [ ] タイトルは Conventional Commit形式・英語・50文字以内
- [ ] 本文にプレースホルダーが残っていない
- [ ] `--assignee @me --draft` を付けた（`--no-draft` 指定時を除く）
- [ ] 作成したPRのURLをユーザーに報告した
