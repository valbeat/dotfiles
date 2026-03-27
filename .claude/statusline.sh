#!/bin/bash
input=$(cat)

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

RESET='\033[0m'
DIM='\033[2m'

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

# Format a metric with color and bar
fmt_metric() {
    local label=$1 pct=$2
    local c
    c=$(color_by_pct "$pct")
    printf '%b%s%b %b%s%b %b%3d%%%b' "$DIM" "$label" "$RESET" "$c" "$(bar_gauge "$pct")" "$RESET" "$c" "$pct" "$RESET"
}

# Model name
MODEL=$(echo "$input" | jq -r '.model.display_name')

# Context window usage
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size')
USAGE=$(echo "$input" | jq '.context_window.current_usage')
CTX_PCT=0
if [ "$USAGE" != "null" ] && [ "$CONTEXT_SIZE" != "null" ] && [ "$CONTEXT_SIZE" != "0" ]; then
    CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    CTX_PCT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
fi

# Rate limits
FIVE_HOUR=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
SEVEN_DAY=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Build output
OUTPUT="$(fmt_metric "ctx" "$CTX_PCT")"
[ -n "$FIVE_HOUR" ] && OUTPUT+="  $(fmt_metric "5h" "${FIVE_HOUR%.*}")"
[ -n "$SEVEN_DAY" ] && OUTPUT+="  $(fmt_metric "7d" "${SEVEN_DAY%.*}")"

# Git branch
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    [ -n "$BRANCH" ] && OUTPUT+="  ${DIM}${BRANCH}${RESET}"
fi

echo -e "[$MODEL] $OUTPUT"
