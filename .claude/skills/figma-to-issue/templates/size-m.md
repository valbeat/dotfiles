# Size M（標準）Issue テンプレート

標準コンポーネント用。Props・振る舞い・アクセシビリティ。

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
