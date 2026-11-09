#!/usr/bin/env bash
# Sets up Claude Code (Pro login) as YOOLBOT's ops agent:
#  - ~/yoolbot-ops workspace with CLAUDE.md + scoped permissions
#  - Remote Control server as a systemd user service (chat with it from the Claude app > Code)
#  - Nightly review run at 23:30 (headless)
set -euo pipefail
OPS="$HOME/yoolbot-ops"
CLAUDE_BIN="$HOME/.local/bin/claude"
[ -x "$CLAUDE_BIN" ] || { echo "claude not found at $CLAUDE_BIN"; exit 1; }
mkdir -p "$OPS/.claude" "$OPS/logs" "$HOME/.config/systemd/user"

cat > "$OPS/CLAUDE.md" <<'EOF'
# YOOLBOT ops

You are the maintainer for YOOLBOT, Sam's local AI home server. Be brief.

## System
- This laptop (WSL2): OpenClaw gateway (systemd user unit openclaw-gateway), Docker sandbox image yoolbot-toolbox:3,
  room-display hub (~/yoolbot-hub, systemd user unit yoolbot-hub, 127.0.0.1:8787).
- Gaming PC: Ollama (qwen3-coder:30b primary, qwen3.5:9b fallback). Sleeps nightly, wakes 06:38 weekdays.
- Agent workspace: ~/.openclaw/workspace (screen/, data/, projects/). projects/ is a git repo worked by YOOLBOT's build loop.
- Hub screen files: ~/.openclaw/workspace/screen/{now.json,brief.md,builds.md,fantasy.md}.

## Rules
- Never read or print secrets, tokens, keys, or ~/.openclaw config/credential files. Use `openclaw` CLI status/audit commands instead.
- Never git push. Never open ports, change Tailscale, firewall, or sandbox settings without asking.
- Colors on the hub: red = real failure only, amber = degraded only. Never use them decoratively.
- Commit your own changes in projects/ as "claude: <what>". Keep YOOLBOT's history intact.
- After any change to the hub, run `systemctl --user restart yoolbot-hub` and check `curl -s 127.0.0.1:8787/api/state | head -c 300`.
- To tell Sam something on the room screen, write ~/.openclaw/workspace/screen/now.json:
  {"text":"<=120 chars","mood":"idle|happy|thinking|alert","ttl_min":120}
EOF

cat > "$OPS/.claude/settings.json" <<'EOF'
{
  "permissions": {
    "additionalDirectories": ["~/.openclaw/workspace", "~/yoolbot-hub"],
    "allow": [
      "Bash(git status *)", "Bash(git log *)", "Bash(git diff *)", "Bash(git add *)", "Bash(git commit *)",
      "Bash(python3 *)", "Bash(pytest *)", "Bash(ruff *)", "Bash(ls *)", "Bash(cat *)",
      "Bash(systemctl --user status *)", "Bash(journalctl --user *)", "Bash(curl -s 127.0.0.1:*)",
      "Bash(openclaw status *)", "Bash(openclaw security audit *)", "Bash(docker ps *)", "Bash(df *)", "Bash(free *)"
    ],
    "ask": [
      "Bash(systemctl --user restart *)", "Bash(openclaw config set *)", "Bash(docker *)",
      "Edit(~/.openclaw/**)", "Edit(~/yoolbot-hub/**)"
    ],
    "deny": [
      "Read(~/.openclaw/*.json)", "Read(~/.openclaw/credentials/**)", "Read(~/.openclaw/agents/**)",
      "Read(~/.openclaw/**/.env)", "Read(~/.ssh/**)", "Read(~/.config/**)",
      "Bash(git push *)", "Bash(openclaw config get *)", "Bash(cat ~/.openclaw/*.json)",
      "Bash(tailscale *)", "Bash(sudo *)", "Bash(ssh *)"
    ]
  }
}
EOF

cat > "$OPS/nightly.md" <<'EOF'
Nightly YOOLBOT review. Work only on what you can verify.
1. Health: `systemctl --user status openclaw-gateway yoolbot-hub --no-pager | head -40`, `df -h /mnt/c`, `openclaw status`. Note anything failed.
2. Projects: in ~/.openclaw/workspace/projects, look at commits from the last 24h. Run each touched project's tests.
   Fix real bugs and weak tests. Commit as "claude: review <project>: <what>". Don't restyle working code.
3. Backlog hygiene: BACKLOG.md must have exactly one line per item, finished items ticked in place, no duplicates. Fix if not.
4. Append a dated 3-6 line summary to ~/yoolbot-ops/logs/nightly.md (what was healthy, what you fixed, what needs Sam).
5. Only if something needs Sam: write ~/.openclaw/workspace/screen/now.json with mood "alert" and a short message.
EOF

cat > "$HOME/.config/systemd/user/yoolbot-claude-rc.service" <<EOF
[Unit]
Description=Claude Code Remote Control for YOOLBOT ops
After=network-online.target

[Service]
WorkingDirectory=$OPS
ExecStart=$CLAUDE_BIN remote-control --name YOOLBOT --spawn same-dir --permission-mode acceptEdits
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
EOF

cat > "$HOME/.config/systemd/user/yoolbot-claude-nightly.service" <<EOF
[Unit]
Description=Claude nightly YOOLBOT review

[Service]
Type=oneshot
WorkingDirectory=$OPS
ExecStart=/bin/bash -lc '$CLAUDE_BIN -p "\$\$(cat $OPS/nightly.md)" --permission-mode acceptEdits --permission-prompts none >> $OPS/logs/nightly-raw.log 2>&1'
TimeoutStartSec=3600
EOF

cat > "$HOME/.config/systemd/user/yoolbot-claude-nightly.timer" <<'EOF'
[Unit]
Description=Run Claude nightly YOOLBOT review at 23:30

[Timer]
OnCalendar=*-*-* 23:30:00
Persistent=false

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now yoolbot-claude-nightly.timer
echo
echo "Done. Next, run these ONCE by hand (they ask one-time questions):"
echo "  cd $OPS && claude remote-control --name YOOLBOT     # answer y to trust + enable, then Ctrl+C"
echo "  systemctl --user enable --now yoolbot-claude-rc"
echo "Then open the Claude app > Code > YOOLBOT."
