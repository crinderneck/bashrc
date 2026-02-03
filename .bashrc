#
# ~/.bashrc
#

cal
date
[[ $- != *i* ]] && return
alias ma='minall'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias ipconfig='ip -4 addr show'
if command -v pacman >/dev/null 2>&1; then
    alias install='sudo pacman -S'
    alias uninstall='sudo pacman -Rsc'
    alias update='sudo pacman -Syu'
    alias search='pacman -Ss'
elif command -v apt >/dev/null 2>&1; then
    alias install='sudo apt install'
    alias uninstall='sudo apt remove'
    alias update='sudo apt update'
    alias search='apt search'
fi
alias yayinstall='sudo pacman -S'
alias yayuninstall='sudo pacman -Rsc'
alias yayupdate='sudo pacman -Syu'
alias yaysearch='pacman -Ss'
alias rerc='. ~/.bashrc'
alias editrc='nano ~/.bashrc'
alias erc='nano ~/.bashrc'
alias la='ls -A'
alias weather='python /home/blithen/git/scripts/nws-weather-tui.py'


glg() {
  local query="$*"
  if [[ -z "$query" ]]; then
    echo "Usage: glg <search terms>"
    return 1
  fi

  local encoded
  encoded=$(printf '%s' "$query" | sed 's/ /+/g')

  xdg-open "https://www.google.com/search?q=$encoded" >/dev/null 2>&1
}

# KDE Plasma Wayland: minimize all windows (true minimize, not Show Desktop toggle)
minall() {
  local qdbus_bin
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus_bin=qdbus6
  elif command -v qdbus >/dev/null 2>&1; then
    qdbus_bin=qdbus
  else
    echo "minall: need qdbus6 (or qdbus). Install Qt DBus tools." >&2
    return 1
  fi

  # Invoke the KWin script action "MinimizeAll" via global shortcuts
  if ! "$qdbus_bin" org.kde.kglobalaccel /component/kwin \
      org.kde.kglobalaccel.Component.invokeShortcut "MinimizeAll" >/dev/null 2>&1; then
    echo "minall: couldn't invoke 'MinimizeAll'." >&2
    echo "Make sure KWin Script 'Minimize All' is enabled:" >&2
    echo "  System Settings → Window Management → KWin Scripts → Minimize All" >&2
    echo "Debug: available KWin shortcuts:" >&2
    "$qdbus_bin" org.kde.kglobalaccel /component/kwin \
      org.kde.kglobalaccel.Component.shortcutNames 2>/dev/null | sed 's/^/  /'
    return 2
  fi
}

clip () {
while IFS= read -r line; do
	wl-copy $line
done
}

dicepass() {
    local words=${1:-6}
    curl -s https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt \
      | shuf -n "$words" \
      | awk '{print $2}' \
      | paste -sd '-'
}

audio() {
  # Fuzzy-set default audio output sink (PipeWire/PulseAudio)
  # Usage:
  #   audio            # interactive pick (fzf if available)
  #   audio <pattern>  # non-interactive: first sink matching pattern
  #
  # Requires: pactl
  # Optional: fzf

  command -v pactl >/dev/null 2>&1 || { echo "audio: pactl not found (install: pacman -S pulseaudio-utils)"; return 1; }

  # Build sink list: "NAME<TAB>DESCRIPTION"
  local sinks
  sinks="$(pactl -f json list sinks 2>/dev/null | \
    python - <<'PY' 2>/dev/null
import json, sys
data=json.load(sys.stdin)
for s in data:
    name=s.get("name","")
    desc=s.get("description","")
    if name:
        print(f"{name}\t{desc}")
PY
  )"

  if [[ -z "$sinks" ]]; then
    # Fallback if json output isn't available (older pactl)
    sinks="$(pactl list short sinks | awk '{print $2 "\t" $2}')"
  fi

  local choice sink_name
  if [[ -n "${1-}" ]]; then
    # Non-interactive: pick first match from pattern (case-insensitive)
    choice="$(printf '%s\n' "$sinks" | grep -i -m1 -- "$1")"
    [[ -z "$choice" ]] && { echo "audio: no sink matched: $1"; return 1; }
  else
    if command -v fzf >/dev/null 2>&1; then
      choice="$(printf '%s\n' "$sinks" | fzf --prompt="Output sink > " --with-nth=2.. --delimiter=$'\t' --preview 'echo "NAME: {1}"; echo "DESC: {2..}"')"
    else
      echo "audio: fzf not found; install it for fuzzy picker: pacman -S fzf"
      echo "Available sinks:"
      printf '%s\n' "$sinks" | nl -w2 -s'. '
      read -r -p "Type a substring to match: " _q
      choice="$(printf '%s\n' "$sinks" | grep -i -m1 -- "${_q}")"
    fi
  fi

  [[ -z "$choice" ]] && return 130

  sink_name="${choice%%$'\t'*}"

  # Set default sink
  if ! pactl set-default-sink "$sink_name"; then
    echo "audio: failed to set default sink: $sink_name"
    return 1
  fi

  # Move current sink inputs (playing audio) to new sink
  local input_id
  while read -r input_id _; do
    [[ -n "$input_id" ]] && pactl move-sink-input "$input_id" "$sink_name" >/dev/null 2>&1
  done < <(pactl list short sink-inputs 2>/dev/null)

  # Confirmation
  local pretty
  pretty="$(printf '%s\n' "$sinks" | awk -F'\t' -v n="$sink_name" '$1==n{print $2; found=1} END{if(!found) print ""}')"
  if [[ -n "$pretty" ]]; then
    echo "Default output set to: $pretty ($sink_name)"
  else
    echo "Default output set to: $sink_name"
  fi
}

math() {
    if [ $# -eq 0 ]; then
        echo "Usage: math2 \"expression\""
        echo "Example: math2 \"2 + 3 * 4\""
        return 1
    fi
    
    # Use Python to evaluate the expression safely
    python3 -c "
import math
import sys
try:
    result = eval(' '.join(sys.argv[1:]), {'__builtins__': {}}, {'math': math})
    print(result)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" "$@" 2>/dev/null || {
        echo "Error: Failed to evaluate expression"
        return 1
    }
}