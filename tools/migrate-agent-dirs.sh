#!/usr/bin/env bash
# Turn ~/.claude, ~/.codex and ~/.gemini from whole-directory symlinks into real
# directories that hold only runtime state, with this repository's tracked files
# linked in individually (what darwin/home.nix does after #143).
#
#   tools/migrate-agent-dirs.sh            show what would move (default)
#   tools/migrate-agent-dirs.sh --apply    do it
#
# Why: while ~/.claude is a symlink to this checkout, every agent writes its
# runtime state (sessions, plugins, projects, logs — gigabytes) into the git
# working tree, which is what .gitignore's allow-lists exist to hide (#115).
#
# Safe to re-run: a directory that is already migrated is reported and skipped.
# Nothing is deleted — entries are moved, and the tracked ones are linked so the
# tools keep working between this script and the next `nix run .#switch`.
set -euo pipefail

REPO="${MIGRATE_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TARGET_HOME="${MIGRATE_HOME:-$HOME}"
DIRS=("${MIGRATE_DIRS:-.claude .codex .gemini}")
read -r -a DIRS <<< "${DIRS[0]}"

apply=0
[ "${1:-}" = "--apply" ] && apply=1

say() { printf '%s\n' "$*"; }
run() { if [ "$apply" = 1 ]; then "$@"; else printf '  would:'; printf ' %q' "$@"; printf '\n'; fi; }

status=0
for dir in "${DIRS[@]}"; do
  live="$TARGET_HOME/$dir"
  src="$REPO/$dir"
  say "== $live"

  if [ ! -e "$live" ] && [ ! -L "$live" ]; then
    say "  skip: does not exist"
    continue
  fi

  if [ ! -L "$live" ]; then
    if [ -d "$live" ]; then say "  ok: already a real directory"; else say "  skip: not a directory"; status=1; fi
    continue
  fi

  resolved=$(cd "$live" 2>/dev/null && pwd -P || true)
  if [ -z "$resolved" ]; then
    say "  skip: broken symlink"
    status=1
    continue
  fi
  if [ "$resolved" != "$(cd "$src" 2>/dev/null && pwd -P || echo "")" ]; then
    say "  skip: symlink does not point at $src (points at $resolved)"
    status=1
    continue
  fi

  # Top-level entries this repository tracks: they stay in the repository and
  # get linked back individually. Everything else is runtime state and moves.
  mapfile -t tracked < <(git -C "$REPO" ls-files "$dir" | cut -d/ -f2 | sort -u)
  say "  tracked (stay in repo, linked back): ${tracked[*]:-none}"

  moved=()
  for entry in "$src"/* "$src"/.[!.]*; do
    [ -e "$entry" ] || continue
    name=$(basename "$entry")
    skip=0
    for t in "${tracked[@]}"; do [ "$name" = "$t" ] && skip=1; done
    [ "$skip" = 1 ] && continue
    moved+=("$name")
  done
  say "  runtime entries to move: ${#moved[@]}"

  # The symlink has to go first: with it in place, writing into $live writes
  # into the repository.
  run rm "$live"
  run mkdir -p "$live"
  for name in "${moved[@]}"; do
    run mv "$src/$name" "$live/$name"
  done
  # Bridge until the next switch: home-manager replaces these with the same links.
  for name in "${tracked[@]}"; do
    [ -e "$src/$name" ] || continue
    run ln -s "$src/$name" "$live/$name"
  done
done

if [ "$apply" = 0 ]; then
  say
  say "dry run. Re-run with --apply, then \`nix run .#switch\`."
fi
exit $status
