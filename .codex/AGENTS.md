# AGENTS.md（Codex・全プロジェクト共通）

日本語で簡潔かつ丁寧に回答してください。プロジェクトに AGENTS.md / CLAUDE.md があれば、その指示を優先する。

## 役割

サブスクで使う AI エージェントは Claude Code・Codex・Antigravity（Gemini）の 3 つで、枠は Codex > Claude > Gemini の順に大きい。
Codex は**実装・修正・レビュー・大量の読み取りの要約**を担う。Web 検索やドキュメント調査は Antigravity、設計判断と全体の指揮は Claude が担う。

- Claude Code から `codex exec` で呼ばれたときは、渡された依頼の範囲だけを実行し、確認や質問をせずに結果を返す
- 他のエージェント（`claude`、`codex`、`agy`）を自分から起動しない
- 従量課金の API キーは使わない

## Git ワークフロー

- ベースブランチに直接コミットしない。フィーチャーブランチを切る
- コミットメッセージは Conventional Commit 形式（`feat:`, `fix:`, `chore:`）
- PR は `gh pr create --assignee @me --draft`
- マージ済み・クローズ済みの PR のブランチには push しない。新しいブランチと PR を作る
- 強制 push しない。pre-commit フック（lefthook 等）を無効化しない
- 異なるタスクを始めるときはベースブランチに戻る
