#!/usr/bin/env python3
"""skill-creator/improve_description.py の `_call_claude` を codex 呼び出しに置換する。

exit codes:
  0  applied
  10 already patched (skipped)
  20 target missing
"""

import re
import sys
from pathlib import Path

MARKER = "# PATCH:CLAUDE_PRINT_GUARD codex-replacement"

REPLACEMENT = '''def _call_claude(prompt: str, model: str | None, timeout: int = 300) -> str:
    """Run codex exec (OpenAI) instead of `claude -p` and return the text response.

    {marker}
    元実装は `claude -p --output-format text` を使っていたが、Claude Code Max
    サブスクリプションの対象外になったため codex CLI へフォールバック。codex の
    認証 (`codex login` か OPENAI_API_KEY) は呼び出し側で済ませておく前提。
    """
    cmd = ["codex", "exec", "-"]
    if model:
        cmd.extend(["-m", model])

    env = {{k: v for k, v in os.environ.items() if k != "CLAUDECODE"}}

    result = subprocess.run(
        cmd,
        input=prompt,
        capture_output=True,
        text=True,
        env=env,
        timeout=timeout,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"codex exec exited {{result.returncode}}\\nstderr: {{result.stderr}}"
        )
    return result.stdout
'''.format(marker=MARKER)


def main():
    if len(sys.argv) != 2:
        print("usage: patch-improve-description.py <path>", file=sys.stderr)
        sys.exit(2)

    target = Path(sys.argv[1])
    if not target.exists():
        print(f"  missing: {target}")
        sys.exit(20)

    src = target.read_text()
    if MARKER in src:
        print(f"  already patched: {target}")
        sys.exit(10)

    pattern = re.compile(
        r'def _call_claude\(prompt: str, model: str \| None, timeout: int = 300\) -> str:\n'
        r'(?:[^\n]*\n)+?'
        r'    return result\.stdout\n',
        re.MULTILINE,
    )
    if not pattern.search(src):
        print(f"  ERROR: _call_claude のシグネチャが想定と異なる: {target}", file=sys.stderr)
        sys.exit(3)

    # Use a lambda so re.sub doesn't interpret \n / \1 etc inside the replacement.
    new = pattern.sub(lambda _m: REPLACEMENT, src, count=1)
    target.write_text(new)
    print(f"  applied: {target}")
    sys.exit(0)


if __name__ == "__main__":
    main()
