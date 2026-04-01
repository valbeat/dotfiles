---
name: review
allowed-tools: Read, Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git blame:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git show:*), Bash(git symbolic-ref:*), Bash(which:*), Bash(cat /tmp/*), Bash(codex:*), Bash(copilot:*), Glob, Grep, Agent
description: >-
  Multi-agent local code review with confidence scoring.
  Trigger conditions: git diff に変更がある場合（staged/unstaged/committed）。
  特に .ts, .tsx, .js, .jsx, .go, .rs, .py, .rb 等のソースコード変更時。
  Use when user says "review", "code review", "check my code", "コードレビュー", or "変更を確認".
argument-hint: "[--uncommitted|--staged|--brief|--commit <sha>|<file>]"
---

# Code Review (Local Multi-Agent)

## Arguments

| Argument | Description |
|----------|-------------|
| (none) | Review current branch vs base branch |
| `--uncommitted` | Review uncommitted changes (`git diff HEAD`) |
| `--staged` | Review staged changes (`git diff --cached`) |
| `--brief` | Output issues with confidence >= 75 only (for `/impl` integration) |
| `--commit <sha>` | Review specific commit |
| `<file_path>` | Review specific file(s) |

## Review Process

### Step 1: Identify Review Scope

各モードに応じた diff を取得し、テンプファイルに保存する（後続ステップで再利用）:

```bash
# Default: branch diff (auto-detect default branch)
# 1. デフォルトブランチを検出（各コマンドを個別に実行）
git rev-parse --abbrev-ref origin/HEAD  # → "origin/main" or "origin/master"
# 失敗した場合のフォールバック:
git rev-parse --verify origin/main >/dev/null 2>&1  # main を確認
git rev-parse --verify origin/master >/dev/null 2>&1 # master を確認

# 2. merge-base を取得
git merge-base HEAD origin/main  # (検出されたブランチを使用)

# 3. diff を取得してテンプファイルに保存
git diff <BASE>..HEAD > /tmp/review-diff.txt

# --uncommitted
git diff HEAD > /tmp/review-diff.txt

# --staged
git diff --cached > /tmp/review-diff.txt

# --commit <sha>
git show <sha> > /tmp/review-diff.txt

# <file_path> (branch diff scoped to file)
git diff <BASE>..HEAD -- "<file_path>" > /tmp/review-diff.txt
```

重要: パイプやサブシェルを使わず、個別コマンドとして実行すること（allowed-tools の制約）。

### Step 2: Gather Context (Haiku Agent)

Launch a Haiku agent to collect:
- Relevant CLAUDE.md files (root + directories of changed files)
- Project conventions and lint/format config files
- Summary of the change scope

```
subagent_type: Explore
model: haiku
prompt: |
  Collect review context for the following changes:
  {diff summary from Step 1}

  Return:
  1. Paths to all relevant CLAUDE.md files (with their content)
  2. Lint/format config files (.eslintrc, biome.json, etc.)
  3. Brief summary of the change
```

### Step 3: Parallel Review (5 Sonnet Agents + External AI)

Launch all review agents in parallel. Internal agents and external AI tools run simultaneously.

#### Internal Agents (5 Sonnet Agents)

```
model: sonnet
```

Each agent receives the diff and CLAUDE.md paths from Step 2, and returns issues with reasons. 各 issue の reason には `(Claude Sonnet)` を付記する。

**Agent #1 — CLAUDE.md Compliance**
Audit the changes against CLAUDE.md rules. Not all CLAUDE.md instructions apply to every change; focus on directly relevant ones.

**Agent #2 — Bug Detection (Shallow Scan)**
Read only the changed lines. Focus on obvious bugs. Avoid nitpicks. Ignore likely false positives.

**Agent #3 — Git History Context**
Read `git blame` and history of modified code. Identify bugs or regressions in light of historical context.

**Agent #4 — Code Comment Compliance**
Read code comments (TODO, FIXME, doc comments) in modified files. Ensure changes comply with any guidance in the comments.

**Agent #5 — Pattern & Consistency**
Check that changes follow existing patterns in the codebase (naming, structure, error handling). Flag deviations from established conventions.

#### External AI Review (Optional, in parallel)

Codex CLI / Copilot CLI がインストールされている場合、並列で外部AIレビューを実行する。
未インストールのツールはスキップ。Gemini は検索専用のため、レビューには使用しない。

```bash
# インストール確認（個別に実行）
which codex
which copilot
```

共通レビュープロンプト (REVIEW_PROMPT):
```
You are a senior code reviewer. Review these changes for bugs, logic errors, and security issues. Focus on significant problems only — skip nitpicks, style issues, and anything a linter would catch. Output a numbered list of issues with file:line, description, and suggested fix. If no significant issues, say 'No issues found'.
```

Step 1 で保存した `/tmp/review-diff.txt` を `cat` で読み取り、stdin 経由で各ツールに渡す:

**Codex Review** (if installed):
```bash
codex exec --full-auto --sandbox read-only --cd /path/to/repo "$REVIEW_PROMPT" < /tmp/review-diff.txt
```

**Copilot Review** (if installed):
```bash
cat /tmp/review-diff.txt | copilot -p "$REVIEW_PROMPT"
```

外部AIの指摘は Step 4 の信頼度スコアリング対象に統合する。issue の reason には `(Codex)` / `(Copilot)` を付記。

### Step 4: Confidence Scoring (Haiku Agents)

For each issue found in Step 3, launch a parallel Haiku agent. Each scoring agent receives:
- The issue description and reason
- The diff (from `/tmp/review-diff.txt`)
- CLAUDE.md file paths and content (from Step 2)

Score confidence (0-100):

| Score | Meaning |
|-------|---------|
| 0 | False positive. Doesn't stand up to scrutiny, or pre-existing issue. |
| 25 | Might be real, but likely false positive. Stylistic issues not in CLAUDE.md. |
| 50 | Real issue, but nitpick or rarely hit in practice. Not important relative to the rest. |
| 75 | Very likely real, verified by double-check. Important, directly impacts functionality or explicitly in CLAUDE.md. |
| 100 | Definitely real, confirmed with evidence. Happens frequently in practice. |

For CLAUDE.md-flagged issues, the agent must verify the CLAUDE.md actually calls it out specifically.

### Step 5: Filter & Report

Filter out issues scoring below 75.

**False positive examples (filter these out):**
- Pre-existing issues (not introduced by this change)
- Looks like a bug but isn't
- Pedantic nitpicks a senior engineer wouldn't flag
- Issues a linter/typechecker/compiler would catch
- General quality issues unless required by CLAUDE.md
- Issues silenced by lint-ignore comments
- Intentional functionality changes related to the broader change
- Pre-existing issues on unmodified lines (unless caused or exposed by the current change)

## Output Format

### Standard Output

```markdown
## Code Review Report

### Summary
- Files reviewed: X
- Lines changed: +Y -Z
- Issues found: N (of M candidates, filtered by confidence >= 75)

### Issues

1. **[description]** (confidence: N/100, model: Claude Sonnet|Gemini|Codex|Copilot)
   - File: path:line
   - Reason: [CLAUDE.md rule / bug / historical context / etc.]
   - Suggestion: [fix]

2. ...

### No Issues
(If all issues filtered out)
No significant issues found. Checked for bugs and CLAUDE.md compliance.
```

### Brief Output (--brief)

For `/impl` integration:

```
PASSED: No issues with confidence >= 75

or

ISSUES FOUND:
- [score] [model] path:line - description
- [score] [model] path:line - description
```

## Notes

- Do not attempt to build, typecheck, or run linters — assume CI handles that
- Cite CLAUDE.md rules when flagging compliance issues
- Keep output concise; avoid emojis
- For `--brief` mode, output only issues with confidence >= 75
- Use individual commands (no pipes between git and other tools) to respect allowed-tools constraints
- Temp file `/tmp/review-diff.txt` is used to pass diff data between steps; clean up is not required
