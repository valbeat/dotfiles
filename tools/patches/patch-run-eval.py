#!/usr/bin/env python3
"""skill-creator/run_eval.py に CLAUDE_ALLOW_PRINT guard を挿入する。

run_eval.py は claude が skill description で正しくトリガーするかを評価するため
`claude -p` を spawn する。codex に置換すると別 LLM の挙動を測ることになり意味的
に成立しないので、明示的な opt-in (CLAUDE_ALLOW_PRINT=1) を要求する guard を入
れる。

exit codes:
  0  applied
  10 already patched
  20 target missing
"""

import sys
from pathlib import Path

MARKER = "# PATCH:CLAUDE_PRINT_GUARD env-opt-in"

ANCHOR = '''        cmd = [
            "claude",
            "-p", query,
            "--output-format", "stream-json",
            "--verbose",
            "--include-partial-messages",
        ]'''

GUARD = f'''        # {MARKER}
        # claude -p はサブスク対象外（API 課金）。CLAUDE_ALLOW_PRINT=1 で明示許可した場合のみ実行。
        if os.environ.get("CLAUDE_ALLOW_PRINT") != "1":
            raise RuntimeError(
                "run_eval.py は claude -p を spawn しますが、サブスクリプション対象外で API 課金されます。"
                "実行するには CLAUDE_ALLOW_PRINT=1 を環境変数に設定してください。"
            )
'''


def main():
    if len(sys.argv) != 2:
        print("usage: patch-run-eval.py <path>", file=sys.stderr)
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

    new = src.replace(ANCHOR, GUARD + ANCHOR, 1)
    target.write_text(new)
    print(f"  applied: {target}")
    sys.exit(0)


if __name__ == "__main__":
    main()
