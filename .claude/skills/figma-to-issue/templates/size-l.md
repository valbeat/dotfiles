# Size L（詳細）Issue テンプレート

画面・複数バリアント用。データ流し込み・API・タスク分解。

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
