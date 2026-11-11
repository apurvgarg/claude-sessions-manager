#!/usr/bin/env bash
# Usage: ./uninstall.sh [--purge]   (--purge also deletes your projects list)
set -u
APP="${CSM_PREFIX:-$HOME/.local/share/claude-sessions-manager}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/claude-sessions-manager"
B="# >>> claude-sessions-manager >>>"
E="# <<< claude-sessions-manager <<<"

[ -x "$HOME/.local/bin/claude-sessions" ] && "$HOME/.local/bin/claude-sessions" stop
rm -rf "$APP"
rm -f "$HOME/.local/bin/claude-sessions"
rm -f "$HOME/.local/share/applications/claude-sessions.desktop" \
      "$HOME/.config/autostart/claude-sessions.desktop"
[ -f "$HOME/.tmux.conf" ] && sed -i "\|$B|,\|$E|d" "$HOME/.tmux.conf"
[ "${1:-}" = "--purge" ] && rm -rf "$CONF"
echo "Uninstalled. Running Claude tmux sessions were NOT touched."
[ "${1:-}" = "--purge" ] || echo "Your projects list is kept in $CONF (use --purge to delete)."
