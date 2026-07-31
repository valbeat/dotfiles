# home-manager configuration: declarative replacement for `make deploy`.
#
# Every entry below becomes a symlink in $HOME that ultimately resolves to
# this repository checkout (via mkOutOfStoreSymlink), so editing a dotfile
# in the repo takes effect immediately — no rebuild needed. This matches the
# `ln -sfnv` behavior the Makefile provided.
{ config, ... }:
let
  # Absolute path to this repository checkout. Must match where the repo is
  # cloned; forks cloned elsewhere should adjust this.
  dotfilesDir = "${config.home.homeDirectory}/src/github.com/valbeat/dotfiles";

  # Mirrors the Makefile's DOTFILES list: every `.??*` entry in the repo root
  # except .DS_Store, .git, .gitmodules, and .github.
  dotfiles = [
    ".claude"
    ".coderabbit.yaml"
    ".codex"
    ".config"
    ".gemini"
    ".gitconfig"
    ".gitconfig.local" # machine-local override, intentionally untracked
    ".gitconfig.osx"
    ".gitignore"
    ".gitignore_global"
    ".gvimrc"
    ".ideavimrc"
    ".screenrc"
    ".tigrc"
    ".tmux.conf"
    ".vim"
    ".vimrc"
    ".zshrc"
  ];
in
{
  home.file = builtins.listToAttrs (
    map (name: {
      inherit name;
      value.source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${name}";
    }) dotfiles
  );

  # Used for backwards compatibility of stateful data. Bump only with care.
  home.stateVersion = "25.05";
}
