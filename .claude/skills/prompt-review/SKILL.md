---
name: prompt-review
description: >
  Claude Code の対話履歴を収集・分析し、プロンプトの傾向・技術理解度・AI活用パターンを
  診断するレポートを生成する。/prompt-review で呼び出す。
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash
context: fork
---

# prompt-review

Claude Code との過去の対話履歴を分析し、プロンプティングの傾向や技術理解度を診断するスキル。
レポートはファイルに書き出さず、会話内に直接出力する。

## 引数

`$ARGUMENTS` を以下のルールで解釈する:

- 数値 → 日数（例: `30` → 過去30日）
- 文字列 → プロジェクト名フィルタ（部分一致）
- 文字列 + 数値 → プロジェクト名 + 日数
- `0` → 全期間
- 引数なし → 過去7日、全プロジェクト

## 実行手順

### Step 1: データ収集

収集スクリプトを実行する。パスはスキルファイルの場所を基準に解決する。

```bash
python3 .claude/skills/prompt-review/scripts/collect.py [OPTIONS] > /tmp/prompt-review-data.json
```

オプション対応:
- 引数なし → オプションなし（デフォルト7日）
- 数値（例: `30`） → `--days 30`
- `0` → `--days 0`
- 文字列（例: `myapp`） → `--project myapp`
- 文字列 + 数値 → `--project myapp --days 30`

実行後、`/tmp/prompt-review-data.json` を Read で読み込む。

### Step 2: 分析

読み込んだJSONの `messages` を以下の観点で分析する。
各観点に**プロンプトの引用（エビデンス）** を必ず含める。

#### 前処理: ノイズ除去

以下のような短文応答は分析対象から除外する:
- 単純な肯定（`y`, `yes`, `はい`, `ok`）
- 実行指示（`進めて`, `やって`, `do it`, `go ahead`）
- 承認（`それで`, `いいよ`, `お願いします`）
- 感謝のみ（`ありがとう`, `thanks`）

判定基準: 20文字以下かつ上記パターンに合致。技術的指示（`asyncで`, `30pxで`）は除外しない。

#### 分析観点

**a. 技術理解度**
- 熟知: 具体的な実装指示、正確な用語
- 基本理解: 概念は知っているがAIに委任
- 学習中: 質問形式、試行錯誤

**b. プロンプティングパターン**
- 効果的: 制約指定、段階的指示、コンテキスト提供
- 改善余地: 曖昧な指示、コンテキスト不足
- 癖: 言語の使い分け、短縮表現の頻度

**c. AI活用スタイル**
- 主体的: 方針決定はユーザー、実装をAIに依頼
- 依存的: 方針もAIに委ねている
- デバッグパターン: エラー解決の頼り方

**d. 時系列変化**
- プロンプト品質の変遷
- 新規技術への取り組み
- 繰り返す課題

**e. シークレット警告**
`secret_warnings` が空でなければ、レポート冒頭に警告を出力する。
マスク済みの値のみ使用し、平文は絶対に記載しない。

### Step 3: レポート出力

[references/report-template.md](references/report-template.md) に従い日本語でレポートを生成する。
ファイルには書き出さず、会話内にMarkdownとして直接出力する。

#### 記述ルール

- 日本語で記述
- 推測は「〜と推測される」「〜の可能性がある」と明示
- プロンプト引用は短く切り取り、パス中の個人名は `<user>` にマスク
- データ不足の場合は正直に記載
- ツール出典を括弧書きで明記（例: (Claude Code)）

## 参照

- [scripts/collect.py](scripts/collect.py) — データ収集スクリプト
- [references/report-template.md](references/report-template.md) — レポートテンプレート
