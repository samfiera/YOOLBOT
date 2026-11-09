# Setup

This is the order I built it in. It's a reference, not a one-click installer: configs with tokens, IPs and account details are deliberately left out of this repo. Placeholders look like `<LIKE_THIS>`.

## 1. Gaming PC: Ollama

```powershell
# User environment variables, then restart Ollama from the tray
setx OLLAMA_HOST 0.0.0.0
setx OLLAMA_KEEP_ALIVE 2h
setx OLLAMA_FLASH_ATTENTION 1
setx OLLAMA_KV_CACHE_TYPE q8_0

ollama pull qwen3-coder:30b
ollama pull qwen3.5:9b
```

Allow port 11434 from the agent laptop's Tailscale IP only:

```powershell
New-NetFirewallRule -DisplayName "Ollama (agent laptop only)" -Direction Inbound -Protocol TCP `
  -LocalPort 11434 -RemoteAddress <LAPTOP_TAILSCALE_IP> -Action Allow
```

### Scheduled wake (PC sleeps at night)

Run in an admin PowerShell:

```powershell
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
powercfg /setactive SCHEME_CURRENT

$a  = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c exit"
$t1 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 6:38
$t2 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday,Sunday -At 8:53
$s  = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$p  = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U
Register-ScheduledTask -TaskName "YOOLBOT wake" -Action $a -Trigger $t1,$t2 -Settings $s -Principal $p -Force

powercfg /waketimers   # should list "YOOLBOT wake"
```

### GPU reporter (optional, for the rig view)

Set the two IPs in [`pc/gpustat.ps1`](../pc/gpustat.ps1) and [`pc/setup-gpustat.ps1`](../pc/setup-gpustat.ps1), then run in an admin PowerShell from that folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-gpustat.ps1
```

## 2. Tailscale grants

Tag the machines and allow only what's needed (example policy, adapt the tags):

```json
{
  "grants": [
    { "src": ["autogroup:member"], "dst": ["tag:agent"],  "ip": ["tcp:443"] },
    { "src": ["tag:agent"],        "dst": ["tag:gpu-pc"], "ip": ["tcp:11434", "tcp:11435"] },
    { "src": ["tag:gpu-pc"],       "dst": ["tag:agent"],  "ip": ["tcp:22"] }
  ]
}
```

No Funnel, no exit nodes, no router port forwards. On the laptop, turn on **Run unattended** in Tailscale so it stays connected at the Windows sign-in screen.

## 3. Agent laptop: OpenClaw (WSL2)

Install OpenClaw in WSL2 Ubuntu, point the `ollama` provider at the PC's Tailscale address, then harden:

| Setting | Value |
|---|---|
| Gateway bind | loopback, token auth, exposed with `tailscale serve` |
| Primary / fallback model | `ollama/qwen3-coder:30b` / `ollama/qwen3.5:9b` |
| `tools.byProvider` | deny `web_fetch` and `browser` for **every** model |
| `plugins.allow` | `ollama`, `duckduckgo`, `memory-core`, `device-pair`, `document-extract` |
| Sandbox | mode `all`, workspace `ro`, scope `session`, network `none`, read-only root, cap drop `ALL` |
| Sandbox image | `yoolbot-toolbox:3` |
| Sandbox binds | `~/.openclaw/workspace/screen:/screen:rw`, `…/data:/data:ro`, `…/projects:/projects:rw` |
| Secrets | OpenClaw secret store (SecretRef), nothing in plain config |

Then run `openclaw security audit` and document anything you accept.

Bind sources must be inside `~/.openclaw/workspace`, or the sandbox refuses them.

## 4. Toolbox image + projects repo

```bash
bash toolbox/setup-toolbox.sh
```

This builds `yoolbot-toolbox:3` (languages, test/lint tools, RE tools; everything pre-installed because the sandbox has no network) and creates `~/.openclaw/workspace/projects` as a git repo with a starter backlog. Swap in [`projects/BACKLOG.example.md`](../projects/BACKLOG.example.md) for the full bank.

## 5. Hub + room display

```bash
bash hub/install.sh
nano ~/.config/yoolbot-hub.env      # set YOOLHUB_LAT / YOOLHUB_LON, optional fantasy league
systemctl --user restart yoolbot-hub
```

Point a kiosk browser on the laptop at `http://localhost:8787` on the portable monitor. [`laptop/hidecursor.ps1`](../laptop/hidecursor.ps1) parks the cursor at logon (run it from a scheduled task).

Teach the agent the screen contract by adding a section to its `AGENTS.md`: what `/screen/now.json` and the `.md` files are, the allowed moods, and that they're the only files it may write outside `/projects`.

## 6. Automations

Create the jobs in [`automations/`](../automations) in OpenClaw's scheduler.

## 7. Ops agent (Claude Code)

```bash
curl -fsSL https://claude.ai/install.sh | bash
bash ops/setup-claude-ops.sh
cd ~/yoolbot-ops && claude remote-control --name YOOLBOT   # one time: trust + enable, then Ctrl+C
systemctl --user enable --now yoolbot-claude-rc
```

Open the Claude app → **Code** → **YOOLBOT** to drive it from your phone. The nightly review runs at 23:30.

## 8. Keep the laptop reachable

- Tailscale: **Run unattended**
- `Set-Service sshd -StartupType Automatic`
- Windows Update active hours, so restarts happen overnight
- Lock screen and sleep: never, on AC power (it's a display)
