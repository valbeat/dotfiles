# Repository Guidelines

## Project Structure & Module Organization
- Core dotfiles live at repo root (`.zshrc`, `.vimrc`, `.gitconfig`, `.tmux.conf`, etc.). Each is symlinked into `$HOME` by home-manager (`darwin/home.nix`); new root dotfiles must be added to its `dotfiles` list.
- `.claude/` is `~/.claude`: the user-level `CLAUDE.md`, `skills/` (experimental skills that stay out of the plugin marketplaces), `agents/`, `hooks/`, and `statusline.sh`. `.codex/` is `~/.codex` (`AGENTS.md`, `prompts/`). Everything else under both directories is runtime state and untracked.
- `darwin/` holds the nix-darwin configuration: `configuration.nix` (entry), `system-defaults.nix` (macOS defaults), `home.nix` (dotfile symlinks), `homebrew.nix` (taps/brews/casks), and `claude.nix` + `claude/merge.jq` (managed keys of the Claude/Gemini `settings.json`).
- `flake.nix` wires it together and exposes the `build` / `switch` / `update` apps. Vim-related assets sit under `.vim/` (plugins, colors, rc snippets).
- `tools/` keeps the non-nix helpers: `patches/` (plugin-cache patches), `settings-diff.sh`, and `tests/` (`test-*.sh`). `Makefile` keeps only tasks with no nix equivalent.

## Build, Test, and Development Commands
- `nix run .#build`: dry-run build of the darwin system; CI runs this on every PR. Run it after touching `darwin/` or `flake.nix`.
- `nix run .#switch`: build and activate (system defaults + symlinks + Homebrew + settings.json merge; runs as root).
- `nix run .#update`: pulls latest `main` and updates git submodules.
- `make test`: runs `tools/tests/test-*.sh` (settings merge, settings-diff). When changing `merge.jq`, update the test first.
- `make settings-diff`: shows which managed keys the next switch would reset in `~/.claude/settings.json` and `~/.gemini/settings.json`.
- `make patches`: applies the `claude -p` replacement patches to plugin caches (idempotent; rerun after a plugin update overwrites them).
- `make hunk-skill`: re-syncs the vendored `hunk-review` skill after `brew upgrade hunk`.

## Claude Code / Codex Settings
- `~/.claude/settings.json`, `~/.gemini/settings.json`, and `~/.codex/config.toml` are untracked: the tools write runtime state into them (`/model`, `/config`, auto mode, plugin installs, Orca's agent-status hooks), and committing them would leak machine- and project-local data into this public repo.
- Intended settings (permissions, own hooks, `enabledPlugins`, UI preferences) go in `darwin/claude.nix`; `nix run .#switch` merges them into the live files via `darwin/claude/merge.jq` (managed keys win, unnamed keys pass through, hooks are unioned). `model` is deliberately not managed.
- A managed key changed locally via `/config` or `claude plugin install` is reset on the next switch. Check `make settings-diff` first and port anything worth keeping to `darwin/claude.nix`.
- General-purpose skills live in the `valbeat/claude-plugins` (public) and `valbeat/claude-plugins-private` marketplaces and are invoked with a namespace (`/git-workflow:commit`, `/dev-workflow:spec`). To update one: edit the marketplace repo (`~/src/github.com/valbeat/claude-plugins{,-private}`), bump `version` in `plugin.json` (an unchanged version is skipped), push, then run `claude plugin marketplace update` and `claude plugin update`.

## Gotchas
- **Switching branches rewrites the live Claude/Codex config.** `~/.claude` and `~/.codex` resolve into this checkout, so `git checkout` swaps `CLAUDE.md`, skills, and agents for every running session. Do branch work in a worktree, never switch during `--loop` or long autonomous runs, and confirm `git branch --show-current` before committing (another session may have switched the shared checkout). Push explicitly with `git push origin <branch>`.
- Checking out a stale `main` that still tracked `settings.json` overwrites the live file, and the following `git pull` deletes it. Run `git fetch` first, check `git diff --stat HEAD..origin/main -- .claude/settings.json .gemini/settings.json`, and copy `~/.claude/settings.json` aside before moving.
- `.claude/hooks/guard.sh` blocks any Bash command whose text matches `claude -p` / `claude --print`, including an `echo` or `grep` that merely contains it. Search with a different token, or prefix `CLAUDE_ALLOW_PRINT=1` when the call is intended.

## Coding Style & Naming Conventions
- Shell/Vim config: prefer POSIX-compatible shell snippets; indent with tabs in Makefiles and two spaces in shell fragments to match existing style.
- Keep filenames dot-prefixed and aligned with `$HOME` paths; avoid introducing platform-specific suffixes unless guarded (e.g., `.gitconfig.osx` pattern).
- When editing Vim/IDE configs, follow current plugin manager/layout; keep per-tool settings in their respective rc files.

## Testing Guidelines
- Run `nix run .#build` after changing anything under `darwin/` or `flake.nix` to ensure the configuration still evaluates (CI enforces this on PRs). Run `make test` after changing `tools/` or `darwin/claude/merge.jq`.
- Manually spot-check a representative link: `ls -l ~/.zshrc` should resolve to the repo path. For Vim tweaks, launch `vim` once to confirm no startup errors.

## Commit & Pull Request Guidelines
- Commit messages follow a light Conventional Commit flavor (`feat:`, `fix:`, optional scope like `feat(git):`); keep them present-tense and descriptive.
- Rebase onto `main` before opening a PR. In PR descriptions, include: summary of changes, any new commands or env vars, and verification steps (`nix run .#build`/manual checks). Link related issues when available.

## Security & Configuration Tips
- Do not commit machine-specific secrets or tokens; prefer env var references or `.gitconfig.local`-style overrides kept outside version control.
- When adding new tools, keep defaults secure (e.g., `gpg`, SSH) and document any required permissions or key locations in comments near the config they affect.
