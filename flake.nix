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

      # `nix run .#build` — dry-run build of the darwin system without activating.
      # Used by CI (.github/workflows/nix-build.yml) and as a local preflight check.
      apps.aarch64-darwin.build =
        let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "build-dry-run" ''
              exec nix build --dry-run --no-link \
                "${self}#darwinConfigurations.takumas-MacBook-Pro.system" "$@"
            ''
          );
        };
    };
}
