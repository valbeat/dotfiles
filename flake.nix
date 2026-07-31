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
      # Forks: add your own host here. For Intel, set `system = "x86_64-darwin"`
      # AND `nixpkgs.hostPlatform` in darwin/configuration.nix to match.
      darwinConfigurations."takumas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./darwin/configuration.nix ];
      };

      apps.aarch64-darwin =
        let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          app = name: script: {
            type = "app";
            program = toString (pkgs.writeShellScript name script);
          };
        in
        {
          # `nix run .#build` — dry-run build of the darwin system without activating.
          # Used by CI (.github/workflows/nix-build.yml) and as a local preflight check.
          build = app "build-dry-run" ''
            exec nix build --dry-run --no-link \
              "${self}#darwinConfigurations.takumas-MacBook-Pro.system" "$@"
          '';

          # `nix run .#switch` — build and activate the darwin system for this host.
          # Activation must run as root; the host name comes from LocalHostName so
          # forks with their own darwinConfigurations entry can use it as-is.
          switch = app "darwin-switch" ''
            exec sudo darwin-rebuild switch \
              --flake "${self}#$(scutil --get LocalHostName)" "$@"
          '';

          # `nix run .#update` — pull the latest main and sync submodules to their
          # remote default branches (replaces `make update`). Run from the repo root.
          update = app "repo-update" ''
            set -euo pipefail
            git pull origin main
            git submodule update --init --remote
          '';
        };
    };
}
