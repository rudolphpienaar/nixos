if [[ ! -o interactive ]]; then
  return
fi

if [[ -n "$TMUX" || "$TERM" == "dumb" ]]; then
  return
fi

if [[ "$LANG$LC_ALL$LC_CTYPE" == *UTF-8* ]]; then
  box_h="─"
  box_v="│"
  box_tl="┌"
  box_tr="┐"
  box_bl="└"
  box_br="┘"
  bullet="◆"
else
  box_h="-"
  box_v="|"
  box_tl="+"
  box_tr="+"
  box_bl="+"
  box_br="+"
  bullet="*"
fi

content_width=75

rule() {
  local color="$1"
  local title="$2"
  local bar
  local border_width=$((content_width + 2))

  if [[ -n "$title" ]]; then
    local label=" $title "
    local remaining=$((border_width - ${#label}))
    if (( remaining < 0 )); then
      label=" ${title[1,border_width-2]} "
      remaining=0
    fi
    printf -v bar "%${remaining}s" ""
    bar="${bar// /$box_h}"
    print -P "%F{$color}$box_tl$label$bar$box_tr%f"
  else
    printf -v bar "%${border_width}s" ""
    bar="${bar// /$box_h}"
    print -P "%F{$color}$box_tl$bar$box_tr%f"
  fi
}

footer() {
  local color="$1"
  local bar
  printf -v bar "%77s" ""
  bar="${bar// /$box_h}"
  print -P "%F{$color}$box_bl$bar$box_br%f"
}

box_line() {
  local color="$1"
  shift
  local text="$*"
  local padded
  text="${text//$'\t'/    }"
  text="${text//$'\r'/}"
  if (( ${#text} > content_width )); then
    text="${text[1,content_width]}"
  fi
  printf -v padded "%-${content_width}s" "$text"
  print -P "%F{$color}$box_v%f $padded %F{$color}$box_v%f"
}

box_stream() {
  local color="$1"
  while IFS= read -r line || [[ -n "$line" ]]; do
    box_line "$color" "$line"
  done
}

host_name="$(hostname)"
arch="$(uname)"
kernel_line="$(uname -r)"
uptime_line="$(uptime 2>/dev/null)"

rule 33 "console matrix"
box_line 33 "$bullet host: $host_name   $bullet user: $USER"
box_line 33 "$bullet term: $TERM   $bullet kernel: $kernel_line   $bullet arch: $arch"
box_line 33 "$uptime_line"
footer 33

print ""
rule 81 "process board"
box_line 81 "PID    USER       COMMAND                    CPU    MEM"
while IFS='|' read -r pid user comm cpu mem; do
  box_line 81 "$(printf '%-6s %-10s %-24s %6s  %6s' "$pid" "$user" "$comm" "$cpu" "$mem")"
done < <(
  ps -eo pid=,user=,comm=,%cpu=,%mem= --sort=-%cpu | \
  awk '{
    pid=$1
    user=$2
    cpu=$(NF-1)
    mem=$NF
    $1=""; $2=""; $(NF-1)=""; $NF=""
    sub(/^[[:space:]]+/, "", $0)
    sub(/[[:space:]]+$/, "", $0)
    printf "%s|%s|%s|%s|%s\n", pid, user, $0, cpu, mem
  }' | head -n 10
)
footer 81

print ""
rule 39 "session index"
{
  mesg y 2>/dev/null || true
  finger -s 2>/dev/null || true
} | box_stream 39
footer 39

print ""
rule 214 "temperature cities"
if command -v curl >/dev/null 2>&1; then
  while IFS='|' read -r label query; do
    weather_blob="$(
      curl -fsS \
        --connect-timeout 1 \
        --max-time 2 \
        "https://wttr.in/$query?m&0&T" \
        2>/dev/null || true
    )"
    condition="unknown"
    forecast="feed unavailable"
    if [[ -n "$weather_blob" ]]; then
      condition="$(
        printf '%s\n' "$weather_blob" |
          sed -n '3p' |
          sed -E 's/^.*[[:space:]]{2,}([[:alpha:]].*)$/\1/; s/^[[:space:]]*//; s/[[:space:]]*$//'
      )"
      temp="$(
        printf '%s\n' "$weather_blob" |
          sed -n '4p' |
          grep -oE '[+-]?[0-9]+(\([+-]?[0-9]+\))? ?°C' |
          head -n 1
      )"
      wind="$(
        printf '%s\n' "$weather_blob" |
          sed -n '5p' |
          grep -oE '([←→↑↓↖↗↘↙][[:space:]]*)?[0-9]+ km/h' |
          head -n 1
      )"
      temp="$(
        printf '%s\n' "$temp" |
          sed -E \
            -e 's/^\+?([0-9]+)\(\+?([0-9]+)\)[[:space:]]*°C$/\1°C (feels like \2°C)/' \
            -e 's/^\+?([0-9]+)[[:space:]]*°C$/\1°C/'
      )"
      forecast="$(printf '%s %s' "$temp" "$wind" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]][[:space:]]*/ /g')"
    fi
    condition="${condition#"${condition%%[![:space:]]*}"}"
    condition="${condition%"${condition##*[![:space:]]}"}"
    forecast="${forecast#"${forecast%%[![:space:]]*}"}"
    forecast="${forecast%"${forecast##*[![:space:]]}"}"
    box_line 214 "$(printf '%-16s  %-18s  %s' "$label" "$condition" "$forecast")"
  done <<'EOF'
Boston|Boston
New York City|New%20York%20City
Troy, NY|Troy%20NY
Cape Town|Cape%20Town
EOF
else
  box_line 214 "weather feed unavailable"
fi
footer 214

cal_file="$(mktemp)"
clock_file="$(mktemp)"

cal >"$cal_file" 2>/dev/null || : >"$cal_file"

if command -v toilet >/dev/null 2>&1; then
  date '+%H:%M' | toilet -f future -F border >"$clock_file" 2>/dev/null || : >"$clock_file"
elif command -v figlet >/dev/null 2>&1; then
  date '+%H:%M' | figlet >"$clock_file" 2>/dev/null || : >"$clock_file"
else
  date '+%H:%M' >"$clock_file"
fi

print ""
rule 178 "calendar and time"
paste "$cal_file" "$clock_file" | box_stream 178
footer 178
rm -f "$cal_file" "$clock_file"

if command -v cpufetch >/dev/null 2>&1; then
  cpufetch
fi

if command -v neofetch >/dev/null 2>&1; then
  print ""
  neofetch --disable WM --disable Resolution 2>/dev/null
  print ""
elif command -v screenfetch >/dev/null 2>&1; then
  print ""
  screenfetch 2>/dev/null
  print ""
fi

print ""
rule 135 "signal"
fortune 2>/dev/null | box_stream 135
footer 135
print ""
