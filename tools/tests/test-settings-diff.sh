#!/usr/bin/env bash
# Tests for tools/settings-diff.sh — shows what the next `nix run .#switch`
# would change in a live settings file, given the Nix-generated JSON that the
# last switch left beside it.
#
#   settings-diff.sh <live.json> <nix.json>   exit 0: no drift
#                                              exit 1: drift, diff on stdout
#                                              exit 2: nix.json missing
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script="$here/../settings-diff.sh"
tmp=$(mktemp -d)
trap 'rm -r -- "$tmp"' EXIT

fail=0
check() { # check <name> <expected-exit> <cmd...>
  local name=$1 want=$2; shift 2
  out=$("$@" 2>"$tmp/err"); got=$?
  if [ "$got" -eq "$want" ]; then printf 'ok   %s\n' "$name"; else
    printf 'FAIL %s\n     exit: want %s got %s\n     stdout: %s\n     stderr: %s\n' \
      "$name" "$want" "$got" "$out" "$(cat "$tmp/err")"; fail=1; fi
}

cat > "$tmp/nix.json" <<'JSON'
{ "theme": "dark", "permissions": { "allow": ["Read"], "deny": ["Read(.env)"] },
  "hooks": { "PreToolUse": [ { "hooks": [ { "type": "command", "command": "~/.claude/hooks/guard.sh" } ] } ] } }
JSON

# live == what switch would produce -> no drift, even with runtime-only keys
cat > "$tmp/live-clean.json" <<'JSON'
{ "theme": "dark", "permissions": { "allow": ["Read"], "deny": ["Read(.env)"] },
  "hooks": { "PreToolUse": [ { "hooks": [ { "type": "command", "command": "~/.claude/hooks/guard.sh" } ] },
                             { "matcher": "*", "hooks": [ { "type": "command", "command": "orca-hook" } ] } ] },
  "model": "fable[1m]", "autoMode": { "allow": ["$defaults"] } }
JSON
check "no drift -> exit 0, no output" 0 bash "$script" "$tmp/live-clean.json" "$tmp/nix.json"
if [ -z "$out" ]; then printf 'ok   no drift prints nothing\n'; else printf 'FAIL no drift printed: %s\n' "$out"; fail=1; fi

# managed key changed locally (/config) and a deny rule added by hand -> drift
cat > "$tmp/live-drift.json" <<'JSON'
{ "theme": "light", "permissions": { "allow": ["Read", "Bash"], "deny": ["Read(.env)"] },
  "hooks": { "PreToolUse": [ { "hooks": [ { "type": "command", "command": "~/.claude/hooks/guard.sh" } ] } ] },
  "model": "fable[1m]" }
JSON
check "drift -> exit 1" 1 bash "$script" "$tmp/live-drift.json" "$tmp/nix.json"
if grep -q '^-.*"light"' <<<"$out" && grep -q '^+.*"dark"' <<<"$out"; then
  printf 'ok   drift shows theme light -> dark\n'; else printf 'FAIL diff lacks theme change:\n%s\n' "$out"; fail=1; fi
if grep -q '^-.*"Bash"' <<<"$out"; then
  printf 'ok   drift shows allow entry that will be dropped\n'; else printf 'FAIL diff lacks Bash:\n%s\n' "$out"; fail=1; fi
if grep -q '^[-+].*fable' <<<"$out"; then
  printf 'FAIL unmanaged model key changed:\n%s\n' "$out"; fail=1; else printf 'ok   unmanaged model key unchanged\n'; fi

# nix.json missing (never switched) -> exit 2 with a hint
check "missing nix.json -> exit 2" 2 bash "$script" "$tmp/live-clean.json" "$tmp/does-not-exist.json"
if grep -q 'switch' "$tmp/err"; then printf 'ok   hint mentions switch\n'; else printf 'FAIL no switch hint\n'; fail=1; fi

# multiple pairs: exit 1 if any drifts
check "two pairs, one drifting -> exit 1" 1 bash "$script" \
  "$tmp/live-clean.json" "$tmp/nix.json" "$tmp/live-drift.json" "$tmp/nix.json"

exit $fail
