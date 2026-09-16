# CLAUDE.md

## Model Selection Policy

制約はコストではなくレート制限（サブスクのみ、従量課金なし）。枠は **Codex > Claude > Gemini** の順に大きい。
7d 枠は繰り越されないので、使い残しは損。

役割が決まっている作業:

- **指揮・対話（メインセッション）**: Claude Opus 5（settings.json には固定しない）
- **判断が品質を決める場面**: Fable 5.1（`model: fable`）。`/personal-tools:review` のボーダーライン裁定、設計レビュー、`code-reviewer` / `debugger` エージェント、Workflow の verify / judge ステージ
- **実装・修正・大量の読み取りの要約**: Codex（`/personal-tools:codex`、既定 gpt-5.6-terra。難所は sol / astra、機械的な作業は luna）
- **Web 検索・ドキュメント調査**: Gemini（`/personal-tools:gemini`、Antigravity CLI の `agy`。`gemini` CLI はサブスクで使えない）
- **探索・整形・分類のサブエージェント**: Sonnet 5 / Haiku 4.5
- **セキュリティ監査・脆弱性調査には Fable を使わない**。サイバー系分類器の refusal 誤検知があるため Opus を使う（`/security-review`, `autoresearch:security`）。この例外は枠の状況に関わらず常に最優先

どちらの枠でもできる作業（2 人目のレビュー、実装 worker、反証役）の振り分け（route）と、7d の余剰による自動格上げ（budget tier）は、`personal-tools:rate-pace` スキルが唯一の定義

## Git Workflow

- ベースブランチに直接コミットしない。フィーチャーブランチを切る
- コミットメッセージは Conventional Commit 形式（`feat:`, `fix:`, `chore:`）
- PR は `gh pr create --assignee @me --draft`（`/git-workflow:pr` も同じ既定）
- マージ済み PR には push しない。新しい PR を作る
- `--loop` や自律的な複数タスク処理は worktree で行う（他セッションのブランチ切替と競合させない）
- 異なるタスクを始めるときはベースブランチに戻る

## 環境

- ワークスペースマネージャーは Orca（worktree は `~/orca/workspaces/<repo>/<name>`）。Orca 管理下かは `orca worktree current --json` で判定し、管理下なら `orca-cli` / `orchestration` スキル、素の iTerm2 なら `personal-tools:iterm2` スキルを使う。ブラウザ自動化は claude-in-chrome
- Orca の orchestration を使わせるには依頼に「監督して」「DAG で」「worker_done を待って」を明示する（「別のエージェントに渡して」は full handoff 扱い）。worker の `--model` / `--effort` は `--agent claude` 専用
- Gemini との協業モードは `personal-tools:gemini`、Codex への委譲は `personal-tools:codex` スキルに従う
- 定期実行は Orca の automations を既定にする（`/schedule`・`/loop`・cron はユーザーが明示したときだけ）。組む・直すときは `personal-tools:orca-automation` スキルに従う
