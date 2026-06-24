{
  description = "valbeat dotfiles - nix-darwin configuration (Phase 1: system defaults)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, nix-darwin }:
    {
      # One entry per host; the attribute name must match `scutil --get LocalHostName`.
      # Forks: add your own host here (and adjust `system` for Intel: x86_64-darwin).
      darwinConfigurations."takumas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./darwin/configuration.nix ];
      };
    };
}
