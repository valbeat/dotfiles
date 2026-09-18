#!/usr/bin/env bash
# Tests for tools/migrate-agent-dirs.sh against a throwaway repo and HOME.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
script="$here/../migrate-agent-dirs.sh"
fail=0
ok() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; fail=1; fi; }

setup() {  # -> prints the sandbox root
  local root
  root=$(mktemp -d)
  mkdir -p "$root/repo/.claude/agents" "$root/home"
  printf 'rules\n' > "$root/repo/.claude/CLAUDE.md"
  printf 'agent\n' > "$root/repo/.claude/agents/reviewer.md"
  git -C "$root/repo" init -q
  git -C "$root/repo" add .claude/CLAUDE.md .claude/agents/reviewer.md
  git -C "$root/repo" -c user.email=t@example.com -c user.name=t commit -qm init
  # runtime state written through the symlink, as the agents do today
  mkdir -p "$root/repo/.claude/projects" "$root/repo/.claude/plugins"
  printf 'memory\n' > "$root/repo/.claude/projects/memory.md"
  printf '{}\n' > "$root/repo/.claude/settings.json"
  ln -s "$root/repo/.claude" "$root/home/.claude"
  printf '%s' "$root"
}

run_migrate() { MIGRATE_REPO="$1/repo" MIGRATE_HOME="$1/home" MIGRATE_DIRS=".claude" bash "$script" "${2:-}"; }

# --- dry run changes nothing ---
root=$(setup)
out=$(run_migrate "$root")
tracked_line=$(grep 'tracked (stay in repo, linked back)' <<<"$out")
ok "dry run lists the tracked file"        "$(grep -c 'CLAUDE.md' <<<"$tracked_line")" 1
ok "dry run lists the tracked directory"   "$(grep -c 'agents' <<<"$tracked_line")" 1
ok "dry run counts the runtime entries"    "$(grep -c 'runtime entries to move: 3' <<<"$out")" 1
ok "dry run keeps the symlink"             "$( [ -L "$root/home/.claude" ] && echo yes || echo no)" yes
ok "dry run moves nothing"                 "$( [ -f "$root/repo/.claude/projects/memory.md" ] && echo yes || echo no)" yes
rm -rf "$root"

# --- apply ---
root=$(setup)
run_migrate "$root" --apply >/dev/null
ok "home dir is real after apply"          "$( [ -d "$root/home/.claude" ] && [ ! -L "$root/home/.claude" ] && echo yes || echo no)" yes
ok "runtime state moved to home"           "$( [ -f "$root/home/.claude/projects/memory.md" ] && echo yes || echo no)" yes
ok "runtime state left the repo"           "$( [ -e "$root/repo/.claude/projects" ] && echo yes || echo no)" no
ok "untracked settings.json moved"         "$( [ -f "$root/home/.claude/settings.json" ] && echo yes || echo no)" yes
ok "tracked file stays in the repo"        "$( [ -f "$root/repo/.claude/CLAUDE.md" ] && echo yes || echo no)" yes
ok "tracked file is linked from home"      "$(readlink "$root/home/.claude/CLAUDE.md")" "$root/repo/.claude/CLAUDE.md"
ok "tracked dir is linked from home"       "$(readlink "$root/home/.claude/agents")" "$root/repo/.claude/agents"
ok "repo working tree is clean"            "$(git -C "$root/repo" status --porcelain | wc -l | tr -d ' ')" 0

# --- idempotent ---
out=$(run_migrate "$root" --apply)
ok "second run reports already migrated"   "$(grep -c 'already a real directory' <<<"$out")" 1
ok "second run keeps the runtime state"    "$( [ -f "$root/home/.claude/projects/memory.md" ] && echo yes || echo no)" yes
rm -rf "$root"

# --- refuses to touch a symlink pointing somewhere else ---
root=$(setup)
rm "$root/home/.claude"
mkdir -p "$root/elsewhere"
ln -s "$root/elsewhere" "$root/home/.claude"
out=$(run_migrate "$root" --apply); rc=$?
ok "foreign symlink is skipped"            "$(grep -c 'symlink does not point at' <<<"$out")" 1
ok "foreign symlink exits non-zero"        "$rc" 1
ok "foreign symlink is untouched"          "$( [ -L "$root/home/.claude" ] && echo yes || echo no)" yes
rm -rf "$root"

# --- missing directory ---
root=$(setup)
rm "$root/home/.claude"
out=$(run_migrate "$root" --apply)
ok "missing home entry is skipped"         "$(grep -c 'does not exist' <<<"$out")" 1
rm -rf "$root"

exit $fail
