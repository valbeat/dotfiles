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

原則: **「探索・機械的作業は安いモデルに散らし、判断・裁定・長期自律実行だけ Fable に集約する」**

- **メインセッション**: Opus 4.8（settings.json の `"model": "opus"`）。日常の対話・実装・設計はこれで行う
- **Fable 5** (`model: fable`): 判断が品質を決める場面に限定して明示指定する
  - `/review` Step 4.5 のボーダーライン裁定（レビュー1回につき最大1エージェント）
  - `/dev-workflow:spec` の DESIGN.md 設計レビュー（同上）
  - `code-reviewer` / `debugger` エージェント（`~/.claude/agents/`）
  - Orca orchestration のタスクで worker に `model: fable` を明示指定した場合
  - deep-research や Workflow の verify / judge ステージ
- **Sonnet / Haiku**: 探索・検索・整形・分類などのサブエージェント。orchestration の実装 worker は既定 `sonnet`
- **セキュリティ監査・脆弱性調査には Fable を使わない**: サイバー系の安全分類器による refusal 誤検知リスクがあるため、Opus 4.8 を使う（`/security-review`, `autoresearch:security` 等）
- Fable のコストは Opus の2倍（$10/$50 per 1M tokens）。指摘ごと・ファイルごとに Fable を起動する構成にしない

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
- ユーザー設定は `~/Library/Application Support/orca/profiles/local-default/orca-data.json`（settings キー）、キーバインドは `~/.orca/keybindings.json`、リポジトリ単位の設定は各リポジトリの `orca.yaml`（scripts/issueCommand/defaultTabs/environmentRecipes/worktree）

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
