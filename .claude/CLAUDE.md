# CLAUDE.md

## Model Selection Policy

制約はコストではなくレート制限（Max サブスク、従量課金なし）。5h 枠は繰り越されないので
使い残しは損。7d に余剰がある限り、判断の質が効く場面から順に上のモデルへ回す。

- **メインセッション**: Opus 4.8（起動時の既定。settings.json には固定しない）
- **Fable 5**（`model: fable`）: 判断が品質を決める場面。`/review` のボーダーライン裁定、設計レビュー、`code-reviewer` / `debugger` エージェント、Workflow の verify / judge ステージ
- **Sonnet / Haiku**: 探索・検索・整形・分類のサブエージェント
- **セキュリティ監査・脆弱性調査には Fable を使わない**。サイバー系分類器の refusal 誤検知があるため Opus を使う（`/security-review`, `autoresearch:security`）。この例外は budget tier に関わらず常に最優先
- 7d の余剰による自動格上げ（budget tier）の閾値・格上げ表・ルールは `rate-pace` スキルが唯一の定義

## Git Workflow

- ベースブランチに直接コミットしない。フィーチャーブランチを切る
- コミットメッセージは Conventional Commit 形式（`feat:`, `fix:`, `chore:`）
- PR は `gh pr create --assignee @me --draft`（`/git-workflow:pr` も同じ既定）
- マージ済み PR には push しない。新しい PR を作る
- `--loop` や自律的な複数タスク処理は worktree で行う（他セッションのブランチ切替と競合させない）
- 異なるタスクを始めるときはベースブランチに戻る

## 環境

- ワークスペースマネージャーは Orca（worktree は `~/orca/workspaces/<repo>/<name>`）。Orca 管理下かは `orca worktree current --json` で判定し、管理下なら `orca-cli` / `orchestration` スキル、素の iTerm2 なら `iterm2` スキルを使う。ブラウザ自動化は claude-in-chrome
- Orca CLI は `~/.local/bin/orca`（ランチャー）。Homebrew cask の `orca` は plotly の別ツールなので使わない。設定ファイルの場所と CLI の復旧手順は memory の `reference_orca.md`
- Orca の orchestration を使わせるには依頼に「監督して」「DAG で」「worker_done を待って」を明示する（「別のエージェントに渡して」は full handoff 扱い）。worker の `--model` / `--effort` は `--agent claude` 専用
- `claude -p` / `--print` はサブスク対象外（API 課金）のため `hooks/guard.sh` が BLOCK する。Skill 内は Agent ツールの subagent、外部 script は `codex exec` で代替。この文字列を含むだけの `echo` / `grep` も BLOCK されるので、調査時は語を含めない
- Gemini との協業モードは `gemini` スキル、Codex への委譲は `codex` スキルに従う
