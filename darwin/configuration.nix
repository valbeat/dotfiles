{ ... }:
{
  imports = [
    ./system-defaults.nix
  ];

  # Platform / user
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "takuma";
  users.users.takuma.home = "/Users/takuma";

  # Enable flakes for the nix command.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Manage /etc/zshrc so the nix environment is on PATH.
  # The existing ~/.zshrc is sourced afterwards and stays untouched.
  programs.zsh.enable = true;

  # Used for backwards compatibility of stateful data. Bump only with care.
  system.stateVersion = 5;
}
