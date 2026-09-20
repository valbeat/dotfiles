# home-manager module: apply Orca automation definitions at activation.
#
# The definitions live in the private repository valbeat/orca-automations
# (flake input `orca-automations`), which is the single source of truth. Its
# scripts/apply.sh makes Orca match the repository and refuses to overwrite
# anything that was changed in Orca but not written back to the repository
# (run scripts/export.sh in a clone of that repository and open a PR first).
#
# To pick up merged changes: `nix flake update orca-automations`, then switch.
# Orca not running is a warning, not a failed switch.
{
  lib,
  pkgs,
  orca-automations,
  orcaHostRole,
  ...
}:
{
  # Which automations belong to this Mac. The repository is the same on every
  # host, but a definition that opens PRs or writes reports must fire on one of
  # them only, so each definition names the roles it runs under (default
  # "primary") and only the matching ones reach this machine's Orca.
  #
  # apply.sh takes the role from the environment below; the file is what the
  # manual commands (scripts/check.sh, scripts/export.sh, run in a clone) read.
  # It sits next to that repository's own per-machine state rather than under
  # ~/.config, which is a symlink into this checkout — the role is machine
  # specific and has no business in a public repository.
  home.file.".local/state/orca-automations/role".text = orcaHostRole + "\n";

  home.activation.orcaAutomations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ -n "''${DRY_RUN:-}" ]]; then
      echo "would apply Orca automations from ${orca-automations} (role: ${orcaHostRole})"
    elif ! PATH="${
      lib.makeBinPath [
        pkgs.jq
        pkgs.git
        pkgs.coreutils
      ]
    }:$PATH" \
        ORCA_AUTOMATIONS_ROOT="${orca-automations}" \
        ORCA_AUTOMATIONS_HOST_ROLE="${orcaHostRole}" \
        ${pkgs.bash}/bin/bash "${orca-automations}/scripts/apply.sh"; then
      echo "orca-automations: not applied (see above). The rest of the switch continued." >&2
    fi
  '';
}
