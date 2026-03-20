---
name: figma-to-issue
allowed-tools: Bash(gh:*)
disable-model-invocation: true
argument-hint: "[--size S|M|L] [--repo <repo>] [--draft]"
description: >-
  Generate GitHub issues from selected Figma components using Dev Mode MCP.
  Use when user says "Figmaからissue作成", "create issue from figma", or "figma to issue".
---

# Figma Component to Issue

## Context

- Current repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repository"`
- Figma Dev Mode MCP: Required for component data extraction
- Component selection: Must be selected in Figma before running
- Design system: Follow project's component patterns and naming

## Your task

Figma Dev Mode MCP を使用して、選択中のコンポーネントの実装用 GitHub Issue を自動生成する。デザインシステムと実装要件を分析して構造化されたIssueを作成する。

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
   curl -s http://127.0.0.1:3845/mcp/health || echo "Figma MCP サーバが起動していません"
   ```

2. **選択コンポーネントの情報取得**
   - MCP ツール `get_code` でコード生成情報を取得（デフォルト: React + Tailwind）
   - MCP ツール `get_variable_defs` でデザイン変数・スタイル情報を取得
   - MCP ツール `get_code_connect_map` で既存実装との紐づけ確認
   - MCP ツール `get_image` でスクリーンショット取得（オプション）

3. **コンポーネント情報の解析**
   - コンポーネント名・階層、使用デザイントークン
   - Props候補（variant、state等）、レスポンシブ対応の有無、既存実装との差分

4. **Issue タイトル生成**
   - パターン: `[UI] {コンポーネント名} の{実装|改修|バリアント追加}`

5. **Issue 本文生成（サイズ別テンプレート）**
   - Size S: [templates/size-s.md](templates/size-s.md)
   - Size M: [templates/size-m.md](templates/size-m.md)
   - Size L: [templates/size-l.md](templates/size-l.md)

6. **GitHub Issue 作成**
   ```bash
   gh issue create \
     --title "$ISSUE_TITLE" \
     --body "$ISSUE_BODY" \
     --label "ui,figma,needs-implementation"
   ```

## Error Handling

1. **MCP サーバ未起動**: Figma アプリ再起動
2. **選択なし**: Figma で対象を選択してから実行
3. **権限不足**: Dev Mode 権限の確認
4. **Code Connect 未設定**: 警告として表示（Issue 作成は継続）

## Examples

```
/figma-to-issue --size M
/figma-to-issue --size L --repo myorg/frontend-repo
/figma-to-issue --size S --draft
```

## Notes

- Figma Dev Mode MCP サーバーが http://127.0.0.1:3845/mcp で動作している前提
- Code Connect が設定されていると既存実装との差分が正確に取得できる
- Issue 作成後は手動でラベルやアサイン調整を推奨
