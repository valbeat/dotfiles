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
  gh pr create --assign @me --draft --title "[package-name] 変更内容" --body "変更の詳細"
  ```
- ドキュメントの言語はプロジェクトに合わせる
- 異なるタスクを始めるときはベースブランチに戻る
