# Ops agent

[`setup-claude-ops.sh`](setup-claude-ops.sh) turns Claude Code on the agent laptop into YOOLBOT's maintainer, using a Claude subscription. Claude Code is first-party, so no subscription credentials go into third-party tools.

It creates:
- `~/yoolbot-ops/CLAUDE.md`: the system map and house rules (color rule, never push, no secrets)
- `~/yoolbot-ops/.claude/settings.json`: allow / ask / deny permissions. Secrets, SSH keys, `~/.config`, `git push`, `sudo`, `ssh` and `tailscale` are denied. Config edits, restarts and Docker are ask-first.
- `yoolbot-claude-rc.service`: an always-on Remote Control session, so I can chat with it from the Claude app
- `yoolbot-claude-nightly.timer`: a 23:30 headless review of health, the build loop's commits and the backlog, logged to `~/yoolbot-ops/logs/`

Division of labour: **the local model builds, Claude reviews.** Nothing leaves the laptop through git without me.
