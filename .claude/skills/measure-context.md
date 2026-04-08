---
name: measure-context
description: "初期コンテキストのトークン消費量を計測する。CLAUDE.md最適化の前後比較に使用。任意のリポジトリで利用可能。"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
disable-model-invocation: true
---

初期コンテキストのトークン消費量を計測し、レポートを表示する。

## Step 1: 自動読み込みファイルのサイズ計測

以下のファイルが存在する場合、行数・バイト数を取得する：

- `./CLAUDE.md`（プロジェクト）
- `./.claude/rules/` 配下の全 `.md` ファイル
- `~/.claude/CLAUDE.md`（グローバル）
- プロジェクト固有の memory ディレクトリ（`~/.claude/projects/` 配下の対応ディレクトリ）

プロジェクト固有の memory パスは以下のコマンドで動的に特定する：

```bash
# カレントディレクトリのパスからプロジェクト固有ディレクトリを導出
PROJECT_HASH=$(pwd | sed 's|/|-|g; s|^-||')
MEMORY_DIR="$HOME/.claude/projects/${PROJECT_HASH}/memory"
if [ -d "$MEMORY_DIR" ]; then
  echo "Memory directory: $MEMORY_DIR"
  wc -lc "$MEMORY_DIR"/*.md 2>/dev/null || echo "No memory files"
fi
```

## Step 2: claude CLI でトークン実測

Bash で以下を実行し、JSON 出力から usage を抽出する：

```bash
echo "hello" | claude -p --output-format json 2>/dev/null | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for item in data:
    if item.get('type') == 'result':
        u = item.get('usage', {})
        mu = item.get('modelUsage', {})
        print(json.dumps({
            'total': {
                'input_tokens': u.get('input_tokens'),
                'cache_creation': u.get('cache_creation_input_tokens'),
                'cache_read': u.get('cache_read_input_tokens'),
                'output_tokens': u.get('output_tokens'),
                'cost_usd': item.get('total_cost_usd')
            },
            'models': {k: {
                'input': v.get('inputTokens'),
                'cacheCreation': v.get('cacheCreationInputTokens'),
                'cacheRead': v.get('cacheReadInputTokens'),
                'output': v.get('outputTokens'),
                'costUSD': v.get('costUSD')
            } for k, v in mu.items()}
        }, indent=2, ensure_ascii=False))
        break
"
```

## Step 3: レポート表示

以下のフォーマットで結果を表示する：

```
## コンテキスト計測レポート

### ファイルサイズ
| ファイル | 行数 | バイト |
|---|---|---|
| Project CLAUDE.md | X | X |
| Global CLAUDE.md | X | X |
| Rules (*.md) | X | X |
| Memory (*.md) | X | X |
| 合計 | X | X |

### トークン実測
| 項目 | トークン数 |
|---|---|
| input_tokens | X |
| cache_creation | X |
| cache_read | X |
| 初期コンテキスト合計 | X |
| コスト | $X.XX |
```

引数に `--compare` が指定された場合:
1. 現在の計測結果を表示
2. `git stash` で変更を退避
3. 同じ計測を実行
4. `git stash pop` で復元
5. 改善前後の比較テーブルを表示
