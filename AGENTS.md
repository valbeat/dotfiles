# Repository Guidelines

## Project Structure & Module Organization
- Core dotfiles live at repo root (`.zshrc`, `.vimrc`, `.gitconfig`, `.tmux.conf`, etc.). Each is symlinked into `$HOME` by home-manager (`darwin/home.nix`); new root dotfiles must be added to its `dotfiles` list.
- `darwin/` holds the nix-darwin configuration: `configuration.nix` (entry), `system-defaults.nix` (macOS defaults), `home.nix` (dotfile symlinks), `homebrew.nix` (taps/brews/casks).
- `flake.nix` wires it together and exposes the `build` / `switch` / `update` apps. Vim-related assets sit under `.vim/` (plugins, colors, rc snippets).
- `Makefile` keeps only tasks with no nix equivalent (`patches`, `hunk-skill`).

## Build, Test, and Development Commands
- `nix run .#build`: dry-run build of the darwin system; CI runs this on every PR.
- `nix run .#switch`: build and activate (system defaults + symlinks + Homebrew; runs as root).
- `nix run .#update`: pulls latest `main` and updates git submodules.
- `make patches`: applies `claude -p` replacement patches to plugin caches.
- `make hunk-skill`: re-syncs the bundled hunk-review skill.

## Coding Style & Naming Conventions
- Shell/Vim config: prefer POSIX-compatible shell snippets; indent with tabs in Makefiles and two spaces in shell fragments to match existing style.
- Keep filenames dot-prefixed and aligned with `$HOME` paths; avoid introducing platform-specific suffixes unless guarded (e.g., `.gitconfig.osx` pattern).
- When editing Vim/IDE configs, follow current plugin manager/layout; keep per-tool settings in their respective rc files.

## Testing Guidelines
- Run `nix run .#build` after changing anything under `darwin/` or `flake.nix` to ensure the configuration still evaluates (CI enforces this on PRs).
- Manually spot-check a representative link: `ls -l ~/.zshrc` should resolve to the repo path. For Vim tweaks, launch `vim` once to confirm no startup errors.

## Commit & Pull Request Guidelines
- Commit messages follow a light Conventional Commit flavor (`feat:`, `fix:`, optional scope like `feat(git):`); keep them present-tense and descriptive.
- Rebase onto `main` before opening a PR. In PR descriptions, include: summary of changes, any new commands or env vars, and verification steps (`nix run .#build`/manual checks). Link related issues when available.

## Security & Configuration Tips
- Do not commit machine-specific secrets or tokens; prefer env var references or `.gitconfig.local`-style overrides kept outside version control.
- When adding new tools, keep defaults secure (e.g., `gpg`, SSH) and document any required permissions or key locations in comments near the config they affect.
