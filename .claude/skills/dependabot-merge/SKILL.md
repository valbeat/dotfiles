---
allowed-tools: Bash(gh:*)
description: "Auto-merge all open Dependabot PRs with AI review"
argument-hint: "[--dry-run] [--include-major]"
---

# Dependabot Auto-Merge Skill

Automatically review and enable auto-merge for all open Dependabot PRs in the current repository.

## Context

- **Repository**: Current git repository
- **Target**: PRs authored by `app/dependabot`
- **State**: Open PRs only

## Arguments

- `--dry-run`: Preview mode. Shows what would be processed without making any changes.
- `--include-major`: Include major version updates (normally skipped for safety).

## Steps

1. **Verify Prerequisites**
   - Confirm `gh` CLI is authenticated: `gh auth status`
   - Confirm current directory is a git repository

2. **Fetch Open Dependabot PRs**
   ```bash
   gh pr list --author app/dependabot --state open --json number,title,url,headRefName
   ```

3. **For Each PR, Determine Update Type**
   - Parse the PR title to detect version change
   - Classify as `patch`, `minor`, or `major`

4. **Skip Major Updates** (unless `--include-major` specified)
   - Major updates may contain breaking changes
   - Log skipped PRs for manual review

5. **Fetch PR Diff**
   ```bash
   gh pr diff <number>
   ```

6. **Review the Changes**
   - Analyze the diff to understand what changed
   - Check for any suspicious or unexpected changes
   - Verify it's a standard dependency update

7. **Post Review Comment** (skip in dry-run)
   ```bash
   gh pr comment <number> -b "<review comment>"
   ```

8. **Approve the PR** (skip in dry-run)
   ```bash
   gh pr review <number> --approve -b "LGTM - automated review by Claude"
   ```

9. **Enable Auto-Merge** (skip in dry-run)
   ```bash
   gh pr merge <number> --auto --merge
   ```

10. **Output Summary**
    - Display table of all processed PRs
    - Show statistics (total, processed, skipped, failed)

## Version Detection

Dependabot PR titles follow this pattern:
- `Bump <package> from <old_version> to <new_version>`
- `Update <package> requirement from <old_version> to <new_version>`

Version change classification:
- **Major**: First number changes (e.g., 1.x.x → 2.x.x)
- **Minor**: Second number changes (e.g., 1.1.x → 1.2.x)
- **Patch**: Third number changes (e.g., 1.1.1 → 1.1.2)

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

After processing all PRs, display:

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
