#!/bin/bash
# Decide a budget tier from the 7d rate-limit pace.
#
# Asks Anthropic for the current utilisation and answers one question: are we
# far enough ahead of the weekly burn rate to justify spending more?
#
#   pace.sh          -> tier=L1 pace=+18.3 used=31.2 elapsed=49.5 left=68.8 reason=ok
#   pace.sh tier     -> L1
#
# Always exits 0. Callers run under `set -e`; the verdict travels in `tier=`,
# never in the exit status. Anything unknown resolves to L0 (change nothing).

# All percentages are integers in tenths of a percent, so no float ever reaches
# bash arithmetic. 1000 == 100.0%.
# pace can never exceed (100 - final weekly usage), so a threshold above that
# is unreachable rather than merely strict: at a 83% week, pace tops out at
# +17 and a +30 tier would never once fire. Half a day and one day of banked
# budget keep both tiers live for realistic usage.
L1_X10="${RATE_PACE_L1_X10:-70}"               # +7.0pt  ~= half a day of weekly budget
L2_X10="${RATE_PACE_L2_X10:-140}"              # +14.0pt ~= one day
# Measured, not assumed: a real rollover was observed on 2026-08-02 and the
# window came back to exactly 604800s. See the sanity check below.
WINDOW=604800
ENDPOINT="${RATE_PACE_ENDPOINT:-https://api.anthropic.com/api/oauth/usage}"

MODE="${1:-full}"

fmt() {  # tenths -> "12.3"; pass a second arg to force a leading +
    local v=$1 sign=''
    [ "$v" -lt 0 ] && { sign='-'; v=$(( -v )); }
    [ -n "$2" ] && [ "$sign" = '' ] && sign='+'
    printf '%s%d.%d' "$sign" $((v / 10)) $((v % 10))
}

emit() {  # tier pace_x10 used_x10 elapsed_x10 left_x10 reason
    if [ "$MODE" = tier ]; then
        printf '%s\n' "$1"
    else
        printf 'tier=%s pace=%s used=%s elapsed=%s left=%s reason=%s\n' \
            "$1" "$(fmt "$2" +)" "$(fmt "$3")" "$(fmt "$4")" "$(fmt "$5")" "$6"
    fi
    exit 0
}
unknown() { emit L0 0 0 0 0 "$1"; }

command -v jq >/dev/null 2>&1 || unknown nojq

# --- Fetch ---
# RATE_PACE_USAGE_JSON short-circuits the network for tests.
if [ -n "$RATE_PACE_USAGE_JSON" ]; then
    BODY=$(cat "$RATE_PACE_USAGE_JSON" 2>/dev/null) || unknown nofixture
else
    command -v security >/dev/null 2>&1 || unknown nokeychain
    TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
            | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    [ -n "$TOKEN" ] || unknown notoken
    # The header goes through a config file on stdin, never argv: anything on a
    # command line is world-readable via ps.
    BODY=$(printf 'header = "Authorization: Bearer %s"\nheader = "Accept: application/json"\nsilent\nfail\nmax-time = 5\n' "$TOKEN" \
           | curl --config - "$ENDPOINT" 2>/dev/null)
    # A 401 means Claude Code has not refreshed the token yet. Do not try to
    # refresh it here — owning the auth state from outside the app is a far
    # worse failure mode than skipping one upgrade.
    [ -n "$BODY" ] || unknown fetch_failed
fi

# --- Parse ---
# Only UTC timestamps are accepted; a non-zero offset would silently skew the
# elapsed fraction, so treat it as unparseable instead of guessing.
read -r USED_X10 RESETS_AT <<< "$(printf '%s' "$BODY" | jq -r '
    .seven_day as $s
    | ($s.resets_at // "") as $r
    | if ($r | test("(\\+00:00|Z)$")) then
        [ (($s.utilization // 0) * 10 | round),
          ($r | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) ]
        | @tsv
      else empty end' 2>/dev/null)"

case "$USED_X10" in ''|*[!0-9-]*) unknown unparseable ;; esac
case "$RESETS_AT" in ''|*[!0-9-]*) unknown unparseable ;; esac

# --- Pace ---
NOW=$(date +%s)
rem=$((RESETS_AT - NOW))
[ "$rem" -lt 0 ] && rem=0
# If more than a full window remains, the 7d limit is not the fixed 7-day window
# this maths assumes. (A rolling window needs no guard: `remaining` would stay
# pinned near the maximum, elapsed would sit at ~0, and pace could never clear
# the L1 bar — it fails closed on its own.)
[ "$rem" -gt "$WINDOW" ] && unknown window_longer

elapsed_x10=$(( (WINDOW - rem) * 1000 / WINDOW ))
[ "$elapsed_x10" -lt 0 ] && elapsed_x10=0
[ "$elapsed_x10" -gt 1000 ] && elapsed_x10=1000
pace_x10=$((elapsed_x10 - USED_X10))
left_x10=$((1000 - USED_X10))
[ "$left_x10" -lt 0 ] && left_x10=0

if [ "$pace_x10" -ge "$L2_X10" ]; then
    emit L2 "$pace_x10" "$USED_X10" "$elapsed_x10" "$left_x10" ok
elif [ "$pace_x10" -ge "$L1_X10" ]; then
    emit L1 "$pace_x10" "$USED_X10" "$elapsed_x10" "$left_x10" ok
fi
emit L0 "$pace_x10" "$USED_X10" "$elapsed_x10" "$left_x10" ok
