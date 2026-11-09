# Gaming PC helpers

- [`gpustat.ps1`](gpustat.ps1): a tiny TCP responder bound to the PC's Tailscale IP. It ignores the request and returns one fixed-shape JSON from `nvidia-smi` (utilization, VRAM, temp, power, clock). No parameters, no commands, no files.
- [`setup-gpustat.ps1`](setup-gpustat.ps1): installs the reporter to `C:\ProgramData\yoolbot` (admin-only write), adds a firewall rule for the agent laptop only, and runs it at logon as a limited user.

Set the `<…_TAILSCALE_IP>` placeholders first. The scripts refuse to run until you do.
