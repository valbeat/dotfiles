# Fold the Nix-managed Claude Code settings into the live settings.json.
#
#   jq --argjson managed "$MANAGED_JSON" -f merge.jq ~/.claude/settings.json
#
# Input  (.)        the live document Claude Code and other tools write to.
# Arg    ($managed) the document generated from darwin/claude.nix.
#
# Precedence: managed > live. Anything the managed document does not name
# (model, autoMode, feedbackSurveyState, future keys) passes through untouched,
# so runtime writes survive `nix run .#switch`. Two exceptions to plain
# recursive merge:
#
#   permissions.allow / deny  replaced wholesale by the managed lists — the
#                             policy is the policy, not a union of whatever
#                             accumulated on this machine.
#   hooks                     unioned per event and deduplicated, so entries
#                             injected at runtime (Orca's agent-status hooks)
#                             are kept alongside the managed ones. On a
#                             collision the managed entry wins and comes first.
#
# The filter is idempotent: applying it to its own output is a no-op.
# Tests: tools/tests/test-merge-settings.sh

# Identity of a hook entry: its matcher plus the sorted set of commands it runs.
def hook_key: [(.matcher // ""), ([.hooks[]?.command] | sort)];

# Append entries from $extra whose key is not already present, keeping order.
def union_hooks($extra):
  reduce $extra[] as $e (.;
    if any(.[]; hook_key == ($e | hook_key)) then . else . + [$e] end);

. as $live
| ($live * $managed)
| .hooks = (
    ($live.hooks // {}) as $lh
    | ($managed.hooks // {}) as $mh
    | reduce (($mh | keys) + ($lh | keys) | unique)[] as $event ({};
        .[$event] = (($mh[$event] // []) | union_hooks($lh[$event] // [])))
  )
| if .hooks == {} then del(.hooks) else . end
