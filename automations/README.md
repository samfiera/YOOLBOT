# Automations

OpenClaw scheduled jobs. Each prompt is written for a small local model, so every tool step and the final write are spelled out. Small models tend to print their answer instead of calling the write tool.

| Job | Schedule | Model | Writes |
|---|---|---|---|
| [morning-brief-weekday](morning-brief.md) | `45 6 * * 1-5` | qwen3.5:35b | `/screen/brief.md`, `/screen/now.json` |
| [fantasy-waivers](fantasy-waivers.md) | `55 6 * * 2` | default | `/screen/fantasy.md` |
| [build-loop](build-loop.md) | `0 18,20,22 * * *` | qwen3-coder:30b | `/projects/**`, `/screen/builds.md` |
| heartbeat | every 30 min | default | nothing unless something is wrong |

Paths are inside the sandbox: `/screen` and `/projects` are the only writable binds, and `/data` is read-only.

Rules that made these reliable:
- Use absolute paths (`/screen/brief.md`). Relative paths resolved against the read-only workspace and failed.
- End with "Always finish by writing…", so a failed search still produces partial output.
- Don't call search results "untrusted". That wording made the model refuse to use them at all. Say what to take from them and what never to obey.
