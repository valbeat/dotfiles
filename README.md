# dotfiles

## Installing

macOS defaults, dotfile symlinks, and Homebrew packages are all applied by
nix-darwin. Install Nix first (flakes enabled), e.g. the Determinate Systems
installer:

```shell
/bin/sh -c "$(curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix)" -- install
```

Then clone the repo to the path `darwin/home.nix` expects and switch:

```shell
git clone git@github.com:valbeat/dotfiles.git ~/src/github.com/valbeat/dotfiles
cd ~/src/github.com/valbeat/dotfiles
MY_HOST=$(scutil --get LocalHostName)
sudo nix run nix-darwin -- switch --flake ".#$MY_HOST"   # first run (bootstrap)
nix run .#switch                                         # subsequent changes
```

This creates `$HOME` symlinks that resolve into this repo — editing a dotfile
here takes effect immediately, no rebuild needed.

## Homebrew packages

Taps, formulae, and casks are declared in `darwin/homebrew.nix` and synced by
`nix run .#switch` (via `brew bundle`; Homebrew itself must be installed).
Add or remove packages by editing that file. Activation does not uninstall
undeclared packages (`onActivation.cleanup = "none"`), so when removing one,
also run `brew uninstall`.

The remaining `Brewfile` holds only entries the module cannot express:
VS Code extensions (`brew bundle --file=Brewfile`) and a commented-out
go/npm install memo.

## Claude Code plugins

Generic and personal skills live in two plugin marketplaces instead of
`.claude/skills/`:

- [valbeat/claude-plugins](https://github.com/valbeat/claude-plugins)
  (public) — `writing`, `design`, `git-workflow`, `dev-workflow`,
  `skill-tools`
- [valbeat/claude-plugins-private](https://github.com/valbeat/claude-plugins-private)
  (private) — `personal-tools`

Skills are invoked with plugin namespaces (e.g. `/git-workflow:commit`,
`/dev-workflow:spec`). Environment-coupled skills (cmux, herdr, iterm2,
hunk-review, etc.) remain in `.claude/skills/` here.

### Setup on a new machine

The private marketplace requires SSH access to GitHub (or `gh auth login`)
to work first. Then:

```shell
cd $HOME/dotfiles && git pull   # syncs .claude/settings.json via symlink
```

`extraKnownMarketplaces` and `enabledPlugins` in `.claude/settings.json`
declare everything; Claude Code picks them up on next launch. If plugins do
not install automatically:

```shell
claude plugin marketplace add valbeat/claude-plugins
claude plugin marketplace add valbeat/claude-plugins-private
claude plugin install writing@valbeat-plugins        # repeat for the rest
claude plugin list                                   # verify all 6 enabled
```

### Updating skills

Edit skills in the marketplace clones
(`~/src/github.com/valbeat/claude-plugins{,-private}`), not here. After
pushing, sync each machine with:

```shell
claude plugin marketplace update
claude plugin update
```

Plugins declare a `version` in `plugin.json`; `update` skips a plugin until
its version is bumped, so bump it when releasing changes. Dotfiles-resident
skills still sync via plain `git pull`. For background auto-update of the
private marketplace, set `GITHUB_TOKEN` in the environment; manual
`marketplace update` needs no token.

## nix-darwin

macOS system settings (`darwin/system-defaults.nix`), dotfile symlinks
(`darwin/home.nix`, via home-manager), and Homebrew packages
(`darwin/homebrew.nix`) are managed declaratively with
[nix-darwin](https://github.com/nix-darwin/nix-darwin). This host uses
Determinate Nix, so nix-darwin's own Nix management is disabled
(`nix.enable = false`).

The flake exposes one configuration per host under `darwinConfigurations` in
`flake.nix`; the attribute name must match `scutil --get LocalHostName`.
Forks should add their own entry, and adjust `dotfilesDir` in
`darwin/home.nix` if the repo is cloned somewhere else.

Flake apps (run from the repo root):

| command | what it does |
| --- | --- |
| `nix run .#switch` | build and activate the system for this host (runs as root) |
| `nix run .#build` | dry-run build without activating; CI runs this on every PR |
| `nix run .#update` | pull the latest `main` and sync submodules |

Activation must run as root; `.#switch` wraps `sudo darwin-rebuild switch`.
On a machine that does not have `darwin-rebuild` yet, bootstrap once with:

```shell
MY_HOST=$(scutil --get LocalHostName)
sudo nix run nix-darwin -- switch --flake ".#$MY_HOST"
```

(`HOST` is read-only in zsh, so a different variable name is used.)

Roll back with `sudo darwin-rebuild --rollback`. The
`$HOME ... is not owned by you` warning printed under `sudo` is benign —
the flake still evaluates and every setting is applied correctly.

## Contribution

1. Fork ([https://github.com/valbeat/dotfiles/fork](https://github.com/valbeat/dotfiles/fork))
1. Create a feature branch
1. Commit your changes
1. Rebase your local changes against the `main` branch
1. Create a new Pull Request

## Author

[valbeat](https://github.com/valbeat)
