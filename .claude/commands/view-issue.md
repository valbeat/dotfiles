# View GitHub Issue

View the details of a GitHub issue by its issue number.

## Steps

1. Ensure you're in a git repository with a GitHub remote
2. Use the GitHub CLI (`gh`) to view the issue
3. Optionally view comments and related information

## Basic Commands

### View issue details
```bash
# View issue by number
gh issue view <issue-number>

# Example
gh issue view 123
```

### View with web browser
```bash
# Open issue in browser
gh issue view <issue-number> --web

# Example
gh issue view 123 --web
```

### View comments
```bash
# View issue with comments
gh issue view <issue-number> --comments

# Example
gh issue view 123 --comments
```

### View specific fields
```bash
# View in JSON format
gh issue view <issue-number> --json title,body,state,author,labels,assignees,createdAt

# View minimal info
gh issue view <issue-number> --json title,state

# View with custom template
gh issue view <issue-number> --template '{{.title}} ({{.state}})'
```

## Advanced Usage

### View from different repository
```bash
# View issue from specific repo
gh issue view <issue-number> --repo owner/repo

# Example
gh issue view 456 --repo facebook/react
```

### List and search issues
```bash
# List all open issues
gh issue list

# Search for issues
gh issue list --search "bug"

# Filter by labels
gh issue list --label "bug" --label "high-priority"

# View closed issues
gh issue list --state closed
```

### Export issue details
```bash
# Save issue details to file
gh issue view <issue-number> > issue-<issue-number>.md

# Export as JSON
gh issue view <issue-number> --json title,body,comments > issue-<issue-number>.json
```

## Notes

- Requires GitHub CLI (`gh`) to be installed and authenticated
- Install with: `brew install gh` (macOS) or download from https://cli.github.com/
- First time setup: `gh auth login`
- The repository must have a GitHub remote configured
- Issue numbers are repository-specific