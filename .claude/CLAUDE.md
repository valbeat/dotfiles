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
  - team 系スキル（cmux-team / herdr-team）でタスクファイルに `model: fable` を指定した場合
  - deep-research や Workflow の verify / judge ステージ
- **Sonnet / Haiku**: 探索・検索・整形・分類などのサブエージェント
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
| `/dev-workflow:spec` 設計レビュー | fable ×1 | fable ×1 | fable ×2（2体目は反証役） |
| team 系 既定モデル（`model:` 省略時のみ） | sonnet | sonnet | opus |
| team 系 最大同時 Conductor | 3 | 4 | 6 |

#### ルール

- **fail closed**: 判定できないときは `L0`。エラーは握りつぶして従来どおり続行する
- **明示指定が最優先**: `--model` やタスクファイルの `model:` があれば tier は無視する
- **1実行につき1回だけ読む**: スキル起動時に tier を確定し、ステップごとに再取得しない（実行中に揺れて設定が混ざるのを防ぐ）
- **格上げは上の表に載っている項目だけ**。「余ってそうだから他も上げる」はしない
- **ユーザー確認は取らない。報告は1行のみ**:
  `Budget tier: L1 (+18.3pt) — Step 2/4 を sonnet、Fable 上限 3`
- **絶対上限**: どの tier でも Fable は1回の実行で最大5エージェント、team の同時 Conductor は最大6、`/review` のレビュアーは最大7
- **ループ内実行は L1 が上限**: `/review --brief`（`/dev-workflow:impl` から反復呼び出しされる）のような経路では L2 に上げない
- **格上げ対象外**: セキュリティ系（上記）、`suite-eval`（モデル指定が測定の独立変数のため自動格上げすると計測が壊れる）
- 格上げは自己制動する。消費すれば余剰が減り、次回の起動で自動的に降格する

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

## iTerm2 (plain) Integration

cmux も herdr も使わない**素の iTerm2** セッションでは、`iterm2` スキルで cmux 互換のペイン操作を行う。バックエンドは `it2` CLI（iTerm2 Python API ラッパー）。

### 判定と使い分け

- `$CMUX_WORKSPACE_ID` あり → **cmux 系スキル**を優先
- cmux 外で `herdr status server` が running → **herdr 系スキル**
- どちらでもない素の iTerm2（`$TERM_PROGRAM=iTerm.app`）→ **`iterm2` スキル**

### 前提（初回のみ）

1. iTerm2 > Settings > General > Magic > **Enable Python API** を有効化
2. `it2` 導入: `uv tool install it2`
3. **Automation 権限の承認**: `it2 session list` を一度実行し、ダイアログを許可（cookie 取得のため）。確実な代替は iTerm2 の Scripts メニュー経由起動（`ITERM2_COOKIE` 自動注入）
4. 診断: `bash ~/.claude/skills/iterm2/scripts/it2-doctor.sh`（OK/NG と修復手順を出力）

### 要点

- cmux 概念との対応: Window=ウィンドウ / Workspace=タブ / Pane・Surface=session（分割ペイン）
- 現 session ID は `${ITERM_SESSION_ID##*:}` で取得（列挙不要）
- ブラウザ自動化は iTerm2 組み込みブラウザではなく **claude-in-chrome** を使う（WKWebView は外部制御口がなく、ネットワーク傍受も不可のため）
