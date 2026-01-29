#
# ~/.bashrc
#

cal
date
[[ $- != *i* ]] && return
alias ma='minall'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ipconfig='ip -4 addr show'
alias rerc='. ~/.bashrc'
alias editrc='nano ~/.bashrc'
alias la='ls -A'

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