# Repository Guidelines

## Project Structure & Module Organization
- Core dotfiles live at repo root (`.zshrc`, `.vimrc`, `.gitconfig`, `.tmux.conf`, `.hyper.js`, etc.). Each is intended to be symlinked directly into `$HOME`.
- `Makefile` orchestrates deployment, updates, backups, and cleanup of symlinks.
- `install.sh` runs the standard setup flow; Vim-related assets sit under `.vim/` (plugins, colors, rc snippets). Keep additions alongside similar files to simplify `ln -s` behavior.

## Build, Test, and Development Commands
- `make install`: runs `clean` then `deploy`; recreates symlinks in `$HOME` from the repo.
- `make deploy`: symlinks all tracked dotfiles into `$HOME` (idempotent).
- `make list`: prints the files that will be linked.
- `make update`: pulls latest main branch and updates git submodules.
- `make backup`: copies existing dotfiles from `$HOME` back into the repo (non-destructive; skips collisions).
- `make clean`: moves existing dotfiles in `$HOME` to `/tmp` as a temporary safety net.
- `make test`: alias of `deploy`; use to validate the Make workflow in CI-like runs.

## Coding Style & Naming Conventions
- Shell/Vim config: prefer POSIX-compatible shell snippets; indent with tabs in Makefiles and two spaces in shell fragments to match existing style.
- Keep filenames dot-prefixed and aligned with `$HOME` paths; avoid introducing platform-specific suffixes unless guarded (e.g., `.gitconfig.osx` pattern).
- When editing Vim/IDE configs, follow current plugin manager/layout; keep per-tool settings in their respective rc files instead of `install.sh`.

## Testing Guidelines
- Run `make test` after changes to ensure symlink creation still succeeds.
- Manually spot-check a representative link: `ls -l ~/.zshrc` should point to the repo path. For Vim tweaks, launch `vim` once to confirm no startup errors.

## Commit & Pull Request Guidelines
- Commit messages follow a light Conventional Commit flavor (`feat:`, `fix:`, optional scope like `feat(git):`); keep them present-tense and descriptive.
- Rebase onto `main` before opening a PR. In PR descriptions, include: summary of changes, any new commands or env vars, and verification steps (`make test`/manual checks). Link related issues when available.

## Security & Configuration Tips
- Do not commit machine-specific secrets or tokens; prefer env var references or `.gitconfig.local`-style overrides kept outside version control.
- When adding new tools, keep defaults secure (e.g., `gpg`, SSH) and document any required permissions or key locations in comments near the config they affect.
