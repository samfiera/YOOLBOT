#!/usr/bin/env bash
# YOOLBOT toolbox: coding + reverse-engineering sandbox image and the /projects workspace.
# Run inside Ubuntu (WSL) on the agent laptop. Safe to re-run.
set -euo pipefail
WS="$HOME/.openclaw/workspace"
PROJ="$WS/projects"
mkdir -p "$PROJ" "$HOME/yoolbot-toolbox"

# ---- 1. sandbox image: everything installed up front, because the sandbox has no network
cat > "$HOME/yoolbot-toolbox/Dockerfile" <<'EOF'
FROM openclaw-sandbox:bookworm-slim
USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv python3-pytest \
      nodejs npm git build-essential make gdb \
      ripgrep jq file xxd sqlite3 binutils curl ca-certificates \
      binwalk yara \
  && rm -rf /var/lib/apt/lists/*
# radare2 was dropped from Debian bookworm: install the official .deb from its GitHub release instead
RUN apt-get update \
 && url=$(curl -fsSL https://api.github.com/repos/radareorg/radare2/releases/latest \
          | jq -r '.assets[].browser_download_url' | grep -E '/radare2_[0-9.]+_amd64\.deb$' | head -1) \
 && curl -fsSLo /tmp/r2.deb "$url" && apt-get install -y /tmp/r2.deb \
 && rm -rf /tmp/r2.deb /var/lib/apt/lists/* \
 || echo "radare2 skipped"
RUN pip3 install --no-cache-dir --break-system-packages \
      requests flask fastapi uvicorn pydantic rich typer pyyaml beautifulsoup4 \
      pytest-timeout capstone pyelftools lief
RUN pip3 install --no-cache-dir --break-system-packages pwntools || echo "pwntools skipped"
# v3 additions: code quality, more languages, data/docs, IoT, runtime tracing
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      shellcheck golang-go rustc cargo pandoc mosquitto-clients strace ltrace \
  && rm -rf /var/lib/apt/lists/*
RUN (apt-get update && apt-get install -y --no-install-recommends hexyl && rm -rf /var/lib/apt/lists/*) || echo "hexyl skipped"
RUN pip3 install --no-cache-dir --break-system-packages ruff mypy hypothesis pandas esptool
RUN git config --system user.name "YOOLBOT" \
 && git config --system user.email "yoolbot@localhost" \
 && git config --system init.defaultBranch main \
 && git config --system --add safe.directory '*'
USER sandbox
WORKDIR /home/sandbox
EOF
docker build -t yoolbot-toolbox:3 "$HOME/yoolbot-toolbox"

# ---- 2. the projects workspace (git repo the agent builds in)
if [ ! -d "$PROJ/.git" ]; then
  git -C "$PROJ" init -q -b main
  cat > "$PROJ/BACKLOG.md" <<'EOF'
# Backlog
One idea per line, top = next. YOOLBOT moves finished items to PROGRESS.md.

- [ ] sslcheck: CLI that reads a list of domains and reports days until each TLS certificate expires (offline-testable with a fake cert fixture)
- [ ] logsum: CLI that summarizes an auth.log or Windows security CSV into top users, IPs and failed logins
- [ ] hashcheck: CLI that hashes every file in a folder and diffs against a saved baseline (file integrity monitor)
EOF
  printf '# Progress\n\n' > "$PROJ/PROGRESS.md"
  git -C "$PROJ" add -A && git -C "$PROJ" -c user.name=Sam -c user.email=sam@localhost commit -qm "Seed backlog"
fi
chmod -R a+rwX "$PROJ"     # the sandbox user must be able to write here

# ---- 3. point OpenClaw at the new image and mount /projects read-write
openclaw config set agents.defaults.sandbox.docker.image yoolbot-toolbox:3
openclaw config set agents.defaults.sandbox.docker.binds \
  "[\"$WS/screen:/screen:rw\",\"$WS/data:/data:ro\",\"$PROJ:/projects:rw\"]" --json

# ---- 4. tell the agent about its toolbox and /projects (once each)
grep -q "^## Toolbox" "$WS/AGENTS.md" 2>/dev/null || cat >> "$WS/AGENTS.md" <<'EOF'

## Toolbox (installed in your sandbox, no network)
Python 3 + pytest, hypothesis, ruff, mypy, pandas, requests, flask, fastapi, rich, typer; Node + npm; Go; Rust (cargo);
gcc/make/gdb; git; shellcheck; pandoc; jq, ripgrep, sqlite3, xxd, hexyl; strace, ltrace, file, binutils, radare2, binwalk, yara,
capstone, pyelftools, lief, pwntools; esptool and mosquitto-clients (hardware/MQTT, only when Sam asks).
Before committing Python: run ruff check and the tests. Before committing shell scripts: run shellcheck.
EOF

grep -q "^## Projects" "$WS/AGENTS.md" 2>/dev/null || cat >> "$WS/AGENTS.md" <<'EOF'

## Projects
/projects is a git repo where you build software. Each project lives in /projects/<name>/ with a README.md, source and tests.
Work loop: plan briefly, write code and tests, run the tests, fix until they pass, then git commit with a clear message.
There is no network: use only what is installed (python3, pytest, node, gcc, git, radare2, binwalk, yara). Never try pip/npm install.
Never write outside /projects and /screen.
EOF

docker rm -f $(docker ps -aq --filter ancestor=openclaw-sandbox:bookworm-slim) >/dev/null 2>&1 || true
systemctl --user restart openclaw-gateway
echo
echo "Toolbox ready: image yoolbot-toolbox:3, /projects mounted read-write."
docker run --rm --network none yoolbot-toolbox:3 sh -c 'python3 --version; node --version; gcc --version | head -1; (r2 -v 2>/dev/null | head -1 || echo "radare2: not installed"); pytest --version; go version; cargo --version; ruff --version; shellcheck --version | sed -n 2p'
