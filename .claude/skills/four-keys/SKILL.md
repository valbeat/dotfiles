---
allowed-tools: Bash(gh:*), Bash(git log:*), Bash(git tag:*), Bash(git diff:*), Bash(git rev-list:*), Bash(git show:*), Bash(date:*), Bash(bc:*), Bash(sort:*), Bash(wc:*), Bash(awk:*), Bash(head:*), Bash(tail:*), Bash(grep:*), Bash(uniq:*), Bash(jq:*), Read
argument-hint: "[--period 30d|90d|180d|1y] [--repo owner/repo] [--deploy-tag-pattern 'v*'] [--deploy-workflow 'deploy']"
name: four-keys
disable-model-invocation: true
context: fork
description: >-
  Measures Four Keys (DORA metrics) including deployment frequency, lead time,
  change failure rate, and MTTR. Use when measuring DevOps performance, or when
  the user says "four keys", "DORA metrics", or "deployment frequency".
model: sonnet
---

# Four Keys (DORA Metrics) Measurement

## Context

- Current repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repository"`
- Default branch: !`gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "unknown"`
- GitHub CLI access: Required

## Overview

Measure the four DORA (DevOps Research and Assessment) metrics from a GitHub repository:

1. **Deployment Frequency (DF)** - How often code is deployed to production
2. **Lead Time for Changes (LT)** - Time from first commit to production deployment
3. **Change Failure Rate (CFR)** - Percentage of deployments causing failures
4. **Mean Time to Recovery (MTTR)** - Time to recover from failures

## Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--period` | `90d` | Analysis period: `30d`, `90d`, `180d`, `1y` |
| `--repo` | (current) | Target repository (`owner/repo`) |
| `--deploy-tag-pattern` | `v*` | Tag glob pattern for identifying deployments |
| `--deploy-workflow` | (none) | GitHub Actions workflow name for deployments |
| `--deploy-branch` | default branch | Branch to track deployments on |
| `--failure-labels` | `bug,incident,hotfix` | Issue/PR labels indicating deployment failures |

## Measurement Process

### Step 1: Determine Analysis Period

Parse `--period` argument (default: 90d) and calculate the start date.

```bash
# Calculate start date
START_DATE=$(date -v-90d +%Y-%m-%dT00:00:00Z 2>/dev/null || date -d "90 days ago" --iso-8601=seconds 2>/dev/null)
```

### Step 2: Identify Deployments

Try multiple strategies in order of preference:

#### Strategy A: GitHub Actions Workflow Runs (if `--deploy-workflow` specified)
```bash
gh run list --workflow "$WORKFLOW" --status completed --branch "$BRANCH" \
  --json createdAt,conclusion,headSha,displayTitle \
  --limit 200 \
  --jq "[.[] | select(.createdAt >= \"$START_DATE\")]"
```

#### Strategy B: GitHub Releases
```bash
gh release list --limit 200 \
  --json tagName,createdAt,isPrerelease \
  --jq "[.[] | select(.isPrerelease == false and .createdAt >= \"$START_DATE\")]"
```

#### Strategy C: Git Tags matching pattern
```bash
git tag --sort=-creatordate --format='%(creatordate:iso-strict) %(refname:short)' \
  | while read date tag; do
    if [[ "$tag" == $PATTERN ]] && [[ "$date" > "$START_DATE" ]]; then
      echo "$date $tag"
    fi
  done
```

Report which strategy was used and how many deployments were found.

### Step 3: Deployment Frequency (DF)

Calculate:
- Total deployments in period
- Deployments per day / week / month
- Classify performance level

**Performance Levels:**
| Level | Frequency |
|-------|-----------|
| Elite | On-demand (multiple per day) |
| High | Between once per day and once per week |
| Medium | Between once per week and once per month |
| Low | Less than once per month |

### Step 4: Lead Time for Changes (LT)

For each deployment, find the commits included and calculate time from first commit to deploy:

```bash
# For each pair of consecutive deployments (tags/releases)
git log --format="%H %aI" "$PREV_TAG..$CURRENT_TAG" --first-parent
# Lead time = deploy timestamp - earliest commit timestamp
```

Calculate:
- Median lead time
- P50, P90 lead times
- Classify performance level

**Performance Levels:**
| Level | Lead Time |
|-------|-----------|
| Elite | Less than one hour |
| High | Between one day and one week |
| Medium | Between one week and one month |
| Low | More than one month |

### Step 5: Change Failure Rate (CFR)

Identify failures by looking for:

1. **Revert commits** after deployments
```bash
git log --grep="^Revert" --grep="^revert" --format="%H %aI %s" --since="$START_DATE"
```

2. **Hotfix deployments** (tags/releases with "hotfix", "fix", "patch" in name)

3. **Issues/PRs with failure labels**
```bash
gh issue list --state closed --label "bug,incident,hotfix" \
  --json number,title,createdAt,closedAt \
  --jq "[.[] | select(.createdAt >= \"$START_DATE\")]" \
  --limit 200
```

Calculate:
- Number of failure-causing deployments / total deployments
- Classify performance level

**Performance Levels:**
| Level | CFR |
|-------|-----|
| Elite | 0-5% |
| High | 5-10% |
| Medium | 10-15% |
| Low | 16-30%+ |

### Step 6: Mean Time to Recovery (MTTR)

For identified failures, calculate recovery time:

1. Match failure events to their resolution (next successful deploy, issue close, fix PR merge)
2. Calculate time between failure detection and recovery

```bash
# For issues with failure labels
gh issue list --state closed --label "bug,incident" \
  --json createdAt,closedAt \
  --jq "[.[] | select(.createdAt >= \"$START_DATE\") | {created: .createdAt, closed: .closedAt}]"
```

**Performance Levels:**
| Level | MTTR |
|-------|------|
| Elite | Less than one hour |
| High | Less than one day |
| Medium | Between one day and one week |
| Low | More than one week |

## Output Format

```markdown
# Four Keys Report

**Repository:** owner/repo
**Period:** YYYY-MM-DD ~ YYYY-MM-DD (Xd)
**Deployment Detection:** [strategy used]

## Summary

| Metric | Value | Level |
|--------|-------|-------|
| Deployment Frequency | X.X / week | ⭐ Elite |
| Lead Time for Changes | Xh XXm (median) | 🟢 High |
| Change Failure Rate | X.X% | 🟡 Medium |
| Mean Time to Recovery | Xh XXm | 🟢 High |

**Overall DORA Level: [Elite/High/Medium/Low]**

## Deployment Frequency

- Total deployments: X
- Per day: X.X
- Per week: X.X
- Per month: X.X
- Trend: [↑ Increasing / → Stable / ↓ Decreasing]

[Weekly deployment chart if applicable]

## Lead Time for Changes

- Median: Xh XXm
- P50: Xh XXm
- P90: Xd Xh
- Shortest: XXm
- Longest: Xd Xh

## Change Failure Rate

- Failed deployments: X / Y total (X.X%)
- Failure types:
  - Reverts: X
  - Hotfixes: X
  - Incidents: X

## Mean Time to Recovery

- Mean: Xh XXm
- Median: Xh XXm
- Fastest: XXm
- Slowest: Xd Xh
- Incidents tracked: X

## Recommendations

[Based on metrics, provide actionable recommendations to improve each metric]
```

## Performance Level Icons

- ⭐ Elite
- 🟢 High
- 🟡 Medium
- 🔴 Low

## Notes

- Requires `gh` CLI authenticated with access to the target repository
- Accuracy depends on consistent deployment practices (tags, releases, or workflows)
- Change Failure Rate is approximated from reverts, hotfix tags, and labeled issues
- MTTR is calculated from issue/incident lifecycle when failure labels are used
- For best results, use consistent release/tag conventions and label incidents appropriately
- If no deployment strategy yields results, report the limitation and suggest setup improvements

## Examples

```bash
# Measure current repo, last 90 days (default)
/four-keys

# Measure specific repo, last 180 days
/four-keys --repo facebook/react --period 180d

# Use workflow-based deployment detection
/four-keys --deploy-workflow "production-deploy"

# Custom tag pattern and period
/four-keys --deploy-tag-pattern "release-*" --period 1y

# Custom failure labels
/four-keys --failure-labels "bug,outage,p0"
```
