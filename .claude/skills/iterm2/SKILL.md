---
name: iterm2
description: >-
  Control iTerm2 topology and routing from the CLI — windows, tabs, split panes
  (sessions), focus, splits, send/run text, read/capture screen, and attention
  flash — via the `it2` wrapper over the iTerm2 Python API. cmux-compatible
  command vocabulary for the plain iTerm2 environment (cmux 外). Use when user
  says "split pane", "new tab", "focus session", "send to pane", "read screen",
  "iTermのペイン操作", "レイアウト変更", or needs deterministic placement in a
  multi-pane iTerm2 layout without cmux.
allowed-tools: Bash
---

# iTerm2 Core Control (cmux-compatible)

素の iTerm2（cmux 外）で、cmux と同じ語彙でトポロジ操作を行うためのスキル。
バックエンドは `it2` CLI（iTerm2 Python API のラッパー）。

**使い分け:** cmux 内（`$CMUX_WORKSPACE_ID` あり）なら `cmux` スキルを優先。
herdr 内なら `herdr-core`。どちらでもない素の iTerm2 でのみ本スキルを使う。

## Prerequisites（初回のみ）

使う前に必ず診断を実行し、[NG] があれば先に解消する。スクリプトはこの SKILL.md と
同じディレクトリの `scripts/it2-doctor.sh`（配備先は `~/.claude/skills/iterm2/scripts/`）:

```bash
bash ~/.claude/skills/iterm2/scripts/it2-doctor.sh
```

診断が確認する前提:
1. iTerm2 内で実行中（`$ITERM_SESSION_ID` あり）
2. `it2` CLI 導入済み（無ければ `uv tool install it2`）
3. iTerm2 Settings > General > Magic > **Enable Python API** が有効
4. **Automation 権限 / cookie**: 初回は `it2` を手で1回実行し、表示される
   「control iTerm2」ダイアログと Automation 許可を承認する。確実な代替は
   iTerm2 の Scripts メニュー経由起動（`ITERM2_COOKIE` が自動注入される）。

接続不能時は原因の 9 割がこの Automation 権限。**診断スクリプトの指示に従う**こと。

## Core Concepts（cmux との対応）

| cmux 概念 | iTerm2 の実体 | it2 での扱い |
|-----------|---------------|--------------|
| Window    | macOS ウィンドウ | `it2 window` |
| Workspace | タブ            | `it2 tab` |
| Pane / Surface | 分割された session | `it2 session` |

iTerm2 には cmux の Pane/Surface の二層区別が無く、**分割ペイン = session** の一層。

## Fast Start

```bash
# --- identify: 現在の呼び出しコンテキスト（cmux identify 相当） ---
echo "$ITERM_SESSION_ID"            # 形式: wNtNpN:UUID
echo "${ITERM_SESSION_ID##*:}"      # UUID 部分（session の一意 ID）

# --- list: トポロジ列挙 ---
it2 window list                     # cmux list-windows
it2 tab list                        # cmux list-workspaces
it2 session list                    # cmux list-panes

# --- create: 生成 ---
it2 tab new                         # cmux new-workspace
it2 window new                      # 新規ウィンドウ
it2 session split --vertical        # 右に分割（cmux new-split right）
it2 session split                   # 下に分割（cmux new-split down）

# --- focus/route: フォーカス移動 ---
it2 session focus <session-id>      # cmux focus surface
it2 tab select <index|id>           # タブ選択
it2 tab goto <index>                # インデックスでタブへ
it2 window focus <window-id>

# --- send/run: ペインへ入力 ---
it2 session send "text"             # 改行なし送信
it2 session run  "cmd"              # 改行付き実行（コマンド投入）
it2 session run "ls -la" --all      # 全 session に一括

# --- read/capture: 画面取得 ---
it2 session read                    # 画面テキスト取得（cmux read 相当）
it2 session capture -o /tmp/pane.png   # スクリーンショット保存（-o は必須）

# --- attention: 注意喚起（cmux trigger-flash 相当・依存ゼロ） ---
printf '\033]1337;RequestAttention=fireworks\a'   # 現在ペインをフラッシュ
# 別 session をフラッシュ: それを標的に上記エスケープを送る
it2 session send $'\033]1337;RequestAttention=fireworks\a' --session <id>

# --- move/close ---
it2 tab move                        # タブを新規ウィンドウへ分離
it2 session close                   # session を閉じる
it2 tab close ; it2 window close

# --- monitor: イベント購読 ---
it2 monitor activity                # session アクティビティ
it2 monitor output                  # 出力
it2 monitor prompt                  # シェルプロンプト（shell integration 要）
```

## Handle Model

- `it2 session list` / `tab list` / `window list` が ID を返す。以降の
  `focus`/`close`/`select` にはその ID か index を渡す。
- 現在 session の ID は環境変数 `${ITERM_SESSION_ID##*:}` で取れる（列挙不要）。

## 機能ギャップ（cmux との差分）

| cmux 機能 | iTerm2 での状況 |
|-----------|-----------------|
| `reorder-surface`（任意順の並べ替え） | tab は `goto/select/next/prev` のみ。任意位置への差し込みは非対応 |
| Surface 単位のブラウザ webview | 非対応。ブラウザ自動化は `claude-in-chrome` を使う |
| ネットワーク傍受 | iTerm2 側に手段なし（`claude-in-chrome` / Chromium 側で行う） |

## Error Handling

- `it2` が見つからない → `uv tool install it2` を案内（uv 前提。無ければ `pipx install it2`）。
- `Not running inside iTerm2 or Python API not enabled` → まず `scripts/it2-doctor.sh` を実行。
  多くは Automation 権限未許可。診断の修復手順に従う。
- ID 参照が無効 → `it2 session list` / `it2 window list` で有効な ID を再取得。
- 破壊的操作（`session close` / `tab close` / `window close`）は対象 ID を明示し、
  実行前に対象を `it2 session read` 等で確認してから行う。

## Related Skills

| Skill | When to Use |
|-------|-------------|
| [../cmux/SKILL.md](../cmux/SKILL.md) | cmux 内（`$CMUX_WORKSPACE_ID` あり）でのトポロジ制御 |
| [../herdr-core/SKILL.md](../herdr-core/SKILL.md) | herdr（TUI/ヘッドレス/リモート）でのトポロジ制御 |
| claude-in-chrome (MCP) | ブラウザ自動化（DOM/ネットワーク/コンソール）。iTerm2 組み込みブラウザは制御不可 |
