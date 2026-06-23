{ ... }:
{
  imports = [
    ./system-defaults.nix
  ];

  # Platform / user
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "takuma";
  users.users.takuma.home = "/Users/takuma";

  # This host uses Determinate Nix, which manages the Nix installation with
  # its own daemon. Disable nix-darwin's native Nix management to avoid the
  # conflict. (nix-command/flakes are already enabled by Determinate, so the
  # `nix.*` settings options are intentionally not used here.)
  nix.enable = false;

  # Manage /etc/zshrc so the nix environment is on PATH.
  # The existing ~/.zshrc is sourced afterwards and stays untouched.
  programs.zsh.enable = true;

  # Used for backwards compatibility of stateful data. Bump only with care.
  system.stateVersion = 5;
}
