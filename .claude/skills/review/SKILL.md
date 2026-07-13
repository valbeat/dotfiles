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
| `--brief` | Output issues with confidence >= 75 only (for `/dev-workflow:impl` integration) |
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

各エージェントには**必ず以下のテンプレートをそのまま使い**、`{...}` を埋めて渡す。
プロンプトを要約・省略しないこと。各 issue の reason には `(Claude Sonnet)` を付記する。

全エージェント共通の出力形式（テンプレート末尾に必ず含める）:

```
Output format (return ONLY this, no preamble):
For each issue found:
- file: <path>:<line>
- issue: <one-sentence description of the defect>
- reason: <why this is a problem, citing evidence (rule, history, comment, or pattern)>
- suggestion: <concrete fix>
If no issues: return exactly "No issues found."
Do NOT report: style nitpicks, pre-existing issues on unmodified lines,
anything a linter/typechecker would catch, or speculative issues without evidence.
```

**Agent #1 — CLAUDE.md Compliance**
```
You are a code reviewer checking ONLY for CLAUDE.md rule violations.
Read the diff at /tmp/review-diff.txt and these CLAUDE.md files: {paths from Step 2}.
For each rule that is directly relevant to the changed code, check whether the change
violates it. Cite the exact rule text in the reason. Not all rules apply to every
change; skip rules that are irrelevant to this diff. Do not flag general quality
issues that no CLAUDE.md rule mentions.
{common output format}
```

**Agent #2 — Bug Detection (Shallow Scan)**
```
You are a code reviewer hunting for bugs INTRODUCED BY this change.
Read the diff at /tmp/review-diff.txt. Focus on the changed lines only.
Look for: null/undefined dereference, off-by-one, inverted conditions, wrong variable
used, missing await/error handling, resource leaks, broken edge cases (empty list,
zero, unicode), incorrect API usage. For each candidate bug, state the concrete input
or state that triggers it. If you cannot describe a failure scenario, do not report it.
{common output format}
```

**Agent #3 — Git History Context**
```
You are a code reviewer using git history as evidence.
Read the diff at /tmp/review-diff.txt. For each modified file, run git blame and
git log on the changed regions. Look for: changes that undo a past bugfix (check the
fixing commit's message), violations of invariants described in past commit messages,
and repeated regressions. Cite the commit hash and message in the reason.
{common output format}
```

**Agent #4 — Code Comment Compliance**
```
You are a code reviewer checking the change against in-code guidance.
Read the diff at /tmp/review-diff.txt, then Read each modified file and collect
comments near the changed code: TODO, FIXME, WARNING, doc comments, invariant notes.
Report cases where the change contradicts or ignores that guidance (e.g. a comment
says "must be called under lock" and the new call is not). Quote the comment in the
reason.
{common output format}
```

**Agent #5 — Pattern & Consistency**
```
You are a code reviewer checking consistency with the existing codebase.
Read the diff at /tmp/review-diff.txt. For each changed file, find 2-3 sibling files
(same directory or same layer) and compare: naming conventions, error handling style,
logging, module structure, test placement. Report only clear deviations where the
codebase is consistent and the change breaks that consistency. Cite the sibling
file(s) that establish the pattern.
{common output format}
```

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

スコアリングエージェントには以下のテンプレートを使う:

```
subagent_type: general-purpose
model: haiku
prompt: |
  You are a skeptical review-verification agent. Your default stance is that the
  issue below is a FALSE POSITIVE; only score it high if the evidence holds up.

  Issue: {issue description, file:line, reason, suggestion}
  Diff: read /tmp/review-diff.txt
  CLAUDE.md files: {paths from Step 2}

  Verify:
  1. Is the flagged line actually changed in this diff (not pre-existing)?
  2. Read the file at the flagged location. Does the issue reproduce as described?
  3. If flagged as a CLAUDE.md violation, quote the exact rule. If no rule states it
     specifically, cap the score at 25.
  4. Would a linter/typechecker/compiler catch this? If yes, score 0.

  Return ONLY: a score (0/25/50/75/100 per the rubric) and a one-sentence justification.
```

### Step 4.5: Borderline Adjudication (Fable Agent)

Step 4 のスコアが **50 または 75** の指摘（ボーダーライン）が1件以上ある場合のみ実行する。
0 / 25 / 100 はスコア確定として扱い、このステップをスキップして Step 5 へ。

全ボーダーライン指摘を**単一の Fable エージェント**にまとめて渡し、最終裁定させる。
Fable はレビュー1回につき最大1エージェント（指摘ごとに起動しない）。

```
subagent_type: general-purpose
model: fable
prompt: |
  You are the final adjudicator for a code review. Each issue below was flagged
  by a reviewer and pre-scored by a fast verifier, but sits on the borderline
  (score 50 or 75). Your job is to settle each one definitively.

  Diff: read /tmp/review-diff.txt
  CLAUDE.md files: {paths from Step 2}

  Issues:
  {for each borderline issue: description, file:line, reason, suggestion, provisional score}

  For each issue:
  1. Read the actual file at the flagged location and trace the concrete failure
     scenario (or the exact CLAUDE.md rule text, for compliance issues).
  2. Decide: is this a real, change-introduced, non-nitpick issue a senior
     engineer would flag? Apply the same 0/25/50/75/100 rubric as the verifier.
  3. Do not split the difference — commit to a final score, citing evidence.

  Return ONLY one line per issue:
  <final score> | <file:line> | <one-sentence verdict with evidence>
```

裁定後のスコアで Step 4 の暫定スコアを上書きする。

### Step 5: Filter & Report

Filter out issues scoring below 75 (Step 4.5 の裁定があった指摘は裁定後スコアを使用).

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

For `/dev-workflow:impl` integration:

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
