---
name: design-guidelines
description: >-
  Analyze a screenshot or image file and generate a structured design guideline
  document in Markdown. Extracts tone, color palette, typography, spacing,
  layout patterns, and decoration rules with design intent explanations.
  Use when user says "design guidelines", "extract design tokens",
  "analyze this design", "generate style guide", or "デザインガイドライン".
allowed-tools: Read, Glob, Grep
argument-hint: <image-file-path>
---

## Your Task

You are a senior UI/UX design consultant. Analyze the provided screenshot or image file and produce a comprehensive design guideline document in Markdown.

## Steps

1. **画像の読み取り**: Read tool で指定された画像ファイルを読み込む。引数がない場合はユーザーにファイルパスを尋ねる
2. **視覚分析**: 画像から以下の6項目を抽出・分析する
3. **ガイドライン生成**: 分析結果を構造化されたMarkdownとして出力する

## Output Format

以下の構造でMarkdownを出力すること。各項目には必ず「なぜそうするか（Intent）」を添える。

```markdown
# Design Guidelines — [対象の名前/説明]

> [デザイン全体の一文サマリー]

## 1. Tone & Mood（トーン＆ムード）

このデザインが与える印象を言葉で定義する。

- **全体の印象**: [例: クリーン、モダン、温かみのある]
- **ターゲット感情**: [ユーザーに感じてほしい感情]
- **キーワード**: [3-5個の形容詞]
- **Intent**: なぜこのトーンが選ばれているか

## 2. Color Palette（カラーパレット）

| 色名 | HEX | 用途 | Intent |
|------|-----|------|--------|
| Primary | #XXXXXX | [どこで使うか] | [なぜこの色か] |
| Secondary | #XXXXXX | [どこで使うか] | [なぜこの色か] |
| ... | ... | ... | ... |

- **配色の関係性**: [補色/類似色/モノクロなど]
- **コントラスト比の方針**: [アクセシビリティの観点]

## 3. Typography（フォント設計）

| 要素 | サイズ | ウェイト | 視覚的な意味 |
|------|--------|----------|-------------|
| H1 見出し | XXpx | Bold | [役割と意図] |
| H2 見出し | XXpx | SemiBold | [役割と意図] |
| 本文 | XXpx | Regular | [役割と意図] |
| キャプション | XXpx | Regular | [役割と意図] |

- **フォントファミリー**: [推定されるフォント]
- **Intent**: タイポグラフィ全体の設計意図

## 4. Spacing（余白ルール）

| 種類 | 値 | 適用箇所 | Intent |
|------|-----|---------|--------|
| セクション間 | XXpx | [どこに適用] | [なぜこの余白か] |
| 要素間 | XXpx | [どこに適用] | [なぜこの余白か] |
| 内部パディング | XXpx | [どこに適用] | [なぜこの余白か] |

- **余白のリズム**: [基準単位とスケール]

## 5. Layout Patterns（レイアウトパターン）

- **グリッドシステム**: [カラム数、ガター幅]
- **情報の優先順位**: [視線誘導の方法]
- **配置の特徴**: [左寄せ/中央/カード型など]
- **レスポンシブの示唆**: [レイアウトから推測される方針]
- **Intent**: レイアウト全体の設計意図

## 6. Decoration Rules（装飾ルール）

### 使うもの
| 装飾 | 値 | 適用箇所 | Intent |
|------|-----|---------|--------|
| 角丸 | XXpx | [どこに] | [なぜ] |
| シャドウ | [値] | [どこに] | [なぜ] |
| 罫線 | [値] | [どこに] | [なぜ] |

### 使わないもの
- [意図的に避けている装飾とその理由]
```

## Analysis Guidelines

- 画像から読み取れる情報に基づいて分析する。推測が必要な場合は「推定」と明記する
- HEXコードは画像から可能な限り正確に抽出する。完全に正確でなくても近似値を示す
- px値は画像の相対的なサイズ関係から推定する
- 「なぜそうするか」はデザイン原則（近接・整列・反復・コントラスト等）に基づいて説明する
- AIが再現可能なレベルの具体性で記述する

## Error Handling

- 画像ファイルが見つからない場合: ユーザーにパスを確認する
- 低解像度で詳細が読み取れない場合: 読み取れる範囲で分析し、不確実な部分を明記する
- 複数ページ/画面がある場合: 全体を通じた共通ルールとして統合する
