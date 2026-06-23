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
      # Bootstrap: nix run nix-darwin -- switch --flake ~/dotfiles#takumas-MacBook-Pro
      # Thereafter: darwin-rebuild switch --flake ~/dotfiles#takumas-MacBook-Pro
      darwinConfigurations."takumas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./darwin/configuration.nix ];
      };
    };
}
