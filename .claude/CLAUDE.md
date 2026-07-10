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
- **対話モード** (`claude --dangerously-skip-permissions`、cmux-agent 経由) は対象外 → サブスク内のまま

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

## cmux Integration

cmux 内で実行中の場合、cmux系スキルを活用してマルチペイン・マルチエージェント操作を行う。

### cmux 環境の判定

```bash
# 環境変数で判定（軽量）
[ -n "$CMUX_WORKSPACE_ID" ]

# ソケット接続で判定（確実）
cmux identify --json &>/dev/null
```

`CMUX_WORKSPACE_ID` が未設定、または `cmux identify` が失敗する場合は cmux 外で実行中。cmux系スキルは使用しない。

### 運用ルール

- cmux 内で実行中の場合、`cmux-*` スキル群を積極的に活用する
- 各スキルの description にトリガーフレーズが定義されているため、自然言語で自動選択される

## herdr Integration

ターミナルネイティブ（TUI + headless サーバ、SSH リモート対応）のワークスペースマネージャー。cmux の GUI が使えない／リモート・ヘッドレス環境では herdr 系スキルを使う。cmux 系スキルと1:1対応する `herdr-*` スキルを用意している。

### herdr / cmux の使い分け

- `CMUX_WORKSPACE_ID` が設定されている（= cmux 内）→ **cmux 系スキルを優先**
- cmux 外で、`herdr status server` が `status: running` を返す → **herdr 系スキルを使う**
- SSH リモート・ヘッドレス・軽量に済ませたい → herdr（`herdr --remote` でリモートアタッチ）

### スキル対応表

| herdr | cmux | 役割 |
|-------|------|------|
| `herdr-core` | `cmux` | トポロジ制御（workspace/tab/pane/worktree） |
| `herdr-agent` | `cmux-agent` | headless サブエージェント起動 |
| `herdr-fork` | `cmux-fork` | 現セッションを split pane にフォーク |
| `herdr-team` | `cmux-team` | 4層マルチエージェントオーケストレーション |
| （なし） | `cmux-browser` | herdr は webview 非対応 → `claude-in-chrome` MCP で代替 |
| （なし） | `cmux-markdown` | herdr は GUI ビューア非対応 |

### herdr の CLI 要点

- socket API 系サブコマンドは `{"id":..,"result":{..}}` 形状の JSON を返す。`jq` で `.result` 配下を参照
- エージェント完了検知は画面 grep ではなく **`herdr wait agent-status <pane> --status idle`**（per-pane の agent_status をネイティブ追跡）が信頼できる
- worktree は `herdr worktree create --branch … --base …` でブランチと workspace を一括生成
