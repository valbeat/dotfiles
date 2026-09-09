#!/usr/bin/env bash
# Regression tests for darwin/claude/merge.jq — the filter that folds the
# Nix-managed Claude Code settings into the live ~/.claude/settings.json at
# home-manager activation.
#
# Contract under test:
#   - managed keys win (permissions, own hooks, plugins, UI prefs)
#   - keys the managed set does not name survive (model, autoMode, ...)
#   - permissions.allow / deny are replaced wholesale, never unioned
#   - hooks are unioned per event, deduplicated by (matcher, commands),
#     so entries injected at runtime (Orca) are preserved
#   - applying the filter twice yields the same document (idempotent)
#   - an empty live document yields exactly the managed document
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
filter="$here/../../darwin/claude/merge.jq"
tmp=$(mktemp -d)
trap 'rm -r -- "$tmp"' EXIT

fail=0
assert() { # assert <name> <file> <jq-expr>
  if jq -e "$3" "$2" >/dev/null 2>&1; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL %s\n     expr: %s\n' "$1" "$3"; fail=1
  fi
}

cat > "$tmp/live.json" <<'JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Read", "Bash", "Task"],
    "deny": ["Bash(sudo dd *)"],
    "ask": ["Bash(git push:*)"],
    "defaultMode": "default"
  },
  "model": "fable[1m]",
  "autoMode": { "allow": ["$defaults"], "environment": ["**Organization**: secret-corp"] },
  "feedbackSurveyState": { "lastShownTime": 1 },
  "theme": "light",
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash|Write|Edit|MultiEdit",
        "hooks": [ { "type": "command", "command": "~/.claude/hooks/guard.sh", "timeout": 5 } ] },
      { "matcher": "*",
        "hooks": [ { "type": "command", "command": "if [ -f \"${HOME-}/.orca/agent-hooks/claude-hook.sh\" ]; then /bin/sh \"${HOME-}/.orca/agent-hooks/claude-hook.sh\"; fi", "timeout": 10 } ] }
    ],
    "SubagentStart": [
      { "matcher": "*",
        "hooks": [ { "type": "command", "command": "if [ -f \"${HOME-}/.orca/agent-hooks/claude-hook.sh\" ]; then /bin/sh \"${HOME-}/.orca/agent-hooks/claude-hook.sh\"; fi", "timeout": 10 } ] }
    ]
  }
}
JSON

cat > "$tmp/managed.json" <<'JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Read", "Write"],
    "deny": ["Bash(sudo dd *)", "Read(.env)"],
    "defaultMode": "auto"
  },
  "theme": "dark-daltonized",
  "language": "Japanese",
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash|Write|Edit|MultiEdit",
        "hooks": [ { "type": "command", "command": "~/.claude/hooks/guard.sh", "timeout": 30 } ] },
      { "matcher": "*",
        "hooks": [ { "type": "command", "command": "/Users/me/.config/iterm2/cc-status", "async": true } ] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit|MultiEdit",
        "hooks": [ { "type": "command", "command": "~/.claude/hooks/format.sh" } ] }
    ]
  }
}
JSON

merge() { jq --argjson managed "$(cat "$2")" -f "$filter" "$1"; }

merge "$tmp/live.json" "$tmp/managed.json" > "$tmp/out.json"
merge "$tmp/out.json"  "$tmp/managed.json" > "$tmp/out2.json"
echo '{}' > "$tmp/empty.json"
merge "$tmp/empty.json" "$tmp/managed.json" > "$tmp/from-empty.json"

o="$tmp/out.json"
# managed wins
assert "permissions.allow replaced wholesale"      "$o" '.permissions.allow == ["Read","Write"]'
assert "permissions.deny replaced wholesale"       "$o" '.permissions.deny == ["Bash(sudo dd *)","Read(.env)"]'
assert "permissions.defaultMode managed"           "$o" '.permissions.defaultMode == "auto"'
assert "permissions.ask (unmanaged) preserved"     "$o" '.permissions.ask == ["Bash(git push:*)"]'
assert "scalar pref managed wins"                  "$o" '.theme == "dark-daltonized"'
assert "managed-only key added"                    "$o" '.language == "Japanese"'
# live-only state survives
assert "model preserved"                           "$o" '.model == "fable[1m]"'
assert "autoMode preserved verbatim"               "$o" '.autoMode.environment == ["**Organization**: secret-corp"]'
assert "feedbackSurveyState preserved"             "$o" '.feedbackSurveyState.lastShownTime == 1'
# hooks: union, dedup, managed version wins on collision
assert "PreToolUse has exactly 3 entries"          "$o" '.hooks.PreToolUse | length == 3'
assert "guard.sh not duplicated, managed timeout"  "$o" '[.hooks.PreToolUse[] | select(.hooks[0].command == "~/.claude/hooks/guard.sh")] | length == 1 and .[0].hooks[0].timeout == 30'
assert "managed entries come first"                "$o" '.hooks.PreToolUse[0].hooks[0].command == "~/.claude/hooks/guard.sh" and .hooks.PreToolUse[1].hooks[0].command == "/Users/me/.config/iterm2/cc-status"'
assert "runtime-injected (Orca) PreToolUse kept"   "$o" '[.hooks.PreToolUse[] | select(.hooks[0].command | test("agent-hooks/claude-hook"))] | length == 1'
assert "live-only event SubagentStart kept"        "$o" '.hooks.SubagentStart | length == 1'
assert "managed-only event PostToolUse added"      "$o" '.hooks.PostToolUse[0].hooks[0].command == "~/.claude/hooks/format.sh"'
# idempotent
assert "second application is a no-op"             "$tmp/out2.json" "$(printf '. == %s' "$(cat "$o")")"
# bootstrap
assert "empty live yields managed"                 "$tmp/from-empty.json" "$(printf '. == %s' "$(cat "$tmp/managed.json")")"

exit $fail
