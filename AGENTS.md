# Repository Guidelines

## Project Structure & Module Organization
- Core dotfiles live at repo root (`.zshrc`, `.vimrc`, `.gitconfig`, `.tmux.conf`, etc.). Each is symlinked into `$HOME` by home-manager (`darwin/home.nix`); new root dotfiles must be added to its `dotfiles` list.
- `.codex/AGENTS.md` and `.gemini/GEMINI.md` are the global instructions for Codex and Antigravity CLI (`agy`). Keep their role and Git-workflow sections in sync with `.claude/user-CLAUDE.md` (Claude Code's counterpart, linked to `~/.claude/CLAUDE.md`).
- `.claude/`, `.codex/` and `.gemini/` hold the files this repo owns for each agent; `darwin/home.nix` links **those files individually** into `~/.claude`, `~/.codex` and `~/.gemini`, which are real directories holding each tool's runtime state (sessions, plugins, logs). Never link the directories themselves. `tools/migrate-agent-dirs.sh` converts an old whole-directory link.
- This file is the only project instruction file: there is no `CLAUDE.md` at the repo root, and Claude Code reads `AGENTS.md` directly (v2.1.277+). That fallback only happens while no `./CLAUDE.md`, `./.claude/CLAUDE.md` or `CLAUDE.local.md` exists, so never add one here. This is why the user-level instructions are stored as `.claude/user-CLAUDE.md` and linked to `~/.claude/CLAUDE.md` under their real name (`renamedFiles` in `darwin/home.nix`).
- `.claude/` provides: the user-level instructions (`user-CLAUDE.md`), `agents/`, `hooks/`, and `statusline.sh`. Skills do not live here (see below). `.codex/` is `~/.codex` (`AGENTS.md` only; Codex custom prompts are deprecated, so Codex gets its skills from the plugin marketplaces instead). Everything else under both directories is runtime state and untracked.
- `darwin/` holds the nix-darwin configuration: `configuration.nix` (entry), `system-defaults.nix` (macOS defaults), `home.nix` (dotfile symlinks), `homebrew.nix` (taps/brews/casks), and `claude.nix` + `claude/merge.jq` (managed keys of the Claude Code / Antigravity CLI `settings.json`).
- `darwin/orca.nix` applies the Orca automation definitions from the private flake input `orca-automations` (valbeat/orca-automations) at activation. That repository is the single source of truth: never change automations only in Orca. Changes made in Orca (the app, another agent) must be written back with its `scripts/export.sh` and merged; otherwise apply stops with a conflict and leaves Orca untouched. After merging there, run `nix flake update orca-automations` here and switch.
- `flake.nix` wires it together and exposes every command as an app: `build` / `switch` / `update` (system) and `test` / `settings-diff` / `patches` / `hunk-skill` (repo tasks, formerly the `Makefile`). Vim-related assets sit under `.vim/` (plugins, colors, rc snippets).
- `tools/` keeps the non-nix helpers: `patches/` (plugin-cache patches), `settings-diff.sh`, and `tests/` (`test-*.sh`). They are run through the flake apps (`nix run .#test` and friends); there is no `Makefile`.

## Build, Test, and Development Commands
- `nix run .#build`: dry-run build of the darwin system; CI runs this on every PR. Run it after touching `darwin/` or `flake.nix`.
- `nix run .#switch`: fetches inputs as the invoking user first (the private `orca-automations` input needs the user's SSH key), then builds and activates (system defaults + symlinks + Homebrew + settings.json merge; runs as root). An agent can run it only after the user runs `sudo -v` in a real terminal: the sudo timestamp is shared per user for 15 minutes (`darwin/configuration.nix`). Ask for that instead of handing the command back, and run it by the expanded absolute path (`nix run /Users/<user>/src/github.com/valbeat/dotfiles#switch`; the allowlist in `darwin/claude.nix` matches that exact text, not `~` or `.#switch`) so the flake in the current directory is never the one activated.
- `nix run .#update`: pulls latest `main` and updates git submodules. The public flake inputs (nixpkgs, nix-darwin, home-manager) are updated by `.github/workflows/flake-update.yml` every Monday as a pull request; `orca-automations` is private and updated locally with `nix flake update orca-automations`.
- `nix fmt`: formats all `.nix` files with nixfmt; CI fails on unformatted files (`nix fmt -- --ci`) and also runs `nix flake check --no-build`.
- `nix run .#test`: runs `tools/tests/test-*.sh` (settings merge, settings-diff, agent-dir migration). When changing `merge.jq`, update the test first — and `git add` a *brand-new* test file before running, see Gotchas.
- `nix run .#settings-diff`: shows which managed keys the next switch would reset in `~/.claude/settings.json` and `~/.gemini/antigravity-cli/settings.json`.
- `nix run .#patches`: applies the `claude -p` replacement patches to plugin caches (idempotent; rerun after a plugin update overwrites them).
- `nix run .#hunk-skill`: re-syncs the vendored `hunk-review` skill into `agent-plugins-private` after `brew upgrade hunk` (then bump `portable-tools` and ship it). `PLUGINS_PRIVATE` overrides the destination checkout.

## Claude Code / Codex Settings
- `~/.claude/settings.json`, `~/.gemini/antigravity-cli/settings.json`, and `~/.codex/config.toml` are untracked: the tools write runtime state into them (`/model`, `/config`, auto mode, plugin installs, Orca's agent-status hooks), and committing them would leak machine- and project-local data into this public repo.
- Intended settings (permissions, own hooks, `enabledPlugins`, UI preferences) go in `darwin/claude.nix`; `nix run .#switch` merges them into the live files via `darwin/claude/merge.jq` (managed keys win, unnamed keys pass through, hooks are unioned). `model` is deliberately not managed.
- A managed key changed locally via `/config` or `claude plugin install` is reset on the next switch. Check `nix run .#settings-diff` first and port anything worth keeping to `darwin/claude.nix`.
- Skills never live in this repo. They live in the `valbeat/agent-plugins-private` (default; environment-coupled and experimental) and `valbeat/agent-plugins` (public; generalized) marketplaces and are invoked with a namespace (`/personal-tools:review`, `/git-workflow:commit`). Codex reads the same marketplaces: `agent-plugins-private` lists only `portable-tools` (skills that are safe outside Claude Code) in `.agents/plugins/marketplace.json`, which Codex prefers over `.claude-plugin/marketplace.json`; everything else stays Claude-only. Update Codex with `codex plugin marketplace upgrade`. Placement rules and the inventory procedure are in `/skill-management:skill-inventory`. To update one: edit the marketplace repo (`~/src/github.com/valbeat/agent-plugins{,-private}`), bump `version` in `plugin.json` (an unchanged version is skipped), push, then run `claude plugin marketplace update` and `claude plugin update`.

## Gotchas
- The flake apps run the repo's files **as git sees them**: a modified tracked file is picked up without committing, but a file that is still untracked is not in the flake source at all. `git add` a newly created test or tool before `nix run .#test` / `nix run .#patches`, or it is silently skipped.
- CI does not fetch the private `orca-automations` input: `nix run .#build` there overrides it with `ci/orca-automations-stub`. Locally, reproduce the CI check with `nix run .#build -- --override-input orca-automations "path:$PWD/ci/orca-automations-stub"`.
- **Switching branches rewrites the live Claude/Codex/Gemini config.** The linked files (`user-CLAUDE.md`, `agents/`, `hooks/`, `statusline.sh`, `AGENTS.md`, `GEMINI.md`) resolve into this checkout, so `git checkout` swaps them for every running session. Runtime state is no longer affected: it lives under `$HOME`, outside this repository. Do branch work in a worktree, never switch during `--loop` or long autonomous runs, and confirm `git branch --show-current` before committing (another session may have switched the shared checkout). Push explicitly with `git push origin <branch>`.
- Checking out a stale `main` that still tracked `settings.json` overwrites the live file, and the following `git pull` deletes it. Run `git fetch` first, check `git diff --stat HEAD..origin/main -- .claude/settings.json .gemini/settings.json`, and copy `~/.claude/settings.json` aside before moving.
- `.claude/hooks/guard.sh` blocks any Bash command whose text matches `claude -p` / `claude --print`, including an `echo` or `grep` that merely contains it. Search with a different token, or prefix `CLAUDE_ALLOW_PRINT=1` when the call is intended.

## Coding Style & Naming Conventions
- Shell/Vim config: prefer POSIX-compatible shell snippets; indent shell fragments with two spaces to match existing style.
- Keep filenames dot-prefixed and aligned with `$HOME` paths; avoid introducing platform-specific suffixes unless guarded (e.g., `.gitconfig.osx` pattern).
- When editing Vim/IDE configs, follow current plugin manager/layout; keep per-tool settings in their respective rc files.

## Testing Guidelines
- Run `nix run .#build` after changing anything under `darwin/` or `flake.nix` to ensure the configuration still evaluates (CI enforces this on PRs). Run `nix run .#test` after changing `tools/` or `darwin/claude/merge.jq`.
- Manually spot-check a representative link: `ls -l ~/.zshrc` should resolve to the repo path. For Vim tweaks, launch `vim` once to confirm no startup errors.

## Commit & Pull Request Guidelines
- Commit messages follow a light Conventional Commit flavor (`feat:`, `fix:`, optional scope like `feat(git):`); keep them present-tense and descriptive.
- Rebase onto `main` before opening a PR. In PR descriptions, include: summary of changes, any new commands or env vars, and verification steps (`nix run .#build`/manual checks). Link related issues when available.

## Security & Configuration Tips
- Do not commit machine-specific secrets or tokens; prefer env var references or `.gitconfig.local`-style overrides kept outside version control.
- When adding new tools, keep defaults secure (e.g., `gpg`, SSH) and document any required permissions or key locations in comments near the config they affect.
