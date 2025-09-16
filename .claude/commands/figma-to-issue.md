# Figma Component to Issue

## Context

- Current repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repository"`
- Figma Dev Mode MCP: Required for component data extraction
- Component selection: Must be selected in Figma before running
- Design system: Follow project's component patterns and naming

## Your task

Figma Dev Mode MCP を使用して、選択中のコンポーネントの実装用 GitHub Issue を自動生成する。デザインシステムと実装要件を分析して構造化されたIssueを作成する。

## Usage
```
Create issue from figma component
```

## Arguments (Optional)
- `--size <type>`: Issue の詳細レベル (S|M|L) デフォルト: M
  - `S`: 小さなUI調整（受入条件のみ）
  - `M`: 標準コンポーネント（Props・振る舞い・アクセシビリティ）
  - `L`: 画面・複数バリアント（データ流し込み・API・タスク分解）
- `--repo <repo>`: 対象リポジトリ（デフォルト: カレントリポジトリ）
- `--draft`: ドラフト Issue として作成

## Prerequisites

1. **Figma Dev Mode MCP サーバが有効**
   - Figma デスクトップアプリで Dev Mode または Full seat
   - ローカル MCP サーバ: `http://127.0.0.1:3845/mcp`

2. **対象コンポーネントを Figma で選択済み**
   - フレーム・レイヤー・コンポーネントを選択状態にする
   - または Figma リンクを用意（node-id 含む）

## Steps

1. **Figma Dev Mode MCP 接続確認**
   ```bash
   # MCP サーバの接続状態を確認
   curl -s http://127.0.0.1:3845/mcp/health || echo "❌ Figma MCP サーバが起動していません"
   ```

2. **選択コンポーネントの情報取得**
   ```bash
   # 選択ノードのコード生成情報を取得
   # MCP ツール: get_code
   # - デフォルト: React + Tailwind
   # - プロンプトでフレームワーク変更可能
   
   # デザイン変数・スタイル情報を取得
   # MCP ツール: get_variable_defs
   # - 使用されている色・余白・タイポ
   # - 変数名と値の両方を取得
   
   # Code Connect マッピング取得
   # MCP ツール: get_code_connect_map
   # - 既存実装コンポーネントとの紐づけ
   
   # スクリーンショット取得（オプション）
   # MCP ツール: get_image
   ```

3. **コンポーネント情報の解析**
   ```bash
   # 取得した情報から以下を抽出:
   # - コンポーネント名・階層
   # - 使用デザイントークン
   # - Props候補（variant、state等）
   # - レスポンシブ対応の有無
   # - 既存実装との差分
   ```

4. **Issue タイトル生成**
   ```bash
   # パターン例:
   # [UI] ButtonComponent の実装
   # [UI] HeaderNavigation のレスポンシブ対応
   # [UI] CardComponent バリアント追加
   
   COMPONENT_NAME="[Figmaから取得したコンポーネント名]"
   ISSUE_TYPE="[実装|改修|バリアント追加]"
   ISSUE_TITLE="[UI] ${COMPONENT_NAME} の${ISSUE_TYPE}"
   ```

5. **Issue 本文生成（サイズ別）**

### Size S（最小）
```markdown
## 📋 概要
Figma で選択したコンポーネントの実装

## 🔗 Figma リンク
[Figma Component Link]

## ✅ 受入条件
- [ ] デザイン通りの見た目
- [ ] レスポンシブ対応
- [ ] アクセシビリティ準拠

## 🎨 デザイントークン
- 使用変数: [variable names]

---
🤖 Generated from Figma Dev Mode MCP
```

### Size M（標準）
```markdown
## 📋 概要
Figma で選択したコンポーネントの実装

## 🔗 Figma リンク
[Figma Component Link]

## 🏗️ コンポーネント仕様
### Props
- `variant`: [取得したバリアント情報]
- `size`: [サイズオプション]
- `disabled`: boolean
- `onClick`: () => void

### 状態・振る舞い
- デフォルト状態
- ホバー・フォーカス・アクティブ
- ディスエーブル状態

### レスポンシブ対応
- モバイル: [breakpoint]
- タブレット: [breakpoint]  
- デスクトップ: [breakpoint]

## 🎨 デザイントークン
### 使用変数
[get_variable_defsで取得した変数一覧]

## ♿ アクセシビリティ
- [ ] セマンティックHTML
- [ ] ARIA属性
- [ ] キーボード操作
- [ ] スクリーンリーダー対応

## ✅ 受入条件
- [ ] Props通りに動作する
- [ ] 全状態のビジュアルが正しい
- [ ] レスポンシブが機能する
- [ ] アクセシビリティテストを通過
- [ ] Storybook にサンプル追加

## 🔄 既存実装との関係
[Code Connectの情報があれば]
- 再利用: [既存コンポーネント名]
- 差分: [変更点]

---
🤖 Generated from Figma Dev Mode MCP
```

### Size L（詳細）
```markdown
## 📋 概要
Figma で選択したコンポーネントの実装

## 🔗 Figma リンク
[Figma Component Link]

## 🏗️ コンポーネント仕様
### Props定義
```typescript
interface ComponentProps {
  variant: 'primary' | 'secondary' | 'outline';
  size: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  children: ReactNode;
  onClick?: () => void;
}
```

### 状態管理
- ローカル状態: [useState等]
- 外部状態: [Context、Store等]

### データフロー例
```typescript
// 使用例
<Component 
  variant="primary"
  size="md"
  onClick={() => handleAction()}
>
  Button Text
</Component>
```

## 🎨 デザインシステム
### デザイントークン詳細
[get_variable_defsの完全な出力]

### アセット
- アイコン: [使用するアイコン一覧]
- 画像: [必要な画像リソース]

## 📱 レスポンシブ仕様
### ブレイクポイント別対応
- Mobile (320-768px): [仕様]
- Tablet (768-1024px): [仕様]
- Desktop (1024px+): [仕様]

## ♿ アクセシビリティ詳細
### WCAG 準拠項目
- AA レベル対応必須
- 色彩コントラスト比: 4.5:1以上
- フォーカス表示: 明確な視覚表現
- キーボード操作: Tab、Enter、Space

### スクリーンリーダー
- aria-label: [適切なラベル]
- role: [適切なロール]

## 🧪 テスト要件
### ユニットテスト
- [ ] Props のバリデーション
- [ ] イベントハンドリング
- [ ] 状態変化の確認

### ビジュアルテスト
- [ ] Storybook での全パターン確認
- [ ] Chromatic でのビジュアル回帰テスト

### E2Eテスト
- [ ] ユーザーフロー内での動作確認

## 📋 実装タスク分解
### Phase 1: 基盤実装
- [ ] コンポーネントファイル作成
- [ ] 型定義
- [ ] 基本スタイリング

### Phase 2: インタラクション
- [ ] 状態管理実装
- [ ] イベントハンドリング
- [ ] バリエーション対応

### Phase 3: 品質保証
- [ ] テスト実装
- [ ] Storybook セットアップ
- [ ] アクセシビリティ確認

## 🔄 既存実装との関係
[Code Connectマッピング詳細]

## 📚 参考資料
- [関連するデザインシステムドキュメント]
- [類似コンポーネントの実装]

---
🤖 Generated from Figma Dev Mode MCP
```

6. **GitHub Issue 作成**
   ```bash
   # 現在のリポジトリまたは指定されたリポジトリに Issue 作成
   gh issue create \
     --title "$ISSUE_TITLE" \
     --body "$ISSUE_BODY" \
     --label "ui,figma,needs-implementation" \
     ${draft:+--web}
   
   # Created issue の URL を表示
   ISSUE_URL=$(gh issue list --limit 1 --json url -q '.[0].url')
   echo "✅ Issue created: $ISSUE_URL"
   ```

7. **Figma リンクとの紐づけ**
   ```bash
   # Issue 作成後、Figma のコメント機能を使って
   # Issue URL をデザインに追記（手動またはAPI）
   ```

## MCP ツール呼び出し例

### get_code の使用
```bash
# React + Tailwind でコード生成
figma_mcp_call get_code --framework="React" --styling="Tailwind CSS"

# 既存 UI ライブラリを使用
figma_mcp_call get_code --prompt="Use our existing Button component from @/components/ui"
```

### get_variable_defs の使用
```bash
# 選択範囲で使われている変数一覧
figma_mcp_call get_variable_defs --include-values=true
```

### get_code_connect_map の使用
```bash
# 既存実装との紐づけ確認
figma_mcp_call get_code_connect_map
```

## エラーハンドリング

### よくある問題と対処
1. **MCP サーバ未起動**: Figma アプリ再起動
2. **選択なし**: Figma で対象を選択してから実行
3. **権限不足**: Dev Mode 権限の確認
4. **Code Connect 未設定**: 警告として表示（Issue 作成は継続）

## Gemini 連携オプション

より詳細な分析が必要な場合：
```bash
gemini <<EOF
役割: フロントエンドアーキテクト・UIデザイナー
タスク: Figma コンポーネント情報から詳細な実装仕様作成
入力:
- Figma MCP データ: $(figma_mcp_call get_code)
- デザイン変数: $(figma_mcp_call get_variable_defs)
- 既存実装: $(figma_mcp_call get_code_connect_map)
- プロジェクト情報: $(cat package.json 2>/dev/null || echo "No package.json")
要件:
- TypeScript インターフェース定義
- アクセシビリティ要件
- テスト戦略
- 段階的実装計画
出力形式:
1. コンポーネント仕様（TypeScript）
2. Props・状態設計
3. 実装タスク分解（チェックリスト）
4. テスト要件
EOF
```

## Examples

### 新規ボタンコンポーネント
```bash
@figma-to-issue --size M
# → 標準的な Props・状態・アクセシビリティ仕様を生成
```

### 複雑なナビゲーション
```bash  
@figma-to-issue --size L --repo myorg/frontend-repo
# → 詳細なレスポンシブ・データフロー・タスク分解を生成
```

### 簡単な UI 調整
```bash
@figma-to-issue --size S --draft
# → 最小限の受入条件でドラフト Issue 作成
```

## Notes

- Figma Dev Mode MCP サーバーが http://127.0.0.1:3845/mcp で動作している前提
- Code Connect が設定されていると既存実装との差分が正確に取得できる
- デザイントークンの命名規則に従ったコード生成が可能
- Issue 作成後は手動でラベルやアサイン調整を推奨