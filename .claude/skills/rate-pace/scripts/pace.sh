#!/bin/bash
# Decide a budget tier from the 7d rate-limit pace.
#
# Reads the cache that statusline.sh publishes and answers one question:
# are we far enough ahead of the weekly burn rate to justify spending more?
#
#   pace.sh          -> tier=L1 pace=+15.2 used=74.0 elapsed=89.2 left=26.0 age=4 conf=high reason=ok
#   pace.sh tier     -> L1
#
# Always exits 0. Callers run under `set -e`; the verdict travels in `tier=`,
# never in the exit status. Anything unknown resolves to L0 (change nothing).

CACHE="${RATE_PACE_CACHE:-$HOME/.claude/cache/rate-pace.tsv}"

# All percentages are integers in tenths of a percent, so no float ever reaches
# bash arithmetic. 1000 == 100.0%.
WINDOW=604800                                  # 7d, verified against resets_at
L1_X10="${RATE_PACE_L1_X10:-150}"              # +15.0pt ~= one day of weekly budget
L2_X10="${RATE_PACE_L2_X10:-300}"              # +30.0pt ~= two days
# No separate "budget left" floor is needed: elapsed never exceeds 100.0, so
# pace = elapsed - used <= 100 - used = left, identically. Clearing the L1 pace
# bar already guarantees at least that much of the week is unspent.
STALE_SOFT=300                                 # beyond this, never upgrade
STALE_HARD=1800                                # beyond this, refuse to answer

MODE="${1:-full}"

is_num() { case "$1" in ''|*[!0-9-]*) return 1 ;; *) return 0 ;; esac; }

# tenths -> "12.3", with an explicit sign when asked
fmt() {
    local v=$1 sign=''
    [ "$v" -lt 0 ] && { sign='-'; v=$(( -v )); }
    [ -n "$2" ] && [ "$sign" = '' ] && sign='+'
    printf '%s%d.%d' "$sign" $((v / 10)) $((v % 10))
}

emit() {  # tier pace_x10 used_x10 elapsed_x10 left_x10 age conf reason
    if [ "$MODE" = tier ]; then
        printf '%s\n' "$1"
    else
        printf 'tier=%s pace=%s used=%s elapsed=%s left=%s age=%s conf=%s reason=%s\n' \
            "$1" "$(fmt "$2" +)" "$(fmt "$3")" "$(fmt "$4")" "$(fmt "$5")" "$6" "$7" "$8"
    fi
    exit 0
}
unknown() { emit L0 0 0 0 0 "${2:--1}" none "$1"; }

[ -r "$CACHE" ] || unknown nocache

schema='' updated_at='' used_x10='' resets_at='' remaining='' max_rem='' anchor_at='' anchor_rem='' win_measured='' five_x10='' five_reset=''
read -r schema updated_at used_x10 resets_at remaining max_rem anchor_at anchor_rem win_measured five_x10 five_reset < "$CACHE" 2>/dev/null

[ "$schema" = 1 ] || unknown schema
for v in "$updated_at" "$used_x10" "$resets_at" "$remaining" "$max_rem" "$anchor_at" "$anchor_rem" "$win_measured"; do
    is_num "$v" || unknown malformed
done
[ "$resets_at" -gt 0 ] || unknown no_rate_limits

NOW=$(date +%s)
AGE=$((NOW - updated_at))
[ "$AGE" -lt 0 ] && AGE=0                      # clock skew between sessions
[ "$AGE" -gt "$STALE_HARD" ] && unknown stale "$AGE"

# --- Is the 7d limit really a fixed 7-day window? ---
# The pace maths only means anything if `remaining` tracks wall-clock 1:1 and
# the window resets whole. Three cheap checks fail closed if it doesn't.
[ "$max_rem" -gt $((WINDOW * 102 / 100)) ] && unknown window_longer "$AGE"
if [ "$win_measured" -gt 0 ]; then
    d=$((win_measured - WINDOW)); [ "$d" -lt 0 ] && d=$(( -d ))
    [ "$d" -gt $((WINDOW * 5 / 100)) ] && unknown window_mismatch "$AGE"
fi
if [ "$anchor_rem" -ge 0 ] && [ "$anchor_at" -gt 0 ]; then
    el=$((updated_at - anchor_at))
    if [ "$el" -ge 3600 ]; then
        drift=$((remaining - (anchor_rem - el)))
        [ "$drift" -lt 0 ] && drift=$(( -drift ))
        # A rolling window keeps `remaining` flat, so drift grows with el.
        [ "$drift" -gt $((el / 4)) ] && unknown window_rolling "$AGE"
    fi
fi
CONF=medium
[ "$max_rem" -ge $((WINDOW * 97 / 100)) ] && CONF=high

# --- Pace ---
rem_now=$((resets_at - NOW))
[ "$rem_now" -lt 0 ] && rem_now=0
elapsed_x10=$(( (WINDOW - rem_now) * 1000 / WINDOW ))
[ "$elapsed_x10" -lt 0 ] && elapsed_x10=0
[ "$elapsed_x10" -gt 1000 ] && elapsed_x10=1000
pace_x10=$((elapsed_x10 - used_x10))
left_x10=$((1000 - used_x10))
[ "$left_x10" -lt 0 ] && left_x10=0

# A stale sample always understates `used`, which always overstates the
# surplus. Upgrading on it is the one direction that can burn the week, so
# soft-stale samples are answered but never promoted.
[ "$AGE" -gt "$STALE_SOFT" ] && emit L0 "$pace_x10" "$used_x10" "$elapsed_x10" "$left_x10" "$AGE" "$CONF" soft_stale

if [ "$pace_x10" -ge "$L2_X10" ]; then
    emit L2 "$pace_x10" "$used_x10" "$elapsed_x10" "$left_x10" "$AGE" "$CONF" ok
elif [ "$pace_x10" -ge "$L1_X10" ]; then
    emit L1 "$pace_x10" "$used_x10" "$elapsed_x10" "$left_x10" "$AGE" "$CONF" ok
fi
emit L0 "$pace_x10" "$used_x10" "$elapsed_x10" "$left_x10" "$AGE" "$CONF" ok
