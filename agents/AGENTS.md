# AGENTS.md（全プロジェクト共通）

プロジェクトに AGENTS.md / CLAUDE.md / GEMINI.md があれば、そちらの指示を優先する。

このファイルは 3 つのエージェントで共有している実体で、`~/.claude/CLAUDE.md`・`~/.codex/AGENTS.md`・`~/.gemini/GEMINI.md` はすべてこれを指す。
**「共通」と自分の節だけに従う。他のエージェント向けの節は、相手が何を担当するかを知るための情報であって、自分への指示ではない。**

置くのは「ツールを選ぶ前に知っている必要があり、間違えると取り返しがつかないこと」だけ。手順と細目はスキル側にある。

## 共通

### 役割分担

サブスクで使う AI エージェントは Claude Code・Codex・Antigravity（Gemini）の 3 つ。
制約はコストではなくレート制限で、従量課金の API キーは使わない。枠は **Codex > Claude > Gemini** の順に大きく、7d 枠は繰り越されないので使い残しは損。

- **Claude Code**: 指揮・対話・設計判断
- **Codex**: 実装・修正・レビュー・大量の読み取りの要約
- **Antigravity**: Web 検索・ドキュメント調査・コードベースの読み取り調査

### Git ワークフロー

- ベースブランチに直接コミットしない。フィーチャーブランチを切る
- コミットメッセージは Conventional Commit 形式（`feat:`, `fix:`, `chore:`）
- PR は `gh pr create --assignee @me --draft`
- マージ済み・クローズ済みの PR のブランチには push しない。新しいブランチと PR を作る
- 強制 push しない。pre-commit フック（lefthook 等）を無効化しない
- 異なるタスクを始めるときはベースブランチに戻る

## Claude Code

### モデル方針

- **指揮・対話（メインセッション）**: Opus 5。`settings.json` には固定しない
- **判断が品質を決める場面**: Fable 5.1。設計レビュー、`/personal-tools:review` のボーダーライン裁定、`code-reviewer` / `debugger`、Workflow の verify / judge ステージ
- **探索・整形・分類のサブエージェント**: Sonnet 5 / Haiku 4.5
- **セキュリティ監査・脆弱性調査に Fable を使わない**。サイバー系分類器の refusal 誤検知があるため Opus を使う（`/security-review`, `autoresearch:security`）。この例外は枠の状況に関わらず常に最優先
- 枠の余剰による格上げ（budget tier）と Claude / Codex の振り分け（route）は `personal-tools:rate-pace` が唯一の定義

### 環境

- ワークスペースマネージャーは Orca（worktree は `~/orca/workspaces/<repo>/<name>`）。Orca 管理下かは `orca worktree current --json` で判定し、管理下なら `orca-cli` / `orchestration` スキル、素の iTerm2 なら `personal-tools:iterm2` スキルを使う
- orchestration を使わせるには依頼に「監督して」「DAG で」「worker_done を待って」が要る（「別のエージェントに渡して」は full handoff 扱い）。worker の `--model` / `--effort` は `--agent claude` 専用
- 定期実行の既定は Orca の automations。`/schedule`・`/loop`・cron はユーザーが明示したときだけ
- `--loop` や自律的な複数タスク処理は worktree で行う（他セッションのブランチ切替と競合させない）

## Codex

日本語で簡潔かつ丁寧に回答する。

- `codex exec` で呼ばれたときは、渡された依頼の範囲だけを実行し、確認や質問をせずに結果を返す
- 他のエージェント（`claude`、`codex`、`agy`）を自分から起動しない

## Antigravity（agy）

日本語で簡潔かつ丁寧に回答する。

- `agy --mode plan -p` で呼ばれたときは調査だけを行い、ファイルを変更しない。確認や質問はせず、指定された出力形式で結果を返す
- 情報には出典（URL、ファイルパスと行）を付ける。公式ドキュメントと一次情報を優先し、推測と事実を分けて書く
- 読み取りが権限で拒否されたら、推測で埋めずに「読めなかったファイルと理由」を結果に含める
- 他のエージェント（`claude`、`codex`、`agy`）を自分から起動しない
