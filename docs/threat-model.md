# Threat model

**Assumption: the model will eventually follow a malicious instruction.** Small local models are much easier to prompt-inject than frontier models, and the agent reads web search results every morning. So every layer is built for the case where the model is already hijacked.

The design goal: **the worst case is a wrong sentence on my screen or a bad commit in a sandboxed folder.**

## Threats and controls

| If this happens | This stops it |
|---|---|
| A search result contains injected instructions | Snippets only: `web_fetch` and `browser` are denied for every model, and the sandbox has no network, so there's nowhere to send data |
| The agent runs a harmful command | Docker sandbox: read-only root, all capabilities dropped, non-root, no network |
| It rewrites its own instructions or config | Workspace mounted read-only. Only `/screen` and `/projects` are writable |
| It fakes data on the display | Facts (scores, fantasy, GPU, health) come from the hub's own code. The model can only add text. Plain-text rendering, size caps, expiry, symlinks refused, and it can't trigger red/amber states |
| Lateral movement between devices | Tailscale grants allow exactly the paths in [architecture](architecture.md#network-paths), and Windows Firewall rules match them |
| Someone tries to get in from outside | No public ports, no Funnel, no port forwards. Gateway on loopback behind Tailscale Serve. SSH is key-only |
| A malicious or vulnerable plugin | Plugin allowlist: 5 of 66 load |
| A compromised GPU reporter or hub endpoint is used as a pivot | The reporter ignores its input and returns a fixed numbers-only JSON. The hub binds to loopback with a Host allowlist and strict CSP |
| Secrets leak through the model | Secrets are in OpenClaw's write-only store. The model never sees them, and the sandbox can't read the config |
| A newly added model skips the tool deny list | Lesson learned: `tools.byProvider` rules are per model, so every new model gets added and the audit re-run |

## Accepted risk

`openclaw security audit`: **0 warnings, 1 critical accepted**. A small model with web search enabled is flagged as prompt-injectable. It's accepted because of the compensating controls above: no fetch, no browser, no sandbox network, read-only workspace, a single writable display folder.

## Residual risks I'm aware of

- **The ops agent (Claude Code) runs outside the sandbox** as my WSL user. That's mitigated by a deny list (secrets, SSH keys, `~/.config`, push, sudo, ssh, Tailscale), ask-first rules for configs and restarts, and approvals on my phone. Never run it in bypass mode.
- **Physical access.** The laptop sits in my room. I chose not to auto-login (no stored password), so after a reboot I sign in by hand.
- **Supply chain** for the toolbox image (pip, apt, a radare2 release). It's built once and then runs with no network.
- **Search quality.** DuckDuckGo snippets can be wrong or rate-limited. The brief says "unavailable" instead of guessing.

## Out of scope by design

- No work data, work accounts or work tooling. This is a personal lab.
- No messaging bridge (Telegram etc.) in v2. The web UI over Tailscale is enough.
- No offensive tooling. RE only on files the agent creates or I own.
