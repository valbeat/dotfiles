# Enrich Issue

GitHub Issueの内容を分析し、プロジェクトのドキュメントやコーディング規約を参照して実装計画や仕様を詳細に補足する。

## Usage
```
Enrich issue #<issue-number>
```

## Arguments (Optional)
- `--mode <type>`: 補足モード (spec|plan|both) デフォルト: both
  - `spec`: 技術仕様の詳細化
  - `plan`: 実装計画の作成
  - `both`: 両方を生成

## Steps

1. **Issueの現在の内容を取得**
   ```bash
   # Issue情報を取得
   gh issue view <issue-number> --json title,body,labels,assignees,milestone
   
   # コメントも含めて取得
   gh issue view <issue-number> --comments
   ```

2. **プロジェクトコンテキストの収集**
   ```bash
   # プロジェクトのREADMEを確認
   cat README.md
   
   # CLAUDE.mdの規約を確認
   cat CLAUDE.md
   cat .claude/CLAUDE.md
   
   # 関連ドキュメントの検索
   find . -name "*.md" -type f | grep -E "(CONTRIBUTING|ARCHITECTURE|DESIGN|SPEC)"
   
   # package.jsonやその他の設定ファイル
   cat package.json 2>/dev/null || cat Cargo.toml 2>/dev/null
   ```

3. **関連コードベースの分析**
   ```bash
   # Issueタイトルから関連キーワードを抽出
   # 例: "認証機能" -> auth, authentication, login
   
   # 関連ファイルを検索
   rg -l "<keyword>" --type-add 'code:*.{js,ts,tsx,jsx,py,rs,go}'
   
   # 既存の実装パターンを確認
   rg -A 5 -B 5 "<pattern>" --type-add 'code:*.{js,ts,tsx,jsx,py,rs,go}'
   ```

4. **技術仕様の詳細化**
   ```markdown
   ## 技術仕様
   
   ### 概要
   [Issueの要件を技術的に解釈]
   
   ### アーキテクチャ
   - 全体構成
   - コンポーネント設計
   - データフロー
   
   ### インターフェース定義
   - API仕様
   - 型定義
   - 入出力形式
   
   ### 実装詳細
   - 使用する技術/ライブラリ
   - アルゴリズム
   - データ構造
   
   ### 制約事項
   - パフォーマンス要件
   - セキュリティ考慮事項
   - 互換性要件
   ```

5. **実装計画の作成**
   ```markdown
   ## 実装計画
   
   ### フェーズ分割
   1. **Phase 1: 基盤準備**
      - [ ] 必要なパッケージのインストール
      - [ ] 基本構造の作成
      - [ ] 設定ファイルの準備
   
   2. **Phase 2: コア機能実装**
      - [ ] メイン機能の実装
      - [ ] ユニットテストの作成
      - [ ] エラーハンドリング
   
   3. **Phase 3: 統合と最適化**
      - [ ] 既存システムとの統合
      - [ ] パフォーマンス最適化
      - [ ] 統合テスト
   
   ### タスクブレークダウン
   - タスク1: [具体的な作業内容] (推定: Xh)
   - タスク2: [具体的な作業内容] (推定: Xh)
   
   ### 依存関係
   - 外部ライブラリ
   - 他のIssue/PR
   - 環境要件
   ```

6. **受け入れ基準の明確化**
   ```markdown
   ## 受け入れ基準
   
   ### 機能要件
   - [ ] [具体的な動作条件1]
   - [ ] [具体的な動作条件2]
   
   ### 非機能要件
   - [ ] パフォーマンス: [具体的な基準]
   - [ ] セキュリティ: [具体的な基準]
   - [ ] 使いやすさ: [具体的な基準]
   
   ### テスト要件
   - [ ] ユニットテストカバレッジ: X%以上
   - [ ] E2Eテストシナリオ
   - [ ] エッジケースの考慮
   ```

7. **Issueの更新**
   ```bash
   # 既存の内容に追記する形で更新
   gh issue edit <issue-number> --body "$(cat <<EOF
   [既存の内容]
   
   ---
   ## 📋 詳細仕様 (AI-Enhanced)
   
   [生成した技術仕様]
   
   [生成した実装計画]
   
   [生成した受け入れ基準]
   
   ### 🔗 参照したドキュメント
   - CLAUDE.md
   - README.md
   - [その他参照したファイル]
   
   ### 📝 Notes
   - この仕様は既存のコードベースとプロジェクト規約に基づいて生成されました
   - 実装時は最新の状態を確認してください
   EOF
   )"
   ```

8. **ラベルの追加（必要に応じて）**
   ```bash
   # 仕様詳細化済みのラベルを追加
   gh issue edit <issue-number> --add-label "spec-defined"
   
   # 実装準備完了のラベルを追加
   gh issue edit <issue-number> --add-label "ready-for-implementation"
   ```

## Gemini連携オプション

より詳細な分析が必要な場合：
```bash
gemini <<EOF
役割: ソフトウェアアーキテクト/テクニカルライター
タスク: GitHub Issue #<number> の内容を基に詳細な技術仕様と実装計画を作成
入力:
- Issue内容: $(gh issue view <number>)
- プロジェクト規約: $(cat CLAUDE.md)
- 関連コード: $(rg -A 10 -B 10 "<keyword>")
要件:
- プロジェクトの既存パターンに従う
- 実装可能な具体的な計画
- テスト戦略を含む
出力形式:
1. 技術仕様（Markdown）
2. 実装計画（タスクリスト形式）
3. 受け入れ基準（チェックリスト）
EOF
```

## コーディング規約の自動抽出

プロジェクトから規約を学習：
```bash
# コーディングスタイルの分析
# - インデント（スペース/タブ）
# - 命名規則（camelCase/snake_case）
# - コメントスタイル
# - ファイル構成パターン

# 使用ライブラリの確認
# - package.json dependencies
# - import文のパターン
# - 頻出するユーティリティ

# テストパターンの確認
# - テストフレームワーク
# - テストファイルの配置
# - モック/スタブの使い方
```

## 注意事項

- Issueの既存内容は保持し、追記形式で更新
- プロジェクト固有の規約を優先
- 実装の実現可能性を考慮
- 過度に詳細になりすぎないようバランスを取る
- チーム固有の用語や略語を尊重

## Examples

### シンプルなバグ修正Issue
```bash
@enrich-issue 42 --mode plan
# → 修正手順とテスト計画を生成
```

### 新機能のIssue
```bash
@enrich-issue 100 --mode both
# → 完全な技術仕様と段階的な実装計画を生成
```

### 仕様のみ必要な場合
```bash
@enrich-issue 55 --mode spec
# → API仕様、データモデル、インターフェース定義を生成
```