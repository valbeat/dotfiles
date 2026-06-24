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

## nix-darwin

macOS system settings are managed declaratively with
[nix-darwin](https://github.com/nix-darwin/nix-darwin). The former `.osx`
script is migrated to `system.defaults` (Homebrew is the planned next phase).
This host uses Determinate Nix, so nix-darwin's own Nix management is disabled
(`nix.enable = false`).

Prerequisites: install Nix (flakes enabled), e.g. the Determinate Systems installer:

```shell
$ /bin/sh -c "$(curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix)" -- install
```

The flake exposes one configuration per host under `darwinConfigurations` in
`flake.nix`. Use your host name (`scutil --get LocalHostName`) in place of
`$HOST` below; a fork should add a matching entry in `flake.nix` first.

Activation must run as root. Bootstrap once with `nix run`, then use
`darwin-rebuild` for subsequent changes (run from the repository directory so
the `.` flake reference resolves):

```shell
$ HOST=$(scutil --get LocalHostName)
$ sudo nix run nix-darwin -- switch --flake ".#$HOST"
$ sudo darwin-rebuild switch --flake ".#$HOST"
```

Roll back with `sudo darwin-rebuild --rollback`.

Recent nix-darwin no longer auto-escalates, so activation must run as root
(`darwin-rebuild` prints `system activation must now be run as root` otherwise).
The `$HOME ... is not owned by you` warning printed under `sudo` is benign —
the flake still evaluates and every setting is applied correctly.

## Contribution

1. Fork ([https://github.com/valbeat/dotfiles/fork](https://github.com/valbeat/dotfiles/fork))
1. Create a feature branch
1. Commit your changes
1. Rebase your local changes against the `main` branch
1. Create a new Pull Request

## Author

[valbeat](https://github.com/valbeat)
