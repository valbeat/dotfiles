#!/bin/bash
input=$(cat)

# Guards
[ -z "$input" ] && echo "" && exit 0
command -v jq >/dev/null 2>&1 || { echo "[no jq]"; exit 0; }

# Single jq call to extract all values
IFS=$'\t' read -r MODEL CONTEXT_SIZE CURRENT_TOKENS FIVE_HOUR FIVE_RESET SEVEN_DAY SEVEN_RESET <<< "$(
  echo "$input" | jq -r '[
    .model.display_name,
    (.context_window.context_window_size // 0),
    ((.context_window.current_usage // {}) | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // "")
  ] | @tsv'
)"

RESET='\033[0m'
DIM='\033[2m'

# ANSI color by percentage: green(0%) -> yellow(50%) -> red(100%)
color_by_pct() {
    local pct=$1
    local r g
    if [ "$pct" -le 50 ]; then
        r=$((pct * 255 / 50))
        g=255
    else
        r=255
        g=$(((100 - pct) * 255 / 50))
    fi
    printf '\033[38;2;%d;%d;0m' "$r" "$g"
}

# Bar gauge using block characters (8 steps per char, 5 chars = 40 steps)
bar_gauge() {
    local pct=$1
    local width=5
    local blocks=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉" "█")
    local total_steps=$((width * 8))
    local filled=$((pct * total_steps / 100))
    local full=$((filled / 8))
    local partial=$((filled % 8))
    local bar=""
    for ((i = 0; i < full; i++)); do bar+="█"; done
    if [ "$full" -lt "$width" ] && [ "$partial" -gt 0 ]; then
        bar+="${blocks[$partial]}"
        full=$((full + 1))
    fi
    local empty=$((width - full))
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    echo -n "$bar"
}

# Format token count as human-readable (e.g., 450k, 1.2M)
format_tokens() {
    local t=$1
    if [ "$t" -ge 1000000 ]; then
        local major=$((t / 1000000))
        local minor=$(((t % 1000000) / 100000))
        if [ "$minor" -gt 0 ]; then
            printf '%d.%dM' "$major" "$minor"
        else
            printf '%dM' "$major"
        fi
    elif [ "$t" -ge 1000 ]; then
        printf '%dk' $((t / 1000))
    else
        printf '%d' "$t"
    fi
}

# Format remaining time until reset (e.g., "2h13m", "3d5h")
format_remaining() {
    local resets_at=$1
    [ -z "$resets_at" ] && return
    local now remaining
    now=$(date +%s)
    remaining=$((resets_at - now))
    [ "$remaining" -le 0 ] && return
    local days=$((remaining / 86400))
    local hours=$(((remaining % 86400) / 3600))
    local mins=$(((remaining % 3600) / 60))
    if [ "$days" -gt 0 ]; then
        printf '%dd%dh' "$days" "$hours"
    elif [ "$hours" -gt 0 ]; then
        printf '%dh%02dm' "$hours" "$mins"
    else
        printf '%dm' "$mins"
    fi
}

# Format rate limit metric with color, bar, and reset countdown
fmt_rate() {
    local label=$1 pct=$2 resets_at=$3
    local c
    c=$(color_by_pct "$pct")
    local reset_str
    reset_str=$(format_remaining "$resets_at")
    if [ -n "$reset_str" ]; then
        printf '%b%s%b %b%s%b %b%3d%%%b %b⟳%s%b' "$DIM" "$label" "$RESET" "$c" "$(bar_gauge "$pct")" "$RESET" "$c" "$pct" "$RESET" "$DIM" "$reset_str" "$RESET"
    else
        printf '%b%s%b %b%s%b %b%3d%%%b' "$DIM" "$label" "$RESET" "$c" "$(bar_gauge "$pct")" "$RESET" "$c" "$pct" "$RESET"
    fi
}

# Strip ANSI escape sequences to measure visible width
visible_len() {
    local esc=$(printf '\033')
    printf '%s' "$1" | sed "s/${esc}\[[0-9;]*m//g" | wc -m | tr -d ' '
}

# Terminal width
COLS=$(tput cols 2>/dev/null || echo 120)

# Context window usage
CTX_PCT=0
if [ "$CURRENT_TOKENS" != "null" ] && [ "$CONTEXT_SIZE" != "null" ] && [ "$CONTEXT_SIZE" != "0" ]; then
    CTX_PCT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
fi
# Clamp to 0-100
[ "$CTX_PCT" -gt 100 ] && CTX_PCT=100
[ "$CTX_PCT" -lt 0 ] && CTX_PCT=0

# Build parts array: each element is an ANSI-formatted string
# Priority order (rightmost gets dropped first):
#   1. [Model] ctx bar tokens  (always shown)
#   2. 5h rate limit
#   3. 7d rate limit
#   4. git branch
PARTS=()

# Part 0: model + context (always shown)
CTX_COLOR=$(color_by_pct "$CTX_PCT")
PARTS+=("$(printf '[%s] %bctx%b %b%s%b %b%s/%s%b' \
    "$MODEL" \
    "$DIM" "$RESET" \
    "$CTX_COLOR" "$(bar_gauge "$CTX_PCT")" "$RESET" \
    "$CTX_COLOR" "$(format_tokens "$CURRENT_TOKENS")" "$(format_tokens "$CONTEXT_SIZE")" "$RESET")")

# Part 1: 5h rate limit (only when >= 20%)
if [ -n "$FIVE_HOUR" ]; then
    FIVE_INT=${FIVE_HOUR%.*}
    [ "$FIVE_INT" -gt 100 ] 2>/dev/null && FIVE_INT=100
    [ "${FIVE_INT:-0}" -ge 20 ] && PARTS+=("$(fmt_rate "5h" "$FIVE_INT" "$FIVE_RESET")")
fi

# Part 2: 7d rate limit (only when >= 20%)
if [ -n "$SEVEN_DAY" ]; then
    SEVEN_INT=${SEVEN_DAY%.*}
    [ "$SEVEN_INT" -gt 100 ] 2>/dev/null && SEVEN_INT=100
    [ "${SEVEN_INT:-0}" -ge 20 ] && PARTS+=("$(fmt_rate "7d" "$SEVEN_INT" "$SEVEN_RESET")")
fi

# Part 3: git branch
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        DIRTY=""
        git diff --quiet 2>/dev/null || DIRTY="*"
        git diff --cached --quiet HEAD 2>/dev/null || DIRTY+="+"
        PARTS+=("$(printf '%b%s%b' "$DIM" "${BRANCH}${DIRTY}" "$RESET")")
    fi
fi

# Assemble: join with "  ", drop rightmost parts until it fits
OUTPUT="${PARTS[0]}"
for ((i = 1; i < ${#PARTS[@]}; i++)); do
    OUTPUT+="  ${PARTS[$i]}"
done

while [ "$(visible_len "$OUTPUT")" -gt "$COLS" ] && [ "${#PARTS[@]}" -gt 1 ]; do
    unset 'PARTS[${#PARTS[@]}-1]'
    OUTPUT="${PARTS[0]}"
    for ((i = 1; i < ${#PARTS[@]}; i++)); do
        OUTPUT+="  ${PARTS[$i]}"
    done
done

printf '%s\n' "$OUTPUT"
