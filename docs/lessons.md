# What broke, and what it taught me

Real failures from the build, mostly found by looking at the room display and asking why a number looked wrong.

| Symptom | Real cause | Fix / lesson |
|---|---|---|
| New coder model could use `web_fetch` | `tools.byProvider` deny rules are per model, so the new model wasn't covered | Add every model to the deny list and re-run the audit whenever a model is added |
| Agent "answered" but nothing appeared on screen | Small models print the result instead of calling the write tool | Prompts spell out every tool step and end with "Always finish by writing …" |
| Agent couldn't write anywhere | Read-only workspace, and bind sources must live inside `~/.openclaw/workspace` | One scoped writable folder (`/screen`) gave the agent a voice without giving it the workspace |
| Brief refused to use search results | The prompt called them "untrusted", so the model ignored them entirely | Say what to take from results and what never to obey |
| Brief had gaps | DuckDuckGo rate-limited (HTTP 202) | Jobs finish with partial data and mark sections "unavailable" |
| Chat fell back to the 9B model | Not a timeout: Ollama hit a CUDA crash after the PC woke from sleep | Check the GPU before the config. A reboot fixed it |
| PC didn't wake for the morning jobs | Wake timers blocked, and the task was set to run only while logged on | `RTCWAKE` enabled in the power plan, task set to `WakeToRun` + S4U. Verify with `powercfg /waketimers` |
| Everything offline after a laptop reboot | At the Windows sign-in screen, Tailscale and WSL are down | Tailscale "run unattended", sshd automatic, Windows Update active hours |
| Rig monitor said 1 TB free | WSL reports a virtual disk | Measure the Windows drive (`/mnt/c`) |
| VRAM meter turned amber at 93% | A 30B model *should* fill VRAM, so that's normal, not degraded | Amber/red only for real states. GPU and VRAM meters never warn |
| Waiver picks were all kickers | The free-agent pool was sorted by projection only | Pull the top free agents per position |
| Backlog full of duplicates | The model rewrote the whole file to tick one box | "Edit ONLY that line", and a nightly review fixes drift |
| Downloaded installer was an old version | The browser renamed repeat downloads to `(1)` | Versioned file names |
