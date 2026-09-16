---
name: orca-close-sessions
description: >-
  現在の Orca プロジェクト（repo）配下の worktree を横断して、自分以外のターミナル
  セッションを閉じる。稼働中のエージェントは閉じない。pty を食い潰した状態の復旧にも使う。
  Use when user says "他のセッションを閉じて", "セッション整理", "Orcaのセッション掃除",
  "ターミナルが溜まってる", "close other sessions", or when terminal creation fails with
  "cannot allocate any more pty devices".
allowed-tools: Bash
argument-hint: "[--apply] [--keep-shells] [--shell-idle-secs <秒>] [--json]"
---

# Orca セッション掃除

Orca で並列にエージェントを回すとターミナルが溜まる。1 ターミナル = 1 pty で、
枯渇すると `orca terminal create` が
`Your system cannot allocate any more pty devices` で失敗し、新しいセッションを
一切作れなくなる。このスキルは**現在のプロジェクト（repo）配下の worktree を横断して**
不要なターミナルを閉じる。

worktree そのものの掃除は [worktree-gc](../worktree-gc/SKILL.md) の担当。
このスキルは**ターミナルしか閉じない**。

## 実行

プロジェクト内のどこかで実行する。既定は dry-run で、何も閉じない。

```bash
node ~/.claude/skills/orca-close-sessions/scripts/orca-close-sessions.mjs            # 判定を表示
node ~/.claude/skills/orca-close-sessions/scripts/orca-close-sessions.mjs --apply    # 実際に閉じる
node ~/.claude/skills/orca-close-sessions/scripts/orca-close-sessions.mjs --keep-shells --apply
```

**必ず dry-run を見せてからユーザーの承認を得て `--apply` すること。**
稼働中の判定は後述のとおり保守的だが、閉じたエージェントの文脈は戻らない。

## 判定基準

ターミナル 1 つずつ、上から順に評価し、最初に一致した規則を適用する。

| 優先 | 条件 | 動作 |
|---|---|---|
| 1 | 自分自身（`ORCA_TERMINAL_HANDLE` または `ORCA_PANE_KEY` が一致） | **閉じない** |
| 2 | エージェントが `interrupted` | **閉じない** |
| 3 | エージェントの `state` が `done` | 閉じる |
| 4 | エージェントが居て `state` がそれ以外（`working`、未知の値、欠落） | **閉じない** |
| 5 | エージェント無しの素のシェル、`--keep-shells` 指定あり | **閉じない** |
| 6 | エージェント無しの素のシェル、最終出力から 60 秒未満 | **閉じない** |
| 7 | エージェント無しの素のシェル、それ以上放置 | 閉じる |

閾値は `--shell-idle-secs` で変えられる。

閉じた結果ターミナルが 0 になる worktree は、`dirty` / 未 push コミットを添えて
**一覧表示するだけ**で削除はしない。

## 設計上の前提（変更するときはここを壊さないこと）

- **`terminal wait --for tui-idle` をアイドル判定に使わない。** これは状態遷移を待つ
  コマンドで、すでに落ち着いている Claude Code の TUI に投げても 20 秒待って
  `timeout` を返す。`state: "done"` のエージェントで実測済み。アイドルの根拠は
  `orca worktree ps --json` の `agents[].state` から取る。
- **`CLOSABLE_AGENT_STATES` は許可リストであって拒否リストではない。** 実測できた値は
  `done` と `working` の 2 つだけで、Orca 側が新しい state を足す可能性がある。
  知らない値は全部「稼働中」に倒す。拒否リストにすると新しい state が来た日に
  作業中のエージェントを落とす。
- **`orca terminal close` に `--tab` を付けない。** `--tab` はタブ全体を落とすので、
  分割タブの中に「残す」と判定した稼働中ペインが同居していると巻き添えにする。
  ペイン単位で閉じれば、最後の 1 枚が消えた時点でタブも消える。
- **`@{upstream}` で未 push を数えない。** PR がマージされてリモートブランチが消えると
  remote-tracking ref も消え、`branch.*.merge` の設定が残っていても `@{upstream}` の
  解決に失敗する。「push 済みなのに未 push 扱い」になり、消せる worktree が
  「要確認」に化ける。`git rev-list --count HEAD --not --remotes` を使う。
- **orca CLI は失敗しても終了コード 0 を返すことがある。** `terminal wait` のタイムアウトが
  その例で、`{"ok": false, "error": {"code": "timeout"}}` を吐きながら exit 0 になる。
  必ず JSON の `ok` を読む。`$?` を信用しない。
- **worktree id は `<repoId>::<path>` の 2 部構成。** repoId だけに縮めない。
  プロジェクトで絞るときは `orca worktree list --repo id:<repoId>` を使う
  （クライアント側で全 worktree を舐めない。数百件ある）。
- **Orca の外から実行されたら `--apply` を拒否する。** `ORCA_TERMINAL_HANDLE` も
  `ORCA_PANE_KEY` も無い状態では自分自身を除外できず、自分を殺しうる。
  意図的に実行するなら `--force-no-self`。

## テスト

判定基準は 18 個のテストで固定してある。基準を変えるときはテストから直す。

```bash
node --test ~/.claude/skills/orca-close-sessions/scripts/orca-close-sessions.test.mjs
```

## 限界

- **close 経路は実機で未検証。** 検証用の使い捨てターミナルを作ろうとした時点で
  pty が枯渇しており（live terminal 260 個）、`orca terminal create` 自体が失敗した。
  分類ロジックと dry-run は実データで確認済み。初回の `--apply` は出力を見ながら行う。
- **素のシェルの「稼働中」は出力時刻でしか判断できない。** `npm run dev` のように
  出力が止まる常駐プロセスは、アイドルに見えて閉じられる。守りたいなら `--keep-shells`。
- **他プロジェクトのセッションには触らない。** 現在の repoId 配下だけが対象。
  マシン全体を掃除したいならプロジェクトごとに実行する。
- **Sleep は扱わない。** あとで再開したいワークスペースは、閉じるのではなく
  Orca の Sleep を使う。
