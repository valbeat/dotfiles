---
name: dependabot-merge
allowed-tools: Bash(gh:*)
disable-model-invocation: true
description: >-
  Auto-reviews and enables auto-merge for all open Dependabot PRs.
  Supports single repo, org-wide, or multi-repo processing.
  Use when merging dependency updates, or when the user says "merge dependabot",
  "auto-merge deps", "handle dependabot PRs", or "org全体のdependabot".
argument-hint: "[--dry-run] [--include-major] [--org <name>] [--repo <owner/name>]"
---

# Dependabot Auto-Merge Skill

Automatically review and enable auto-merge for all open Dependabot PRs.
Supports single repo, org-wide, or specific repo targeting.

## Context

- **Repository**: Current git repository, specific repo, or all repos in an org
- **Target**: PRs authored by `app/dependabot`
- **State**: Open PRs only

## Arguments

- `--dry-run`: Preview mode. Shows what would be processed without making any changes.
- `--include-major`: Include major version updates (normally skipped for safety).
- `--org <name>`: Process all non-archived repos in the specified GitHub organization.
- `--repo <owner/name>`: Process a specific repository (can be repeated).

## Scope Resolution

Determine the target scope based on arguments:

### Single Repo (default)
No `--org` or `--repo` specified. Uses the current git repository.

### Org-Wide (`--org <name>`)
Fetch all non-archived repos in the org, then process each:
```bash
gh repo list <org> --no-archived --source --json nameWithOwner --limit 500 -q '.[].nameWithOwner'
```
- Archived repositories are **always excluded** via `--no-archived`
- Forks are excluded via `--source` (Dependabot doesn't run on forks by default)
- Only repos with open Dependabot PRs are processed (skip repos with 0 PRs)

### Specific Repo (`--repo <owner/name>`)
Process only the specified repo(s). Multiple `--repo` flags can be used.

## Steps

1. **Verify Prerequisites**
   - Confirm `gh` CLI is authenticated: `gh auth status`
   - If no `--org` or `--repo`: confirm current directory is a git repository

2. **Resolve Target Repos**
   - **Default**: current repo only
   - **`--org`**: fetch repo list (see Scope Resolution above)
   - **`--repo`**: use specified repos directly
   - Log the number of target repos before processing

3. **For Each Target Repo, Fetch Open Dependabot PRs**
   ```bash
   # Single repo (current directory)
   gh pr list --author app/dependabot --state open --json number,title,url,headRefName

   # Specific repo or org-wide iteration
   gh pr list --repo <owner/name> --author app/dependabot --state open --json number,title,url,headRefName
   ```
   - Skip repos with 0 open Dependabot PRs (no output needed for skipped repos)

4. **For Each PR, Determine Update Type**
   - Parse the PR title to detect version change
   - Classify as `patch`, `minor`, or `major` (see Version Detection below)

5. **Skip Major Updates** (unless `--include-major` specified)
   - Major updates may contain breaking changes
   - Log skipped PRs for manual review

6. **Fetch PR Diff**
   ```bash
   # Current repo
   gh pr diff <number>
   # Specific repo
   gh pr diff <number> --repo <owner/name>
   ```

7. **Review the Changes**
   - Analyze the diff to understand what changed
   - Check for any suspicious or unexpected changes
   - Verify it's a standard dependency update

8. **Post Review Comment** (skip in dry-run)
   ```bash
   gh pr comment <number> -b "<review comment>" [--repo <owner/name>]
   ```

9. **Approve the PR** (skip in dry-run)
   ```bash
   gh pr review <number> --approve -b "LGTM - automated review by Claude" [--repo <owner/name>]
   ```

10. **Enable Auto-Merge** (skip in dry-run)
    ```bash
    gh pr merge <number> --auto --merge [--repo <owner/name>]
    ```

11. **Output Summary**
    - Display table of all processed PRs grouped by repository (for org/multi-repo mode)
    - Show per-repo and overall statistics (total, processed, skipped, failed)

## Version Detection

Dependabot PR titles follow this pattern:
- `Bump <package> from <old_version> to <new_version>`
- `Update <package> requirement from <old_version> to <new_version>`

Version change classification:
- **Major**: First number changes (e.g., 1.x.x → 2.x.x)
- **Minor**: Second number changes (e.g., 1.1.x → 1.2.x)
- **Patch**: Third number changes (e.g., 1.1.1 → 1.1.2)

Safety rules (treat as major = skip by default):
- **0.x versions**: a minor bump on 0.x (e.g., 0.3.x → 0.4.0) may be breaking per semver
  convention — classify as `major`
- **Grouped updates** (one PR bumping multiple packages): classify by the LARGEST bump
  among all packages in the PR
- **Unparseable version** (no clear old→new semver in the title): classify as `major`
  and log it for manual review — never guess

## Review Comment Template

Use English for all review comments:

```markdown
## Automated Dependency Update Review

### Summary
- **Package**: {package_name}
- **Version Change**: {old_version} → {new_version}
- **Update Type**: {patch|minor|major}

### Review Notes
{analysis_of_changes}

### Decision
This update has been reviewed and approved for auto-merge.

---
*Reviewed by Claude Code*
```

## Output Format

### Single Repo Mode

```markdown
## Dependabot Auto-Merge Summary

### Processed PRs
| PR# | Package | Update | Status |
|-----|---------|--------|--------|
| #123 | lodash | 4.17.20 → 4.17.21 (patch) | ✅ Auto-merge enabled |
| #124 | axios | 0.21.0 → 1.0.0 (major) | ⏭️ Skipped (major) |
| #125 | react | 17.0.1 → 17.0.2 (patch) | ❌ Failed |

### Statistics
- **Total PRs**: X
- **Processed**: Y
- **Skipped (major)**: Z
- **Failed**: W
```

### Org / Multi-Repo Mode

Group results by repository:

```markdown
## Dependabot Auto-Merge Summary — org: <org-name>

### <owner/repo-a> (3 PRs)
| PR# | Package | Update | Status |
|-----|---------|--------|--------|
| #10 | lodash | 4.17.20 → 4.17.21 (patch) | ✅ Auto-merge enabled |
| #11 | webpack | 4.x → 5.x (major) | ⏭️ Skipped (major) |
| #12 | eslint | 8.50.0 → 8.51.0 (minor) | ✅ Auto-merge enabled |

### <owner/repo-b> (1 PR)
| PR# | Package | Update | Status |
|-----|---------|--------|--------|
| #5 | typescript | 5.2.0 → 5.3.0 (minor) | ✅ Auto-merge enabled |

### Overall Statistics
- **Repos scanned**: N
- **Repos with Dependabot PRs**: M
- **Total PRs**: X
- **Processed**: Y
- **Skipped (major)**: Z
- **Failed**: W
```

## Safety Notes

1. **Major updates are skipped by default** because they may contain breaking changes that require manual review and testing.

2. **Always review the diff** before approving. Look for:
   - Unexpected file changes outside of lockfiles
   - Suspicious code modifications
   - Changes to configuration files

3. **Auto-merge requires repository settings**:
   - Auto-merge must be enabled in repository settings
   - Branch protection rules may require status checks to pass

4. **Dry-run first**: Always use `--dry-run` on unfamiliar repositories to preview what would be processed.

## Error Handling

- If a PR cannot be processed, log the error and continue with the next PR
- Report all failures in the final summary
- Common issues:
  - Merge conflicts (PR needs rebase)
  - Failed status checks
  - Missing permissions
