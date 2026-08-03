---
name: worktree-gc
description: >-
  使い終わった git worktree を状態ベース（PR の state / 未コミット変更 / 未 push
  コミット）で判定して掃除する。cmux-team / herdr-team / cmux-agent が作った
  worktree の溜まりを解消する。Use when user says "worktree掃除", "worktree整理",
  "worktree GC", "worktreeが溜まってる", "ディスクを空けたい", or when a session
  notices many stale worktrees.
allowed-tools: Bash
argument-hint: "[--apply] [--size] [--json] [--merged-grace <日>] [--stale-open <日>] [--empty-grace <日>]"
---

# worktree GC

並列エージェント（cmux-team / herdr-team / cmux-agent）を回すと worktree が溜まる。
1 worktree あたり node_modules だけで 1.3GB 程度あり、放置すると数十 GB になる。
このスキルは**状態を見て**掃除する。所有者や作成時刻ではなく、消して安全かどうかで決める。

## 実行

対象リポジトリの中で実行する。既定は dry-run で、何も削除しない。

```bash
node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs            # 判定を表示
node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs --apply    # 実際に削除
node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs --size     # 容量も測る（数十秒）
```

**必ず dry-run を見せてからユーザーの承認を得て `--apply` すること。** 無断で削除しない。

## 判定基準

上から順に評価し、最初に一致した規則を適用する。

| 優先 | 条件 | 動作 |
|---|---|---|
| 1 | メインのチェックアウト、または `locked` | 触らない |
| 2 | 未コミット変更・未追跡ファイルあり | **削除しない**（人間に見せる） |
| 3 | PR なし かつ 未 push の独自コミットあり | **削除しない** |
| 4 | PR が OPEN、最終更新から 14 日未満 | 保持 |
| 5 | PR が OPEN、最終更新から 14 日以上 | `node_modules` だけ削除 |
| 6 | PR が MERGED / CLOSED から 3 日以上 | worktree 削除（MERGED ならブランチも） |
| 7 | PR なし、基準ブランチからの独自コミット 0 | 1 日で worktree 削除 |

閾値は `--merged-grace` / `--stale-open` / `--empty-grace` で変えられる。

## 設計上の前提（変更するときはここを壊さないこと）

- **「マージ済みか」を git の祖先判定で決めない。** squash / rebase merge ではブランチの
  コミットが基準ブランチの祖先にならないため、マージ済みでも「未マージ」に見える。
  PR の state（`gh pr list --head <branch> --state all`）を正とする。
- **worktree の削除とブランチの削除を分ける。** worktree を消してもコミット済みの作業は
  ブランチの ref に残り、失われるのは未コミットの変更だけ。ブランチを消すのは PR が
  MERGED のときだけ。CLOSED（未マージ）は成果がどこにも無いのでブランチを残す。
- **stash は消えない。** `refs/stash` は common dir にあり全 worktree で共有される。
- **`git worktree remove` に `--force` を使わない。** git 自身の「汚れていたら消さない」に守らせる。
- **ディレクトリの mtime を判定に使わない。** ビルド生成物で動く。最終コミット日時 /
  PR 更新日時 / worktree 管理ファイル（`gitdir`・`HEAD`）の mtime の最も新しいものを見る。
- **`index` の mtime は見ない。** `git status` が stat 情報を書き戻すため、様子を見るだけで
  「今触った」に化け、放置された worktree が現役に見えてしまう。
- **サイズは判定に使わない。** 表示専用なので既定では測らない（`du` が node_modules を
  走査して worktree 1 個あたり数秒かかる）。

## テスト

判定基準は 31 個のテストで固定してある。基準を変えるときはテストから直す。

```bash
node --test ~/.claude/skills/worktree-gc/scripts/worktree-gc.test.mjs
```

## 限界

- **登録されていない worktree ディレクトリは見えない。** `git worktree list` に出ないものは
  対象外（metadata だけ prune されてファイルが残った残骸など）。手で確認する。
- **ローカルブランチ単体の掃除はしない。** 消すのは worktree を持つブランチだけ。
  worktree を持たない古いブランチは対象外。
