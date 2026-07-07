---
name: check
allowed-tools: Read, Bash
description: >-
  Executes project quality checks including linter, formatter, build, and tests.
  Auto-detects project type from config files (package.json, go.mod, Cargo.toml, pyproject.toml).
  Trigger conditions: コード変更後の品質確認時、CI相当のローカルチェック実行時。
  Use when user says "check", "run tests", "lint", "format", "チェック", "テスト実行", or "品質確認".
argument-hint: "[--test|--lint|--format|--build|--all]"
---

# Run Project Checks

## Context

- Project type detection: !`ls package.json Makefile pyproject.toml Cargo.toml go.mod 2>/dev/null || echo "No standard project files found"`
- Current directory: !`pwd`

## Your task

Execute project quality checks. Identify the project type and run appropriate checks.

## Arguments

- `--test`: Run tests only
- `--lint`: Run linter only
- `--format`: Run formatter only
- `--build`: Run build only
- `--all` or no args: Run all checks (format → lint → build → test)

## Steps

1. **Detect project type** by checking for config files:
   - `package.json` → Node.js
   - `go.mod` → Go
   - `Cargo.toml` → Rust
   - `pyproject.toml` / `setup.cfg` → Python
   - `Makefile` → Make-based

2. **Resolve commands** by priority:
   1. Project-defined commands: `package.json` scripts / `Makefile` targets /
      commands used in `.github/workflows/`
   2. Only if none exist, fall back to the language defaults below

3. **Run checks** in order (for `--all`):
   - Formatter (auto-fix first)
   - Linter (catch issues)
   - Build (compile check)
   - Tests (verify functionality)

## Commands by Language

### Go
```bash
# Format
gofmt -w .
goimports -w .  # if available

# Lint
go vet ./...
golangci-lint run  # if available
staticcheck ./...  # if available

# Build
go build ./...

# Test
go test ./...
go test -race ./...  # with race detection
go test -cover ./... # with coverage
```

### JavaScript/TypeScript (Node.js)
```bash
# Format
npm run format || npx prettier --write .

# Lint
npm run lint || npx eslint .

# Type Check
npm run typecheck || npx tsc --noEmit

# Build
npm run build

# Test
npm test
```

### Rust
```bash
# Format
cargo fmt

# Lint
cargo clippy -- -D warnings

# Build
cargo build

# Test
cargo test
```

### Python
```bash
# Format
black . || ruff format .

# Lint
ruff check . || flake8

# Type Check
mypy . || pyright

# Test
pytest
```

## Output Format

```
## Quality Check Results

### Format
✓ PASSED (or ✗ FAILED with details)

### Lint
✓ PASSED (or ✗ FAILED with details)

### Build
✓ PASSED (or ✗ FAILED with details)

### Test
✓ PASSED: X tests passed
(or ✗ FAILED: X passed, Y failed)

---
Overall: PASSED / FAILED
```

## Integration with /impl

When called from `/impl`:
- `--test` is commonly used during RED/GREEN/REFACTOR cycles
- Full checks (`--all`) run at phase completion

## Notes

- Run formatter before linter to auto-fix issues
- If a check fails, report the failing command and its actual output verbatim, then stop (for `--all` mode)
- Never report PASSED without having actually run the command
- Check project's README for specific instructions
- For CI alignment, ensure local checks match pipeline
