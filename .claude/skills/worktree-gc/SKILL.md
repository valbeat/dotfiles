---
name: worktree-gc
description: >-
  使い終わった git worktree を状態ベース（PR の state / 未コミット変更 / 未 push
  コミット / Orca ワークスペースの status・作業中のエージェント・未読）で判定して掃除する。
  Orca（orca worktree create や自動化）が作ったワークスペースの溜まりを解消する。Use when user says "worktree掃除", "worktree整理",
  "worktree GC", "worktreeが溜まってる", "ディスクを空けたい", or when a session
  notices many stale worktrees.
allowed-tools: Bash
argument-hint: "[--apply] [--size] [--json] [--no-orca] [--merged-grace <日>] [--stale-open <日>] [--empty-grace <日>]"
---

# worktree GC

並列エージェントや Orca の自動化（`orca worktree create`、`new_per_run` の automation）を回すと worktree が溜まる。
1 worktree あたり node_modules だけで 1.3GB 程度あり、放置すると数十 GB になる。
このスキルは**状態を見て**掃除する。所有者や作成時刻ではなく、消して安全かどうかで決める。

## 実行

対象リポジトリの中で実行する。既定は dry-run で、何も削除しない。

```bash
node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs            # 判定を表示
node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs --apply    # 実際に削除
node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs --size     # 容量も測る（数十秒）
node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs --no-orca  # Orca の情報を使わない
```

Orca が起動していれば自動でワークスペース情報を読み、各行に `[status]` を表示する。
読めなければ git と PR の状態だけで判定し、その旨を出力の先頭に出す。

**必ず dry-run を見せてからユーザーの承認を得て `--apply` すること。** 無断で削除しない。

## 判定基準

上から順に評価し、最初に一致した規則を適用する。

| 優先 | 条件 | 動作 |
|---|---|---|
| 1 | メインのチェックアウト、または `locked` | 触らない |
| 2 | Orca: `existing` モードの自動化が使う固定ワークスペース | 触らない |
| 3 | Orca: ピン留め | 触らない |
| 4 | Orca: ターミナルのエージェントが作業中 | 触らない |
| 5 | 未コミット変更・未追跡ファイルあり | **削除しない**（人間に見せる） |
| 6 | Orca: 未読の出力あり | **削除しない**（最終レポートを読んでから） |
| 7 | どのリモートにも無いコミットあり（PR が MERGED でも） | **削除しない** |
| 8 | Orca: status が `completed`、または archived | 猶予なしで worktree 削除 |
| 9 | PR が OPEN、最終更新から 14 日未満 | 保持 |
| 10 | PR が OPEN、最終更新から 14 日以上 | `node_modules` だけ削除 |
| 11 | PR が MERGED / CLOSED から 3 日以上 | worktree 削除（MERGED ならブランチも） |
| 12 | PR なし、Orca: status が `todo` / `in-review` | 保持 |
| 13 | PR なし、基準ブランチからの独自コミット 0 | 1 日で worktree 削除 |
| 14 | PR なし、独自コミットあり（リモートにはある） | **削除しない** |

基準ブランチ（`main` など）を checkout した worktree は、消すときもブランチは残す。

閾値は `--merged-grace` / `--stale-open` / `--empty-grace` で変えられる。

## Orca の status で掃除を指示する

「もう要らない」と決めたワークスペースは、status を `completed` にしておけば次の GC で猶予なしに消える。

```bash
orca worktree set --worktree active --workspace-status completed --json
```

`in-progress` は Orca の既定値で、全ワークスペースに付いている。判定には使わない。

## 設計上の前提（変更するときはここを壊さないこと）

- **作業中の判定にターミナルの `lastOutputAt` を使わない。** 待機中の codex も画面を
  再描画し続けるため、終わって放置されたワークスペースが永遠に現役に見える。
  タイトル先頭のスピナー（codex は点字 `⠹` など、Claude Code は `◐◓◑◒`）で判定する。
  待機中のターミナルが開いているだけなら削除を妨げない（削除時に閉じる）。
- **Orca の情報は全部読めたときだけ使う。** ワークスペース一覧が truncated、自動化の
  一覧やターミナルが読めない、といった場合は Orca 情報を捨てて git だけで判定する。
  半端な情報で「守るべきもの」を見落とさないため。
- **Orca 管理下のワークスペースは `orca worktree rm` で消す。** ターミナルと Orca 側の
  記録も片付く。`orca worktree rm` は checkout 中のブランチを独自の基準で消そうとするので、
  ブランチを残す判定のときは先に `git switch --detach` してから渡す。
- **基準ブランチでは PR を探さない。** `gh pr list --head main` は無関係な古い PR を返す。

- **「マージ済みか」を git の祖先判定で決めない。** squash / rebase merge ではブランチの
  コミットが基準ブランチの祖先にならないため、マージ済みでも「未マージ」に見える。
  PR の state（`gh pr list --head <branch> --state all`）を正とする。
- **ただし未 push のコミットは PR の state より優先して守る。** PR がマージされた後に
  積んで push していないコミットは、「MERGED だからブランチも削除」で失われる。
  同名のリモートブランチの有無ではなく `git rev-list --count <ref> --not --remotes` で
  「どのリモートにも無いコミット」を数える（マージ後にリモートブランチが消えても、
  別ブランチに同じコミットがあっても正しく判定できる）。
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

判定基準は 59 個のテストで固定してある。基準を変えるときはテストから直す。

```bash
node --test ~/.claude/skills/worktree-gc/scripts/worktree-gc.test.mjs
```

## 限界

- **登録されていない worktree ディレクトリは見えない。** `git worktree list` に出ないものは
  対象外（metadata だけ prune されてファイルが残った残骸など）。手で確認する。
- **ローカルブランチ単体の掃除はしない。** 消すのは worktree を持つブランチだけ。
  worktree を持たない古いブランチは対象外。
