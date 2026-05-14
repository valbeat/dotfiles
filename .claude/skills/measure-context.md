---
name: measure-context
description: "初期コンテキストのトークン消費量を計測する。CLAUDE.md最適化の前後比較に使用。任意のリポジトリで利用可能。サブスクリプション内で動作（追加 API 課金なし）。"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
disable-model-invocation: true
---

初期コンテキストのトークン消費量を計測し、レポートを表示する。

実測値は **現セッションの JSONL ログ** から取得する。`claude -p` を呼ばないためサブスクリプション内で完結し、追加 API 課金は発生しない。

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

## Step 2: セッション JSONL からトークン実測

現セッションの最初の assistant ターンの `usage` ブロックを読み取る。`cache_creation_input_tokens` が「初期コンテキスト全体のトークン数」に相当する（cold start でフル context がキャッシュ作成されるため）。

```bash
PROJECT_HASH=$(pwd | sed 's|/|-|g; s|^-||')
SESS_DIR="$HOME/.claude/projects/${PROJECT_HASH}"
LATEST=$(ls -t "$SESS_DIR"/*.jsonl 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then
  echo "Error: セッション JSONL が見つかりません: $SESS_DIR"
  exit 1
fi

python3 - "$LATEST" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as fp:
    for line in fp:
        try:
            d = json.loads(line)
        except Exception:
            continue
        if d.get('type') != 'assistant':
            continue
        m = d.get('message') or {}
        u = m.get('usage')
        if not u:
            continue
        cache_creation = u.get('cache_creation_input_tokens', 0)
        cache_read = u.get('cache_read_input_tokens', 0)
        out = {
            'input_tokens': u.get('input_tokens', 0),
            'cache_creation': cache_creation,
            'cache_read': cache_read,
            'initial_context_total': cache_creation + cache_read + u.get('input_tokens', 0),
            'output_tokens': u.get('output_tokens', 0),
            'model': m.get('model'),
            'source_jsonl': path,
        }
        print(json.dumps(out, indent=2, ensure_ascii=False))
        break
    else:
        print('Error: assistant ターンの usage が見つかりません', file=sys.stderr)
        sys.exit(1)
PY
```

**補足**: 前後比較したい場合は、変更前後でそれぞれ新規セッションを起動し本スキルを実行してから値を比較する。同一セッション内で計測する場合は最初のターンの usage が「初期コンテキスト + 直前ユーザー入力」を含む点に留意。

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

### トークン実測（現セッションの初回 assistant ターンから）
| 項目 | トークン数 |
|---|---|
| input_tokens | X |
| cache_creation | X |
| cache_read | X |
| 初期コンテキスト合計 | X |
| output_tokens | X |
| model | <name> |
```

引数に `--compare` が指定された場合:
1. 現在の計測結果を表示
2. `git stash` で変更を退避
3. 同じ計測を実行
4. `git stash pop` で復元
5. 改善前後の比較テーブルを表示
