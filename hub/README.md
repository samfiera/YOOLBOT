# Hub

The room display. `hub.py` is a stdlib-only Python server on `127.0.0.1:8787`, and `index.html` is the single-page display it serves.

`install.sh` is self-contained (it embeds both files). It installs to `~/yoolbot-hub`, creates `~/.config/yoolbot-hub.env` on first run, and sets up the `yoolbot-hub` systemd user service.

| Variable | Purpose |
|---|---|
| `YOOLHUB_LAT`, `YOOLHUB_LON` | Weather location |
| `YOOLHUB_FF_LEAGUE`, `YOOLHUB_FF_TEAM` | Optional public ESPN fantasy league + your team id |
| `YOOLHUB_SCREEN_DIR` | Where the agent writes screen files |

The Ollama URL and model come from `~/.openclaw/openclaw.json`. The GPU reporter is reached at the same host on port 11435.

After editing `hub.py` or `index.html`, rebuild the installer so all three stay in sync. The page reloads itself when `index.html` changes.
