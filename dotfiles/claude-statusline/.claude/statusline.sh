#!/usr/bin/env bash
#
# Claude Code status line: model and effort, context use, and the claude.ai
# usage limits, in the Warm Burnout palette (ADR-0045).
#
#   Opus 5.5 · high │ ctx 42% 84k/200k │ 5h 23% ↻3:10pm · 7d 61% ↻Tue
#
# Claude Code pipes the session state to stdin as JSON after each turn. Every
# field is optional here: context use is null until the first reply, and
# rate_limits only appears for subscription logins once the API reports a
# window, so a missing value drops its segment instead of printing a blank.

input=$(cat)

# Fields are split on the ASCII unit separator, not a tab: read collapses runs
# of whitespace IFS characters, so an empty field between tabs would shift every
# later one left.
IFS=$'\x1f' read -r model effort ctx_pct ctx_used ctx_size five_pct five_reset week_pct week_reset < <(
  jq -r '[
      .model.display_name // .model.id // "",
      .effort.level // "",
      .context_window.used_percentage // "",
      .context_window.total_input_tokens // "",
      .context_window.context_window_size // "",
      .rate_limits.five_hour.used_percentage // "",
      .rate_limits.five_hour.resets_at // "",
      .rate_limits.seven_day.used_percentage // "",
      .rate_limits.seven_day.resets_at // ""
    ] | map(tostring) | join("\u001f")' <<<"$input"
)

# Truecolor escapes from the Warm Burnout Dark theme
# (dotfiles/claude/.claude/themes/warm-burnout-dark.json).
rgb() { printf '\033[38;2;%d;%d;%dm' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
reset=$'\033[0m'
c_model=$(rgb '#ff8f40')
c_text=$(rgb '#bfbdb6')
c_dim=$(rgb '#8a8070')
c_sep=$(rgb '#6a6258')
c_ok=$(rgb '#b4bc78')
c_warn=$(rgb '#e6c08a')
c_bad=$(rgb '#f49090')

# Green under half, amber under 80%, rose from there: the same bands claude.ai
# uses to shade its usage bars.
level() {
  local p=${1%.*}
  if ((p >= 80)); then printf '%s' "$c_bad"
  elif ((p >= 50)); then printf '%s' "$c_warn"
  else printf '%s' "$c_ok"
  fi
}

# 84123 -> 84k, 1000000 -> 1M.
human() {
  local n=${1%.*}
  if ((n >= 1000000)); then
    awk -v n="$n" 'BEGIN { printf (n % 1000000 ? "%.1fM" : "%dM"), n / 1000000 }'
  elif ((n >= 1000)); then printf '%dk' $((n / 1000))
  else printf '%d' "$n"
  fi
}

# Epoch seconds to a local time; BSD date (macOS) takes -r, GNU date takes -d @.
when() {
  local fmt=$2
  date -r "$1" "+$fmt" 2>/dev/null || date -d "@$1" "+$fmt" 2>/dev/null
}

segments=()

if [ -n "$model" ]; then
  seg="${c_model}${model}${reset}"
  [ -n "$effort" ] && seg+="${c_dim} · ${effort}${reset}"
  segments+=("$seg")
fi

if [ -n "$ctx_pct" ]; then
  seg="${c_dim}ctx ${reset}$(level "$ctx_pct")$(printf '%.0f' "$ctx_pct")%${reset}"
  if [ -n "$ctx_used" ] && [ -n "$ctx_size" ]; then
    seg+=" ${c_text}$(human "$ctx_used")${c_dim}/$(human "$ctx_size")${reset}"
  fi
  segments+=("$seg")
fi

limits=()
if [ -n "$five_pct" ]; then
  seg="${c_dim}5h ${reset}$(level "$five_pct")$(printf '%.0f' "$five_pct")%${reset}"
  [ -n "$five_reset" ] && seg+=" ${c_dim}↻$(when "$five_reset" '%-I:%M%p' | tr '[:upper:]' '[:lower:]')${reset}"
  limits+=("$seg")
fi
if [ -n "$week_pct" ]; then
  seg="${c_dim}7d ${reset}$(level "$week_pct")$(printf '%.0f' "$week_pct")%${reset}"
  [ -n "$week_reset" ] && seg+=" ${c_dim}↻$(when "$week_reset" '%a')${reset}"
  limits+=("$seg")
fi
if ((${#limits[@]})); then
  seg="${limits[0]}"
  ((${#limits[@]} > 1)) && seg+="${c_sep} · ${reset}${limits[1]}"
  segments+=("$seg")
fi

out=""
for seg in "${segments[@]}"; do
  [ -n "$out" ] && out+="${c_sep} │ ${reset}"
  out+="$seg"
done
printf '%s\n' "$out"
