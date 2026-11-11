#!/usr/bin/env python3
"""Claude Sessions Manager - local dashboard backend (stdlib only)."""
import json, os, re, socket, subprocess, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(DIR)
ENSURE = os.path.join(ROOT, "bin", "claude-sessions-ensure")
PORT = int(os.environ.get("CSM_PORT", "7700"))
CONF = os.environ.get("CSM_CONFIG_DIR") or os.path.join(
    os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"),
    "claude-sessions-manager")
PFILE = os.path.join(CONF, "projects.txt")
HOSTS = {f"127.0.0.1:{PORT}", f"localhost:{PORT}"}
LOCK = threading.Lock()
os.makedirs(CONF, exist_ok=True)


def projects():
    out = []
    if not os.path.exists(PFILE):
        return out
    for line in open(PFILE):
        line = line.strip()
        if not line or line.startswith("#") or line.count("|") != 2:
            continue
        n, p, port = line.split("|")
        try:
            out.append((n, p, int(port)))
        except ValueError:
            pass
    return out


def save(items):
    with open(PFILE, "w") as f:
        for n, p, port in items:
            f.write(f"{n}|{p}|{port}\n")


def tmux(*a):
    return subprocess.run(["tmux", *a], capture_output=True, text=True)


def alive(n):
    return tmux("has-session", "-t", "=" + n).returncode == 0


def port_free(port):
    s = socket.socket()
    try:
        s.bind(("127.0.0.1", port))
        return True
    except OSError:
        return False
    finally:
        s.close()


def next_port(used):
    p = 7681
    while p in used or p == PORT or not port_free(p):
        p += 1
    return p


def kill_ttyd(port):
    subprocess.run(["pkill", "-f", f"ttyd -p {port} "])


def js(o):
    return json.dumps(o)


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body, ctype="application/json"):
        b = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            return json.loads(self.rfile.read(n) or b"{}")
        except Exception:
            return {}

    def host_ok(self):
        return self.headers.get("Host") in HOSTS

    def do_GET(self):
        if not self.host_ok():
            return self.send(403, "{}")
        if self.path == "/api/status":
            return self.send(200, js(
                [{"name": n, "port": port, "alive": alive(n)} for n, _, port in projects()]))
        if self.path == "/api/projects":
            return self.send(200, js(
                [{"name": n, "path": p, "port": port} for n, p, port in projects()]))
        if self.path in ("/", "/dash.html"):
            return self.send(200, open(os.path.join(DIR, "dash.html"), "rb").read(), "text/html")
        self.send(404, "{}")

    def do_POST(self):
        origin = self.headers.get("Origin")
        if not self.host_ok() or (origin is not None and origin not in {"http://" + h for h in HOSTS}):
            return self.send(403, "{}")
        parts = self.path.strip("/").split("/")
        act = parts[1] if len(parts) > 1 else ""
        name = parts[2] if len(parts) > 2 else None

        if act == "project-add":
            d = self.body()
            n = re.sub(r"\s+", "-", str(d.get("name", "")).strip().lower())
            if n and not n.startswith("proj-"):
                n = "proj-" + n
            path = os.path.expanduser(str(d.get("path", "")).strip())
            if not re.fullmatch(r"proj-[a-z0-9][a-z0-9-]{0,40}", n):
                return self.send(400, js({"error": "Name may only contain a-z, 0-9 and -"}))
            if not os.path.isdir(path) or "|" in path or "\n" in path:
                return self.send(400, js({"error": "Folder not found: " + path}))
            with LOCK:
                items = projects()
                if any(x[0] == n for x in items):
                    return self.send(400, js({"error": "That name already exists"}))
                port = next_port({x[2] for x in items})
                items.append((n, path, port))
                save(items)
            subprocess.run([ENSURE, n])
            return self.send(200, js({"ok": True, "name": n, "port": port}))

        if act == "project-remove" and name:
            with LOCK:
                items = projects()
                hit = [x for x in items if x[0] == name]
                if not hit:
                    return self.send(404, js({"error": "Not found"}))
                save([x for x in items if x[0] != name])
            tmux("kill-session", "-t", "=" + name)
            kill_ttyd(hit[0][2])
            return self.send(200, js({"ok": True}))

        names = [n for n, _, _ in projects()]
        if act == "start":
            subprocess.run([ENSURE] + ([name] if name in names else []))
        elif act == "stop":
            for n in ([name] if name in names else names):
                tmux("kill-session", "-t", "=" + n)
        elif act == "quit":
            for _, _, port in projects():
                kill_ttyd(port)
            threading.Thread(target=lambda: (time.sleep(0.3), os._exit(0))).start()
        else:
            return self.send(404, "{}")
        self.send(200, js({"ok": True}))


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
