---
name: dev
description: >-
  Issue番号を指定して、仕様把握→テスト計画→TDD実装→品質チェック→PR作成まで自律実行する。
  テスト計画のみユーザー承認を求める。「dev #N」「開発 #N」「issue対応」
  「fix issue」「resolve issue」で起動。
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, Agent
argument-hint: "<issue-number>"
---

## Your Task

Issue `$ARGUMENTS` の実装を以下のステップで自律実行する。

---

### Step 1: 仕様把握

#### 1-1. Issue 読解

1. `gh issue view $ARGUMENTS` で issue 本文を取得
2. コメントも確認: `gh issue view $ARGUMENTS --comments`
3. 要件を整理（実装内容・受け入れ条件・関連情報）

#### 1-2. コードベース調査

Explore Agent を並列起動して調査:

```
subagent_type: Explore
model: haiku
prompt: |
  以下の issue について、コードベースとの突合と既存パターン調査を行え。

  ## issue
  {issue 本文}

  検証項目:
  1. issue で言及されているファイル・関数が存在するか
  2. 同じレイヤーの既存実装パターン（命名・構造・エラーハンドリング）
  3. 関連するテストファイルの場所と構造
  4. 影響範囲の特定

  出力: 検証結果、関連ファイル一覧、参考既存実装パス
```

#### 1-3. 統合

Agent 結果を統合し、修正対象ファイル一覧を確定する。

**出力**: 仕様要約、修正対象ファイル一覧、参考既存実装パス

---

### Step 2: ブランチ作成

ベースブランチから feature ブランチを作成:

```bash
# ベースブランチを最新化してブランチ作成
git switch <base-branch> && git pull && git switch -c {type}/issue-{番号}-{description}
```

- bug fix → `fix/issue-{番号}-{概要}`
- feature → `feat/issue-{番号}-{概要}`

---

### Step 3: テスト計画

仕様からテストケースを導出。以下を決定:
- テストケース名と検証内容
- 粒度: 1テスト1検証概念
- 正常系・異常系・境界値の網羅性

以下のフォーマットでユーザーに提示:

```
### 対象: {テストファイル/クラス名}

| # | テストケース名 | 検証内容 |
|---|---------------|---------|
| 1 | {条件}_{振る舞い} | {何を検証するか} |
```

**AskUserQuestion で承認を得る。承認まで Step 4 に進まない。**

---

### Step 4: TDD実装

t-wada の TDD サイクルに従って実装:

1. **RED**: テスト計画に基づきテストを書く → 実行して失敗を確認
2. **GREEN**: テストをパスする最小限の実装を書く
3. **REFACTOR**: コードを整理（テストは変更しない）

各サイクルで:
- テストを先に書き、失敗を確認してからコミット
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

---

### Step 5: 品質チェック

プロジェクトの品質チェックを実行:

```bash
# プロジェクトに応じたチェックコマンドを実行
# 例: npm run lint && npm run typecheck && npm test
# 例: cargo clippy && cargo test
# 例: go vet ./... && go test ./...
```

- 最大3回ループ。通らなければユーザーに報告
- フォーマッター → リンター → 型チェック → テストの順で実行

---

### Step 6: PR作成

```bash
git push -u origin HEAD
gh pr create --assignee @me --draft \
  --title "{type}: {概要} (#$ARGUMENTS)" \
  --body "$(cat <<'EOF'
## Summary
{変更内容の要約}

## Test Plan
{テスト計画の要約}

Fixes #$ARGUMENTS
EOF
)"
```

---

## 注意事項

- テスト計画承認後は完全自律で実装を進める
- 品質チェック最大3回ループ、通らなければユーザーに報告
- ベースブランチへの直接コミット禁止
- CLAUDE.md のルールに従う
