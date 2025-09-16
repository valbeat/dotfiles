---
allowed-tools: Read, Bash
description: Execute all project quality checks including linter, formatter, tests
---

# Run Project Checks

Execute all project quality checks including linter, formatter, tests, type checking, and static analysis.

## Steps

1. First, identify available check commands in the project:
   - Check `package.json` scripts section for Node.js projects
   - Check `Makefile` for Make-based projects
   - Check `pyproject.toml` or `setup.cfg` for Python projects
   - Check `Cargo.toml` for Rust projects
   - Look for configuration files like `.eslintrc`, `prettier.config.js`, `tsconfig.json`, etc.

2. Run checks in the following order:
   - **Formatter** (fix auto-fixable issues first)
   - **Linter** (catch style and potential bugs)
   - **Type Check** (ensure type safety)
   - **Tests** (verify functionality)
   - **Static Analysis** (security and complexity checks)

## Common Commands by Language

### JavaScript/TypeScript (Node.js)
```bash
# Format
npm run format || npm run prettier

# Lint
npm run lint || npm run eslint

# Type Check
npm run typecheck || npm run tsc || npx tsc --noEmit

# Test
npm test || npm run test

# All checks (if available)
npm run check || npm run validate
```

### Python
```bash
# Format
black . || autopep8 --in-place --recursive .

# Lint
flake8 || pylint **/*.py || ruff check

# Type Check
mypy . || pyright

# Test
pytest || python -m pytest

# Static Analysis
bandit -r . || safety check
```

### Rust
```bash
# Format
cargo fmt

# Lint
cargo clippy -- -D warnings

# Build (includes type checking)
cargo build

# Test
cargo test

# All checks
cargo check
```

### Ruby
```bash
# Format
rubocop -a || standardrb --fix

# Lint
rubocop || standardrb

# Test
rspec || rake test
```

## GitHub Actions Local Check

### Using act (GitHub Actions locally)
```bash
# Install act if not already installed
# macOS: brew install act
# Linux: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# List available workflows
act -l

# Run all workflows
act

# Run specific workflow
act -W .github/workflows/ci.yml

# Run specific job
act -j test
```

### Check GitHub Actions syntax
```bash
# Validate workflow files
actionlint

# Install actionlint
# macOS: brew install actionlint
# Or download from: https://github.com/rhysd/actionlint
```

### Review CI configuration
```bash
# Check if all local checks match CI pipeline
cat .github/workflows/*.yml | grep -E "run:|uses:"

# Ensure your local checks cover everything CI will run
```

## Notes

- Always run formatter before linter to avoid fixing issues manually
- If a command fails, fix the issues before proceeding to the next check
- Some projects may have a single command that runs all checks (e.g., `make check`, `npm run validate`)
- Check the project's README or CONTRIBUTING guide for specific instructions
- For CI/CD pipelines, ensure all checks pass locally before pushing
- Run GitHub Actions locally with `act` to catch CI failures before pushing
- Validate workflow syntax with `actionlint` to prevent YAML errors