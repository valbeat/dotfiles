#!/usr/bin/env bash
# Show what the next `nix run .#switch` would change in the live Claude Code /
# Gemini settings files — i.e. managed keys you changed locally (via /config,
# `claude plugin install`, hand edits) that Nix will reset unless you port them
# to darwin/claude.nix.
#
# The comparison uses the same filter the activation runs
# (darwin/claude/merge.jq) against the Nix-generated JSON the last switch left
# beside each live file (settings.nix.json). Keys the module does not manage
# never show up. If darwin/claude.nix changed since the last switch, the copy
# is stale; switch (or `nix run .#build`) to refresh it.
#
#   settings-diff.sh                       check the default pairs
#   settings-diff.sh <live> <nix> [...]    check explicit pairs
#
# Exit: 0 no drift, 1 drift found (diff on stdout), 2 a nix.json is missing.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
filter="$here/../darwin/claude/merge.jq"

if [ $# -eq 0 ]; then
  set -- \
    "$HOME/.claude/settings.json" "$HOME/.claude/settings.nix.json" \
    "$HOME/.gemini/settings.json" "$HOME/.gemini/settings.nix.json"
fi
if [ $(( $# % 2 )) -ne 0 ]; then
  echo "usage: $0 [<live.json> <nix.json>]..." >&2
  exit 2
fi

status=0
while [ $# -gt 0 ]; do
  live=$1 nix=$2; shift 2
  if [ ! -f "$nix" ]; then
    echo "$nix: not found — run \`nix run .#switch\` once to generate it" >&2
    status=2; continue
  fi
  if [ ! -s "$live" ]; then
    echo "$live: missing or empty — switch will create it from $nix" >&2
    [ "$status" -eq 0 ] && status=1; continue
  fi
  expected=$(jq --argjson managed "$(cat "$nix")" -f "$filter" "$live") || { status=2; continue; }
  if ! out=$(diff -u --label "$live (now)" --label "$live (after switch)" \
              <(jq -S . "$live") <(jq -S . <<<"$expected")); then
    printf '%s\n' "$out"
    [ "$status" -eq 0 ] && status=1
  fi
done

exit $status
