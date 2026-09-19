{
  description = "valbeat dotfiles - nix-darwin configuration (Phase 1: system defaults)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Orca automation definitions (private). Fetched over SSH with the user's
    # key. CI does not fetch it: it overrides this input with
    # ci/orca-automations-stub (.github/workflows/nix-build.yml). See darwin/orca.nix.
    orca-automations = {
      url = "git+ssh://git@github.com/valbeat/orca-automations.git";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      orca-automations,
    }:
    {
      # One entry per host; the attribute name must match `scutil --get LocalHostName`.
      # Forks: add your own host here. For Intel, set `system = "x86_64-darwin"`
      # AND `nixpkgs.hostPlatform` in darwin/configuration.nix to match.
      darwinConfigurations."takumas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Files already in the way (e.g. symlinks made by `make deploy`)
            # are renamed with this suffix instead of aborting activation.
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.takuma = import ./darwin/home.nix;
            home-manager.extraSpecialArgs = { inherit orca-automations; };
          }
        ];
      };

      # `nix fmt` formats every .nix file with nixfmt (RFC 166 style); CI runs
      # `nix fmt -- --ci` to fail on unformatted files.
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;

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
          #
          # Inputs are fetched first as the invoking user: the private
          # orca-automations input needs the user's SSH key, which root (under
          # sudo) does not have. Root then finds the locked inputs already in
          # the store.
          switch = app "darwin-switch" ''
            set -e
            nix flake archive "${self}" >/dev/null
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

          # `nix run .#test` — run the repo tests (tools/tests/test-*.sh).
          # Replaces `make test`. The scripts come from the flake source, so a
          # *new* test file must be `git add`ed before it is picked up
          # (modifications to tracked files are seen without committing).
          test = app "repo-tests" ''
            status=0
            for t in ${self}/tools/tests/test-*.sh; do
              echo "== $(basename "$t")"
              bash "$t" || status=1
            done
            exit $status
          '';

          # `nix run .#settings-diff` — show which managed keys the next switch
          # would reset in the live settings.json files. Replaces
          # `make settings-diff`.
          settings-diff = app "settings-diff" ''
            exec bash "${self}/tools/settings-diff.sh" "$@"
          '';

          # `nix run .#patches` — apply the `claude -p` replacement patches to
          # the plugin caches (idempotent). Replaces `make patches`.
          patches = app "apply-patches" ''
            exec bash "${self}/tools/patches/apply.sh" "$@"
          '';

          # `nix run .#hunk-skill` — re-sync the vendored hunk-review skill into
          # agent-plugins-private from the installed hunk. Replaces
          # `make hunk-skill`.
          hunk-skill = app "sync-hunk-skill" ''
            set -euo pipefail
            plugins=''${PLUGINS_PRIVATE:-$HOME/src/github.com/valbeat/agent-plugins-private}
            dest=$plugins/plugins/portable-tools/skills/hunk-review/SKILL.md
            cp "$(hunk skill path)" "$dest"
            echo "Synced $dest from $(hunk --version)"
            echo "Bump portable-tools version (both .claude-plugin and .codex-plugin plugin.json) in agent-plugins-private and open a PR to ship it."
          '';
        };
    };
}
