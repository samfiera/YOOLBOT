# YOOLBOT

> A hardened, always-on AI companion hosted on a dedicated home server — controllable from anywhere via Telegram.

[![Status](https://img.shields.io/badge/status-live-10b981?style=flat-square)](https://samfiera.neocities.org)
[![Stack](https://img.shields.io/badge/stack-OpenClaw%20%7C%20WSL2%20%7C%20Gemini%20Flash-3b82f6?style=flat-square)](#stack)
[![Security](https://img.shields.io/badge/security-hardened-10b981?style=flat-square)](#security-posture)

---

## What is YOOLBOT?

YOOLBOT is a personal AI assistant I built and self-host on a dedicated, freshly-wiped laptop. It runs 24/7, can execute scheduled background tasks autonomously via cron, and is fully controllable from my phone through a Telegram bot interface.

This repo documents the project architecture, design decisions, and security posture. The source code is not published here — this is a showcase and reference document.

**Full technical write-up:** [samfiera.neocities.org/yoolbot-writeup.html](https://samfiera.neocities.org/yoolbot-writeup.html)

---

## Why I Built This

I wanted an AI assistant that was genuinely mine — not a SaaS endpoint, not something that reset context every session, and not something running on hardware I shared with personal data. I wanted persistent, always-on compute under my control.

As someone building a career in security, I also wanted to understand what running an internet-connected AI agent looks like from a threat modelling perspective. This project served two purposes: build something useful, and deliberately stress-test my own infrastructure decisions.

---

## Architecture

```
[Telegram App] --> [Telegram API] --> [VPS Relay (static IP)] --> [YOOLBOT Host (WSL2)]
                                                                         |
                                                              [OpenClaw Agent Runtime]
                                                                         |
                                                              [Gemini Flash API (LLM)]
                                                                         |
                                                              [Cron Scheduler (background tasks)]
```

### How a request flows

1. Message sent from Telegram on my phone
2. Telegram's API servers receive it
3. Traffic routes through a VPS relay with a static IP (home IP is never exposed)
4. YOOLBOT's polling loop picks up the message inside WSL2
5. OpenClaw processes it through the Gemini Flash API
6. Response is sent back through the same chain

Separately, cron jobs fire on schedule and execute tasks independently of any user input.

---

## Stack

| Layer | Technology |
|---|---|
| Host OS | Windows (freshly wiped, dedicated machine) |
| Runtime environment | WSL2 (Ubuntu) |
| Agent framework | OpenClaw |
| LLM backend | Google Gemini Flash (via API) |
| Command interface | Telegram Bot API |
| Task scheduling | Cron |
| External connectivity | VPS relay (static IP) |

---

## Security Posture

This was not a casual deployment. Every component was treated as a potential attack surface.

### Host preparation
- Laptop fully wiped before setup — no residual personal data, credentials, or software
- Rebuilt from a known-clean state so the entire software surface is accounted for

### Network hardening
- UFW configured with default-deny inbound inside WSL2
- Unused ports audited and closed on both the Windows host and the WSL2 environment
- Unnecessary Windows services disabled post-install
- Home IP never exposed — all external traffic routes through a VPS relay
- No inbound ports opened on the home router

### Process isolation
- Bot runs as a dedicated non-root user (`yoolbot`) with no sudo access
- Blast radius of any agent compromise limited to that user's file scope
- Cron jobs scoped to the same low-privilege user; all scripts `chmod 750`

### Secrets management
- API keys and bot token stored in `.env` file only — never hardcoded
- `.env` set to `chmod 600`, owned by the bot user
- Version control excludes all secrets via `.gitignore`

### Access control
- Telegram account protected with strong password and 2FA
- Telegram account is the sole command interface — no other inbound access path exists
- Bot token not shared or published anywhere

### Threat model summary

| Threat | Mitigation |
|---|---|
| Prompt injection | Input locked to authenticated Telegram account only |
| Shell escalation via agent | Non-root user, no sudo |
| API key exposure | `.env` only, `chmod 600`, excluded from VCS |
| Telegram account takeover | Strong password + 2FA |
| Open port exploitation | UFW default-deny, VPS relay hides home IP |
| Cron privilege escalation | Runs as `yoolbot` user, scripts `chmod 750` |
| Personal data exfiltration | No personal data on the host machine |

---

## What YOOLBOT Can Do

- Respond to messages 24/7 via Telegram from any device
- Execute autonomous background tasks on a cron schedule
- Run independently of user input — persistent, always-on
- Operate on isolated hardware with a locked-down security posture

---

## What This Repo Does Not Contain

- Bot source code
- API keys or tokens
- OpenClaw configuration files with personal setup details
- Conversation logs or cron outputs
- Any sensitive operational data

This is intentional. The purpose of this repo is to document the project publicly without exposing anything that could be used against the infrastructure.

---

## Links

- **Portfolio:** [samfiera.neocities.org](https://samfiera.neocities.org)
- **Full write-up:** [samfiera.neocities.org/yoolbot-writeup.html](https://samfiera.neocities.org/yoolbot-writeup.html)
- **GitHub:** [github.com/samfiera](https://github.com/samfiera)

---

*Part of the YOOL project — Your Own Ongoing Legacy.*
