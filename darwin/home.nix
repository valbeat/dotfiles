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
    ".coderabbit.yaml"
    ".config"
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

  # The agent home directories (~/.claude, ~/.codex, ~/.gemini) are NOT linked
  # as directories: the tools write gigabytes of runtime state (sessions,
  # plugins, logs) into whatever directory they find there, and linking the
  # directory puts all of it in this working tree. Only the files this
  # repository owns are linked, so the surrounding directory stays a real one
  # under $HOME. tools/migrate-agent-dirs.sh converts an existing whole-directory
  # link. (#143 / #115)
  agentFiles = [
    ".claude/agents"
    ".claude/CLAUDE.md"
    ".claude/hooks"
    ".claude/statusline.sh"
    ".codex/AGENTS.md"
    ".gemini/GEMINI.md"
  ];

  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  imports = [
    ./claude.nix
    ./orca.nix
  ];

  home.file = builtins.listToAttrs (
    map (name: {
      inherit name;
      value.source = link name;
    }) (dotfiles ++ agentFiles)
  );

  # Used for backwards compatibility of stateful data. Bump only with care.
  home.stateVersion = "25.05";
}
