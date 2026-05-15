#!/usr/bin/env python3
"""vercel/scripts/benchmark-runner.ts に CLAUDE_ALLOW_PRINT guard を挿入する。

benchmark-runner.ts は vercel-plugin の skill 注入挙動を `claude --print` で実測
するベンチマーク。codex 置換は不可（claude 自体の挙動測定が目的）。明示的な
opt-in を要求する guard を挿入する。

exit codes:
  0  applied
  10 already patched
  20 target missing
"""

import sys
from pathlib import Path

MARKER = "// PATCH:CLAUDE_PRINT_GUARD env-opt-in"

ANCHOR = '  // Prevent nested session errors\n  delete env.CLAUDECODE;\n'

GUARD = f'''  // Prevent nested session errors
  delete env.CLAUDECODE;

  {MARKER}
  // claude --print はサブスク対象外（API 課金）。CLAUDE_ALLOW_PRINT=1 で明示許可が必要。
  if (process.env.CLAUDE_ALLOW_PRINT !== "1") {{
    throw new Error(
      "benchmark-runner は claude --print を spawn しますが、サブスクリプション対象外で API 課金されます。" +
      "実行するには CLAUDE_ALLOW_PRINT=1 を環境変数に設定してください。",
    );
  }}
'''


def main():
    if len(sys.argv) != 2:
        print("usage: patch-benchmark-runner.py <path>", file=sys.stderr)
        sys.exit(2)

    target = Path(sys.argv[1])
    if not target.exists():
        print(f"  missing: {target}")
        sys.exit(20)

    src = target.read_text()
    if MARKER in src:
        print(f"  already patched: {target}")
        sys.exit(10)

    if ANCHOR not in src:
        print(f"  ERROR: anchor block not found in {target}", file=sys.stderr)
        sys.exit(3)

    new = src.replace(ANCHOR, GUARD, 1)
    target.write_text(new)
    print(f"  applied: {target}")
    sys.exit(0)


if __name__ == "__main__":
    main()
