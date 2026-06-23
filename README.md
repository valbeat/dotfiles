# dotfiles

## Installing

```shell
$ git clone git@github.com:valbeat/dotfiles.git $HOME/dotfiles
$ cd $HOME/dotfiles
$ make install
```
This will create symlinks from this repo to your home folder.

## Homebrew packages

Install the packages declared in the `Brewfile`:

```shell
$ make brew
```

After installing or removing packages, refresh the `Brewfile`:

```shell
$ make brew-dump
```

`brew-dump` regenerates the whole `Brewfile` from the current environment.
Redundant built-in taps are stripped automatically, but EOL/deprecated
packages reappear if they are still installed. Review `git diff Brewfile`
after running it, and use `brew uninstall` to remove unwanted packages from
the system rather than only deleting their lines here.

## nix-darwin (experimental, Phase 1)

macOS system settings are being migrated from the imperative `.osx` script to
declarative [nix-darwin](https://github.com/nix-darwin/nix-darwin). Phase 1
covers `system.defaults` only; see [docs/nix-darwin-design.md](docs/nix-darwin-design.md)
for the full plan. `.osx` is kept until the migration is verified.

Prerequisites: install Nix (flakes enabled), e.g. the Determinate Systems installer:

```shell
$ /bin/sh -c "$(curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix)" -- install
```

Bootstrap once, then rebuild on changes:

```shell
$ nix run nix-darwin -- switch --flake ~/dotfiles#takumas-MacBook-Pro
$ darwin-rebuild switch --flake ~/dotfiles#takumas-MacBook-Pro
```

Roll back with `darwin-rebuild --rollback`.

## Contribution

1. Fork ([https://github.com/valbeat/dotfiles/fork](https://github.com/valbeat/dotfiles/fork))
1. Create a feature branch
1. Commit your changes
1. Rebase your local changes against the `main` branch
1. Create a new Pull Request

## Author

[valbeat](https://github.com/valbeat)
