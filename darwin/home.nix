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
    ".claude/hooks"
    ".claude/statusline.sh"
  ];

  # The user-level instructions are a single file shared by all three agents.
  # Each tool looks for a different name in a different directory, so the same
  # source is linked three times ($HOME path -> repository path).
  #
  # It deliberately does not live at .claude/CLAUDE.md in this repository:
  # Claude Code counts a ./CLAUDE.md or ./.claude/CLAUDE.md in the checkout as
  # *this repository's* project instructions and then never falls back to
  # ./AGENTS.md, which is the only project instruction file this repo keeps.
  globalInstructions = {
    ".claude/CLAUDE.md" = "agents/AGENTS.md";
    ".codex/AGENTS.md" = "agents/AGENTS.md";
    ".gemini/GEMINI.md" = "agents/AGENTS.md";
  };

  # ~/.config is shared with every other tool that follows the XDG convention
  # (gh, gcloud, fish, karabiner, git, ...), so it gets the same treatment as
  # the agent directories above: link the entries this repository owns, never
  # the directory itself. Linking ~/.config as a whole hides every unmanaged
  # entry — home-manager moves the real directory to ~/.config.hm-backup — and
  # tools silently lose their configuration and credentials.
  # Mirrors the `.config/*` allow-list in .gitignore.
  configFiles = [
    ".config/cmux"
    ".config/ghostty"
    ".config/yazi"
  ];

  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  imports = [
    ./claude.nix
    ./orca.nix
  ];

  home.file =
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value.source = link name;
      }) (dotfiles ++ agentFiles ++ configFiles)
    )
    // builtins.mapAttrs (_: path: { source = link path; }) globalInstructions;

  # Used for backwards compatibility of stateful data. Bump only with care.
  home.stateVersion = "25.05";
}
