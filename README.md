# Claude Sessions Manager

One browser dashboard for all your [Claude Code](https://claude.com/claude-code) sessions.

Run Claude Code on several projects at once, see them side by side as real
terminals, and bring everything back with one click after a laptop restart.

## Features

- Every project's Claude session in one page, as a real terminal (colors, `/` and `@` popups, scrollback)
- One click after a restart resumes every session with its conversation (`claude --continue`)
- Collapse, maximize, reload, stop or start any session from the UI
- Add or remove projects from the UI, no config editing
- Ctrl+Down jumps to the bottom of Claude's chat in any session
- Localhost only, Python stdlib only (no Node, no database, no Docker)

## How it works

- **tmux** keeps each Claude session alive in the background
- **ttyd** streams each tmux session to the browser
- A small Python server serves the dashboard and handles start/stop/add/remove

## Requirements

Linux with a desktop browser, plus:

| Tool | Install |
|---|---|
| tmux | `sudo apt install tmux` |
| ttyd | `sudo apt install ttyd` or [releases](https://github.com/tsl0922/ttyd/releases) |
| python3 | `sudo apt install python3` |
| curl, ss | `sudo apt install curl iproute2` |
| Claude Code | https://claude.com/claude-code |

> If you installed ttyd with apt, it may run a system service on port 7681
> with a login terminal. Disable it: `sudo systemctl disable --now ttyd`

## Install

```bash
git clone https://github.com/apurvgarg/claude-sessions-manager.git
cd claude-sessions-manager
make check              # verify dependencies
make install            # or: ./install.sh
make install-autostart  # optional: also start at login
```

Make sure `~/.local/bin` is in your `PATH`.

## Usage

```bash
claude-sessions            # start sessions + dashboard, open the browser
claude-sessions status     # show dashboard and session status
claude-sessions stop       # stop dashboard and web terminals (Claude sessions keep running)
claude-sessions stop-all   # also stop the Claude tmux sessions
```

You can also search **Claude Sessions** in your app menu.

In the dashboard, click **Projects** to add a project (name and folder).
It starts a Claude session there right away.

## Configuration

Your project list lives outside the repo:

```
~/.config/claude-sessions-manager/projects.txt
```

One project per line: `name|folder|port`. Names start with `proj-`, ports are unique.

| Variable | Default | Purpose |
|---|---|---|
| `CSM_PORT` | `7700` | Dashboard port |
| `CSM_CONFIG_DIR` | `~/.config/claude-sessions-manager` | Config folder |

## Security

The dashboard sends keystrokes to terminals that may run in auto-accept mode.
It listens on `127.0.0.1` only and rejects requests from other origins.
Do not expose it to a network.

## Uninstall

```bash
make uninstall          # keeps your projects list
./uninstall.sh --purge  # also deletes it
```

Running Claude tmux sessions are never touched by uninstall.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## License

MIT
