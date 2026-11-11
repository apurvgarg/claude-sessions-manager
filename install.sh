#!/usr/bin/env bash
# Claude Sessions Manager installer
# Usage: ./install.sh [--autostart] [--check]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${CSM_PREFIX:-$HOME/.local/share/claude-sessions-manager}"
BINDIR="$HOME/.local/bin"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/claude-sessions-manager"
B="# >>> claude-sessions-manager >>>"
E="# <<< claude-sessions-manager <<<"
AUTOSTART=0; CHECK=0
for a in "$@"; do
  case "$a" in
    --autostart) AUTOSTART=1 ;;
    --check) CHECK=1 ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) echo "unknown option: $a"; exit 1 ;;
  esac
done

missing=0
need() {
  if command -v "$1" >/dev/null 2>&1; then printf '  ok       %s\n' "$1"
  else printf '  MISSING  %-8s -> %s\n' "$1" "$2"; missing=1; fi
}
echo "Checking dependencies:"
need tmux    "sudo apt install tmux"
need ttyd    "sudo apt install ttyd  (or https://github.com/tsl0922/ttyd/releases)"
need python3 "sudo apt install python3"
need curl    "sudo apt install curl"
need ss      "sudo apt install iproute2"
if bash -lc 'command -v claude' >/dev/null 2>&1; then echo "  ok       claude"
else echo "  WARNING  claude not found in a login shell (install Claude Code first)"; fi

if systemctl is-active --quiet ttyd 2>/dev/null; then
  echo
  echo "WARNING: the system 'ttyd' service is running (installed by apt). It takes port 7681"
  echo "and exposes a login terminal. Disable it:  sudo systemctl disable --now ttyd"
fi

if [ "$missing" = 1 ]; then echo; echo "Install the missing tools and run again."; exit 1; fi
[ "$CHECK" = 1 ] && { echo; echo "All required dependencies found."; exit 0; }

mkdir -p "$APP" "$BINDIR" "$CONF"
rm -rf "$APP/bin" "$APP/src"
cp -r "$ROOT/bin" "$ROOT/src" "$APP/"
chmod +x "$APP"/bin/* "$APP/src/server.py"
ln -sf "$APP/bin/claude-sessions" "$BINDIR/claude-sessions"
[ -f "$CONF/projects.txt" ] || cp "$ROOT/config/projects.example.txt" "$CONF/projects.txt"

touch "$HOME/.tmux.conf"
if ! grep -qF "$B" "$HOME/.tmux.conf"; then
  { echo; echo "$B"; cat "$ROOT/config/tmux.conf.snippet"; echo "$E"; } >> "$HOME/.tmux.conf"
fi
tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true

mkdir -p "$HOME/.local/share/applications"
DESK="$HOME/.local/share/applications/claude-sessions.desktop"
sed "s|@BIN@|$BINDIR|g" "$ROOT/desktop/claude-sessions.desktop.in" > "$DESK"
chmod +x "$DESK"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

if [ "$AUTOSTART" = 1 ]; then
  mkdir -p "$HOME/.config/autostart"
  cp "$DESK" "$HOME/.config/autostart/claude-sessions.desktop"
  echo "X-GNOME-Autostart-Delay=5" >> "$HOME/.config/autostart/claude-sessions.desktop"
fi

echo
echo "Installed."
echo "  command : $BINDIR/claude-sessions"
echo "  projects: $CONF/projects.txt"
case ":$PATH:" in *":$BINDIR:"*) ;; *) echo "  NOTE: add $BINDIR to your PATH" ;; esac
echo "Run: claude-sessions   (or search 'Claude Sessions' in your app menu)"
echo "Note: tmux history-limit applies to NEW sessions only."
