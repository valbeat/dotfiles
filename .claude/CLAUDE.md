# CLAUDE.md

## Development Philosophy

### Test-Driven Development (TDD)

- **t-wadaの推奨する進め方に従ってください**

- 原則としてテスト駆動開発（TDD）で進める
- 期待される入出力に基づき、まずテストを作成する
- 実装コードは書かず、テストのみを用意する
- テストを実行し、失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後、テストをパスさせる実装を進める
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

## Documentation Maintenance

- CLAUDE.md は継続的に更新する
- 新しいルールや手順が明確になった際に追記
- プロジェクト固有の知識やベストプラクティスを蓄積
- よく使うコマンドやショートカットも記録
- コード規約の変更や新しいツール導入時にも更新

## Important Notes

- 絶対に必要でない限りファイルを作成しない
- 常に新規ファイル作成より既存ファイルの編集を優先
- 要求された場合はテスト駆動開発（TDD）の原則に従う

## Model Selection Policy

原則: **「制約はコストではなくレート制限。5h 枠は繰り越されないので使い残しは損。7d に余剰がある限り、判断の質が効く場面から順に上のモデルへ回す」**

Max サブスクリプションなので従量課金は発生しない。効くのは 5h / 7d の枠だけ。

- **メインセッション**: Opus 4.8（起動時の既定モデル。settings.json では固定しない）。日常の対話・実装・設計はこれで行う
- **Fable 5** (`model: fable`): 判断が品質を決める場面に指定する
  - `/review` Step 4.5 のボーダーライン裁定
  - `/dev-workflow:spec` の DESIGN.md 設計レビュー
  - `code-reviewer` / `debugger` エージェント（`~/.claude/agents/`）
  - Orca orchestration のタスクで worker に `model: fable` を明示指定した場合
  - deep-research や Workflow の verify / judge ステージ
- **Sonnet / Haiku**: 探索・検索・整形・分類などのサブエージェント。orchestration の実装 worker は既定 `sonnet`
- **セキュリティ監査・脆弱性調査には Fable を使わない**: サイバー系の安全分類器による refusal 誤検知リスクがあるため、Opus 4.8 を使う（`/security-review`, `autoresearch:security` 等）。**この例外は budget tier に関わらず常に優先する**

### Budget Tier（自動格上げ）

余剰の判定は **7d のペース差のみ**で行う（5h は表示専用で判定に使わない）。

```bash
bash ~/.claude/skills/rate-pace/scripts/pace.sh tier   # -> L0 | L1 | L2
```

Claude Code 本体と同じ `GET /api/oauth/usage` を都度叩く（1回 0.4〜0.6 秒）。
**スキル起動時に1回だけ**呼ぶこと。

7d の1日ぶん = 100 / 7 = **14.29pt**。これが閾値の単位。

| tier | 条件 | 方針 |
|------|------|------|
| `L0` | 余剰 < +7pt、または取得失敗 | 現状維持。格上げしない |
| `L1` | 余剰 ≥ +7pt（約半日ぶんの貯金） | 補助ステップ（haiku → sonnet）を格上げ。Fable 同時起動上限 1 → 3 |
| `L2` | 余剰 ≥ +14pt（約1日ぶんの貯金） | 主ステップ（sonnet → opus）も格上げ。並列数を増やす。Fable 上限 5 |

余剰は `100 - 週末の最終消費率` を超えられない。週を 85% で終える使い方なら余剰は
最大でも +15pt までしか伸びないので、それより高い閾値は「厳しい」のではなく
**到達不能**になる。半日 / 1日 はその制約から逆算した値。

判定不能時の理由コードと窓長の前提は `~/.claude/skills/rate-pace/SKILL.md` を参照。

#### 各スキルの格上げ内容

| 対象 | `L0` | `L1` | `L2` |
|------|------|------|------|
| `/review` Step 2 Gather Context | haiku | sonnet | sonnet |
| `/review` Step 4 Confidence Scoring | haiku | sonnet | sonnet |
| `/review` Step 3 レビュアーのモデル | sonnet | sonnet | opus |
| `/review` Step 3 レビュアー体数 | 5 | 5 | 7 |
| `/review` Step 4.5 Fable 上限 | 1 | 3 | 5 |
| `/dev-workflow:spec` 設計レビュー（**予定・未実装**） | fable ×1 | fable ×1 | fable ×2（2体目は反証役） |
| Orca orchestration worker の既定モデル（`model:` 省略時のみ。**予定・未実装**） | sonnet | sonnet | opus |
| Orca orchestration 最大同時 worker（**予定・未実装**） | 3 | 4 | 6 |

「予定・未実装」の行は方針だけ先に決めたもので、tier を実際に読むのは現時点で `/review` だけ
（`/dev-workflow:spec` は `model: fable` 固定、orchestration スキルは tier を参照しない）。
実装するまで、これらの経路では tier に関係なく従来どおりの固定値で動く。

#### ルール

- **fail closed**: 判定できないときは `L0`。エラーは握りつぶして従来どおり続行する
- **明示指定が最優先**: `--model` やタスクファイルの `model:` があれば tier は無視する
- **1実行につき1回だけ読む**: スキル起動時に tier を確定し、ステップごとに再取得しない（実行中に揺れて設定が混ざるのを防ぐ）
- **格上げは上の表に載っている項目だけ**。「余ってそうだから他も上げる」はしない
- **ユーザー確認は取らない。報告は1行のみ**:
  `Budget tier: L1 (+18.3pt) — Step 2/4 を sonnet、Fable 上限 3`
- **絶対上限**: どの tier でも Fable は1回の実行で最大5エージェント、orchestration の同時 worker は最大6、`/review` のレビュアーは最大7
- **ループ内実行は L1 が上限**: `/review --brief`（`/dev-workflow:impl` から反復呼び出しされる）のような経路では L2 に上げない
- **格上げ対象外**: セキュリティ系（上記）、`suite-eval`（モデル指定が測定の独立変数のため自動格上げすると計測が壊れる）
- 格上げは自己制動する。消費すれば余剰が減り、次回の起動で自動的に降格する

## Claude Code settings.json の管理

`~/.claude/settings.json` と `~/.gemini/settings.json` は **untracked**。Claude Code（`/model`、`/config`、auto mode の `autoMode`、plugin install）と Orca（agent-status hook の注入）が実行時に書き込むため、稼働中ファイルをコミットすると勤務先プロジェクトの情報やマシン固有の状態が公開リポジトリに混入する。

- 意図した設定（permissions、自前 hook、plugins、UI の好み）は `darwin/claude.nix` に書く
- 反映は `nix run .#switch`。`darwin/claude/merge.jq` で稼働中ファイルにマージする（管理キーは上書き、名指ししないキーは温存、hooks は和集合）
- 手元で `/config` や `claude plugin install` で変えた管理キーは次の switch で戻る。switch 前に `make settings-diff` で戻る差分を確認し、残したいものは `darwin/claude.nix` に移す
- マージ規則を変えるときは `tools/tests/test-merge-settings.sh` を先に更新し、`make test` で確認する
- `model` は settings.json に固定しない方針のため `darwin/claude.nix` にも書かない

## Git Workflow

- **フィーチャーブランチの作成**: ベースブランチに直接コミットしない
- **コミットメッセージ**: Conventional Commit形式を使用（例: `feat:`, `fix:`, `chore:`）
- **PR作成コマンド**: 必ず以下のコマンドを使用
  ```bash
  gh pr create --assignee @me --draft 
  ```
- ドキュメントの言語はプロジェクトに合わせる
- 異なるタスクを始めるときはベースブランチに戻る
- **マージ済みPRへのpush禁止**: マージ済みのPRにはpushせず、新しいPRを作成する
- **loop時のworktree運用**: `--loop` や自律的に複数タスクを処理する場合は、worktreeで作業する。他のセッションがブランチを切り替えて競合するのを防ぐため

## Gemini CLI Integration

- ユーザーが「Geminiと相談しながら進めて」と指示した場合、Gemini CLIを呼び出して協業する
- 一度協業モードに入ったら、明示的な終了指示まで継続する
- 協業時のワークフロー:
  1. 最新のユーザー要件とこれまでの議論要約をプロンプトに含める
  2. `gemini <<EOF ... EOF` でGemini CLIを呼び出す
  3. Geminiの応答を「**Gemini ➜**」セクションに記載
  4. Claudeの分析・統合案を「**Claude ➜**」セクションに記載
  5. ユーザー入力またはプラン継続で1〜4を繰り返す
- 「Geminiコラボ終了」「ひとまずOK」等で通常モードに復帰

### エラーハンドリング

- Geminiからエラーが返された場合、エラー内容を分析し原因を特定する
- コンテキスト不足が原因の場合は、プロンプトを修正して再試行する
- 解決できない場合は、代替案を検討しユーザーに状況を報告する

### プロンプトテンプレート

Geminiへの標準的な指示形式：
```
gemini <<EOF
役割: [専門家の役割を定義]
タスク: [実行すべき具体的なタスク]
コンテキスト: [対象ファイルや関連情報]
制約条件: [遵守すべきルール]
出力形式: [期待する出力の形式]
EOF
```

### 役割分担

**Claude（オーケストレーター）**:
- ユーザーとの対話・要求のヒアリング
- 複雑なタスクの分解と計画立案
- Gemini / Codex への具体的な指示出し
- 結果の統合とユーザーへの報告
- 全体の進捗管理と軌道修正

**Gemini（検索・調査）**:
- コードベースの検索・調査
- ドキュメントやAPIの情報収集
- 依存関係・呼び出しチェーンの調査
- レビューや修正は担当しない

**Codex（レビュー・仕上げ）**:
- コードレビュー（バグ・ロジックエラー・セキュリティ）
- 修正・リファクタリングの実行
- 最終仕上げ・ポリッシュ

## `claude -p` (非対話モード) のサブスクリプション対象外化への対応

Claude Code Max サブスクリプションは `claude -p` / `claude --print` の呼び出しを対象外とし、API クレジットでの個別課金となる方針。dotfiles ではこれを抑制するため以下の運用ルールを設ける。

### 代替方針

- **Skill 内部で `claude -p` を呼ぶ場合** → Claude Code の **agent (Task ツールの `subagent_type` 指定)** で代替する。同一セッション内で実行されサブスク内で完結
- **Skill 外の script (Python/TS/sh) で `claude -p` を spawn する場合** → **codex CLI** (`codex exec`) に置換する。テキスト生成用途なら意味的に等価
- **claude の挙動自体を測る script** (skill-creator/run_eval.py, vercel/benchmark-runner.ts 等) は codex 置換できないため、`CLAUDE_ALLOW_PRINT=1` の環境変数で **明示 opt-in** したときのみ動作させる
- **対話モード** (`claude --dangerously-skip-permissions`、Orca worktree のエージェントターミナル経由) は対象外 → サブスク内のまま

### 予防策

- `~/.claude/hooks/guard.sh` が Bash ツールで `claude -p` / `claude --print` を BLOCK する
- 例外的に許可したい場合のみ `CLAUDE_ALLOW_PRINT=1` を環境変数に付与
- BLOCK ログは `~/.claude/logs/guard-YYYY-MM-DD.jsonl` に記録される

### プラグインキャッシュ向けパッチ運用

外部プラグイン (skill-creator / vercel) のキャッシュ配下に `claude -p` が残っているため、`tools/patches/apply.sh` で書き換える：

```bash
make patches    # または bash tools/patches/apply.sh
```

- 冪等動作。再実行しても二重適用しない（marker チェック）
- プラグインアップデートでパッチが上書きされたら再実行する
- 必要環境変数:
  - codex CLI 認証: `codex login` を済ませる、または `OPENAI_API_KEY` を設定
  - 明示 opt-in で API 課金を許容する場合は `CLAUDE_ALLOW_PRINT=1`

## Orca Integration

ワークスペースマネージャーは Orca（https://github.com/stablyai/orca）に一本化（2026-09、cmux / herdr から移行）。ワークスペース＝Orca 管理の git worktree（`~/orca/workspaces/<repo>/<name>`）。

### スキル

Orca バンドルスキルを Agent skills home（`~/.agents/skills/`）にインストール済み：

- `orca-cli` — worktree 作成・ターミナル送受信・エージェント spawn・埋め込みブラウザ・artifacts。Orca 管理状態に触るタスクでは raw `git worktree` やアドホック PTY より優先
- `orchestration` — タスク DAG・dispatch・inter-agent メッセージ・decision gate によるマルチエージェント協調（旧 cmux-team / herdr-team 相当）

追加は `orca skills install --skill <name> --agent universal`（computer-use / orca-emulator / orca-linear / orca-per-workspace-env 等）、更新は `orca skills update`。

### 環境の判定

```bash
# Orca 管理下の worktree なら ok:true
orca worktree current --json
```

CLI は `/Applications/Orca.app/Contents/Resources/bin/orca`（PATH は .zshrc で追加済み）。ランタイム未起動なら `orca open` を先に実行。

### 旧スキルからの対応

cmux-* / herdr-* スキルは 2026-09 に廃止（git 履歴から参照可）：

| 旧 (cmux / herdr) | Orca での代替 |
|---|---|
| `cmux` / `herdr-core`（トポロジ制御） | `orca-cli`（worktree / terminal / tab） |
| `cmux-agent` / `herdr-agent`（headless サブエージェント） | `orca worktree create --agent <id> --prompt "..."` |
| `cmux-team` / `herdr-team`（4層オーケストレーション） | `orchestration` スキル |
| `cmux-markdown`（Markdown ビューア） | `orca file open <path>`（markdown タブ） |
| `cmux-browser`（webview 自動化） | `orca tab/snapshot/click`（埋め込みブラウザ）、外部 Chrome は claude-in-chrome |
| `cmux-fork`（セッションフォーク） | `orca terminal create --command "claude --continue --fork-session"` |

### 注意

- Orca.app は手動配布。Homebrew の cask `orca` は plotly の別ツールなので **使わない**
- ユーザー設定は `~/Library/Application Support/orca/profiles/local-default/orca-data.json`（settings キー）、キーバインドは `~/.orca/keybindings.json`、リポジトリ単位の設定は各リポジトリの `orca.yaml`（scripts/issueCommand/defaultTabs/environmentRecipes/worktree。このリポジトリのルートに最小構成の例がある）
- orchestration は Settings → Orchestration（`nestedWorkerMaxDepth` 既定 1）。CLI が `run_required` を返せば有効。コーディネーターに使わせるには依頼に「監督して」「DAG で」「worker_done を待って」を**明示**する（「別のエージェントに渡して」は full handoff 扱いで Task は作られない）
- worker の `--model` / `--effort` は `--agent claude` 専用。Codex worker のモデルや reasoning effort を変えるときは worktree を作ってから `orca terminal create --command 'codex -c model_reasoning_effort="high"'` で起動する

### CLI が "too many levels of symbolic links" で失敗するとき

自動更新（2026-09-09 の 1.4.192 → 1.4.198 で発生）の直後に `Resources/bin/orca` が自己参照 symlink に置き換わることがある。原本は updater の zip に無傷で残っているので、そこから復元する（`/Applications` 配下の書き換えは auto mode の分類器が止めるため、ユーザーが `!` で実行）:

```bash
rm /Applications/Orca.app/Contents/Resources/bin/orca
unzip -p ~/Library/Caches/orca-updater/pending/Orca-<version>-arm64-mac.zip \
  Orca.app/Contents/Resources/bin/orca > /Applications/Orca.app/Contents/Resources/bin/orca
chmod 755 /Applications/Orca.app/Contents/Resources/bin/orca
orca status --json
```

復元前でも CLI の実体は直接実行できる: `ELECTRON_RUN_AS_NODE=1 /Applications/Orca.app/Contents/MacOS/Orca /Applications/Orca.app/Contents/Resources/app.asar.unpacked/out/cli/index.js <subcommand> --json`

上の書き戻しがユーザーのシェルでも `Operation not permitted` になる場合（macOS の App Management がバンドル内への書き込みを拒否する。2026-09-10 に発生。`rm` は通るが作成が通らない）は、バンドルを触らずに `~/.local/bin/orca`（PATH 上）へアプリパスを固定したランチャーを置く:

```bash
cat > ~/.local/bin/orca <<'SH'
#!/usr/bin/env bash
set -euo pipefail
APP_PATH="${ORCA_APP_PATH:-/Applications/Orca.app}"
ELECTRON="$APP_PATH/Contents/MacOS/Orca"
CLI="$APP_PATH/Contents/Resources/app.asar.unpacked/out/cli/index.js"
export ORCA_NODE_OPTIONS="${NODE_OPTIONS-}" ORCA_NODE_REPL_EXTERNAL_MODULE="${NODE_REPL_EXTERNAL_MODULE-}"
unset NODE_OPTIONS NODE_REPL_EXTERNAL_MODULE
ELECTRON_RUN_AS_NODE=1 exec "$ELECTRON" "$CLI" "$@"
SH
chmod 755 ~/.local/bin/orca && orca status --json
```

バンドル同梱のランチャー（`.zshrc` で PATH の先頭）が次の更新で直れば、そちらが自動的に優先される。そのとき `~/.local/bin/orca` は消してよい。また `unzip -p <zip> <member>` を貼り付けるときは zip パスの直後で改行が入ると全ファイルが標準出力へ流れるので、1 行で実行するか上のようにファイルにしてから走らせる。

## iTerm2 (plain) Integration

Orca を使わない**素の iTerm2** セッションでは、`iterm2` スキルでペイン操作を行う。バックエンドは `it2` CLI（iTerm2 Python API ラッパー）。

### 判定と使い分け

- Orca 管理下（`orca worktree current --json` が ok）→ **orca-cli / orchestration スキル**を優先
- Orca 外の素の iTerm2（`$TERM_PROGRAM=iTerm.app`）→ **`iterm2` スキル**

### 前提（初回のみ）

1. iTerm2 > Settings > General > Magic > **Enable Python API** を有効化
2. `it2` 導入: `uv tool install it2`
3. **Automation 権限の承認**: `it2 session list` を一度実行し、ダイアログを許可（cookie 取得のため）。確実な代替は iTerm2 の Scripts メニュー経由起動（`ITERM2_COOKIE` 自動注入）
4. 診断: `bash ~/.claude/skills/iterm2/scripts/it2-doctor.sh`（OK/NG と修復手順を出力）

### 要点

- 概念対応: Window=ウィンドウ / Workspace=タブ / Pane・Surface=session（分割ペイン）
- 現 session ID は `${ITERM_SESSION_ID##*:}` で取得（列挙不要）
- ブラウザ自動化は iTerm2 組み込みブラウザではなく **claude-in-chrome** を使う（WKWebView は外部制御口がなく、ネットワーク傍受も不可のため）
