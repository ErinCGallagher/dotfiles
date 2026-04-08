#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name' | sed 's/ ([^)]*context)//g')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Context window info
used=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor')

# Rate limit info
five_h_pct=$(echo "$input" | jq -r 'if .rate_limits.five_hour.used_percentage != null then .rate_limits.five_hour.used_percentage | floor | tostring else "" end')
five_h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d_pct=$(echo "$input" | jq -r 'if .rate_limits.seven_day.used_percentage != null then .rate_limits.seven_day.used_percentage | floor | tostring else "" end')
seven_d_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Colour palette
ORANGE="\e[38;5;208m"
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Returns the escape code for a given usage percentage
usage_colour() {
  local pct=$1
  local int_pct
  int_pct=$(printf "%.0f" "$pct" 2>/dev/null || echo 0)
  if [ "$int_pct" -lt 50 ]; then
    printf "%s" "$GREEN"
  elif [ "$int_pct" -lt 75 ]; then
    printf "%s" "$YELLOW"
  elif [ "$int_pct" -lt 90 ]; then
    printf "%s" "$ORANGE"
  else
    printf "%s" "$RED"
  fi
}

# Renders a 7-cell bar for a given usage percentage.
# Uses ▊ for both filled and empty segments: filled portion uses usage_colour,
# empty portion uses 256-colour dark grey (238). Two contiguous runs, no borders.
make_bar() {
  local pct=$1
  local BAR_WIDTH=7
  local colour
  colour=$(usage_colour "$pct")
  local filled
  filled=$(printf "%.0f" "$(echo "scale=4; $pct / 100 * $BAR_WIDTH" | bc 2>/dev/null || echo 0)")
  [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
  local empty=$(( BAR_WIDTH - filled ))
  local bar=""
  local filled_chars=""
  local empty_chars=""
  local i
  for (( i=0; i<filled; i++ )); do filled_chars+="▊"; done
  for (( i=0; i<empty; i++ )); do empty_chars+="▊"; done
  bar="${colour}${filled_chars}\e[38;5;238m${empty_chars}${RESET}"
  printf "%s" "$bar"
}

# Formats a unix timestamp as @3pm or @3:45pm (12-hour, no leading zero, lowercase)
format_reset_time() {
  local ts=$1
  local hour min ampm
  hour=$(date -r "$ts" +%-I 2>/dev/null)
  min=$(date -r "$ts" +%M 2>/dev/null)
  ampm=$(date -r "$ts" +%p 2>/dev/null | tr '[:upper:]' '[:lower:]')
  if [ "$min" = "00" ]; then
    printf "@%s%s" "$hour" "$ampm"
  else
    printf "@%s:%s%s" "$hour" "$min" "$ampm"
  fi
}

# Start building the status line
output=""

# Directory
if [ -n "$current_dir" ]; then
  if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    dir_name=$(basename "$current_dir")
  else
    dir_name=$(echo "$current_dir" | awk -F'/' '{if (NF>2) print $(NF-1)"/"$NF; else print $0}')
  fi
  output+=$(printf "🏰 %s " "$dir_name")
fi

# Git branch
if [ -n "$current_dir" ] && git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || echo "detached")
  output+=$(printf " %s " "$branch")
fi

# Model name (always white)
output+=$(printf "\e[97m👸 %s | ${RESET}" "$model_name")
if [ -n "$used" ] && [ "$used" != "null" ]; then
  bar=$(make_bar "$used")
  int_used=$(printf "%.0f" "$used")
  output+=$(printf "\e[97mC:%s \e[97m%s%%${RESET}" "$bar" "$int_used")
fi

# 5-hour rate limit bar
if [ -n "$five_h_pct" ] && [ -n "$five_h_resets" ]; then
  five_h_int=$(printf "%.0f" "$five_h_pct")
  five_h_bar=$(make_bar "$five_h_pct")
  reset_label=$(format_reset_time "$five_h_resets")
  output+=$(printf " \e[97m| \e[97m5h:%s \e[97m%s%% \e[97m%s${RESET}" "$five_h_bar" "$five_h_int" "$reset_label")
fi

# 7-day rate limit bar
if [ -n "$seven_d_pct" ] && [ -n "$seven_d_resets" ]; then
  seven_d_int=$(printf "%.0f" "$seven_d_pct")
  seven_d_bar=$(make_bar "$seven_d_pct")
  now=$(date +%s)
  days_remaining=$(echo "scale=1; ($seven_d_resets - $now) / 86400" | bc 2>/dev/null || echo "?")
  output+=$(printf " \e[97m| \e[97m7d:%s \e[97m%s%% \e[97m%sd${RESET}" "$seven_d_bar" "$seven_d_int" "$days_remaining")
fi

# Vim mode indicator
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "INSERT" ]; then
    output+=$(printf " ${GREEN}[INSERT]${RESET}")
  else
    output+=$(printf " ${RED}[NORMAL]${RESET}")
  fi
fi

printf "%b\n" "$output"
