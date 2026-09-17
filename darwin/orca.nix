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
  ...
}:
{
  home.activation.orcaAutomations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ -n "''${DRY_RUN:-}" ]]; then
      echo "would apply Orca automations from ${orca-automations}"
    elif ! PATH="${lib.makeBinPath [ pkgs.jq pkgs.git pkgs.coreutils ]}:$PATH" \
        ORCA_AUTOMATIONS_ROOT="${orca-automations}" \
        ${pkgs.bash}/bin/bash "${orca-automations}/scripts/apply.sh"; then
      echo "orca-automations: not applied (see above). The rest of the switch continued." >&2
    fi
  '';
}
