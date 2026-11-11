.RECIPEPREFIX = >
.PHONY: help check install install-autostart uninstall start stop status

help:
> @echo "make check              check dependencies"
> @echo "make install            install"
> @echo "make install-autostart  install + start at login"
> @echo "make uninstall          remove (keeps your projects list)"
> @echo "make start|stop|status  run the installed command"

check:
> ./install.sh --check

install:
> ./install.sh

install-autostart:
> ./install.sh --autostart

uninstall:
> ./uninstall.sh

start:
> $(HOME)/.local/bin/claude-sessions

stop:
> $(HOME)/.local/bin/claude-sessions stop

status:
> $(HOME)/.local/bin/claude-sessions status
