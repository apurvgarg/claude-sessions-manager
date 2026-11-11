# Troubleshooting

## A panel is blank (only a cursor)

Port 7681 is often taken by the system `ttyd` service installed by apt.

```bash
ss -ltnp | grep 7681
sudo systemctl disable --now ttyd
claude-sessions
```

Then click the panel's reload button.

## `node: not found`, or an MCP server (e.g. Playwright) can't find `npx`

tmux started without your Node (nvm) on its PATH.

```bash
tmux set-environment -g PATH "$HOME/.nvm/versions/node/<version>/bin:$(tmux show-environment -g PATH | cut -d= -f2-)"
```

Then stop and start the session from the dashboard. For MCP servers, use the
full path to `npx` in the server config.

## The wrong conversation was resumed

`claude --continue` resumes the most recent conversation in that folder.
For a specific one, run `claude --resume` in the folder and pick it.

## A session is gone after a reboot

Click **Start all**, or run `claude-sessions`. Conversations are stored in
`~/.claude/projects/` and are resumed. Work that was running is not.

## Port already in use

Ports must be unique per project. Remove and re-add the project from the
dashboard (it picks a free port), or edit
`~/.config/claude-sessions-manager/projects.txt`.

## Dashboard won't open

```bash
claude-sessions status
cat /tmp/claude-sessions.log
```

## Ctrl+Down does nothing

The binding is in your `~/.tmux.conf` (added by the installer). Reload it:

```bash
tmux source-file ~/.tmux.conf
```

Click inside the terminal panel first so it has keyboard focus.
