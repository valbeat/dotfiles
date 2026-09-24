# home-manager module: this Mac's role for the Orca automations.
#
# The automation definitions live in the private repository
# valbeat/orca-automations, which is the single source of truth. That
# repository's launchd agent (registered once with its scripts/install.sh)
# pulls origin/main every hour and applies it to Orca; nothing here runs at
# activation. Never change automations only in Orca: its scripts/export.sh
# writes them back for a pull request, and an unexported change stops the
# apply with a conflict.
{ orcaHostRole, ... }:
{
  # Which automations belong to this Mac. The repository is the same on every
  # host, but a definition that opens PRs or writes reports must fire on one of
  # them only, so each definition names the roles it runs under (default
  # "primary") and only the matching ones reach this machine's Orca.
  #
  # The role is a fact about the machine, so it is written from here (the
  # host's orcaHostRole in flake.nix) and read by that repository's scripts.
  # It sits next to the repository's own per-machine state rather than under
  # ~/.config, which is a symlink into this checkout.
  home.file.".local/state/orca-automations/role".text = orcaHostRole + "\n";
}
