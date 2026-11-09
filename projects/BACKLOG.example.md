
# Backlog bank 2 (added 2026-10-13)

Rules for every item: Python 3.11 unless stated. No network access, so use only the standard library or packages already in the toolbox. Each project lives in /projects/<name>/ with a README.md, tests (pytest, at least 5) and sample input under /projects/<name>/samples/. Commit only when tests pass. Work top to bottom; tick the box when done.

## Tier 1 — SOC / blue-team utilities

- [ ] **iocx** — Extract IOCs (IPv4/IPv6, domains, URLs, hashes, emails, CVE IDs) from any text file. Handle defanged forms (hxxp, [.]) and output JSON/CSV. Done when: samples include a sample threat report and output is deduplicated.
- [ ] **defang** — Defang/refang IOCs both ways, CLI and library. Done when: round-trip property tests pass (hypothesis).
- [ ] **evtxsum** — Summarize Windows Security event exports (CSV/JSON): logon types, top accounts, failed-logon bursts (4625), new services (7045), log clears (1102). Done when: generates a markdown report from sample data you create.
- [ ] **authlogsum** — Parse Linux auth.log: failed SSH by source, sudo usage, new users. Flag brute-force windows (N failures in M minutes, configurable). Done when: markdown report + JSON.
- [ ] **sigma-lite** — Minimal Sigma rule evaluator: load YAML rules (selection/condition with and/or/not, contains/startswith/endswith) and run against JSON-lines logs. Done when: 10 sample rules and matching/non-matching test logs.
- [ ] **yara-runner** — Wrap yara-python: scan a folder with a rules dir, output JSON hits with offsets. Done when: includes 5 benign demo rules (strings in test files).
- [ ] **phishparse** — Parse .eml files: headers, Received chain hops, SPF/DKIM/DMARC result headers, links (display text vs href mismatch), attachments with hashes. Done when: verdict hints in a markdown report, sample emails created by you.
- [ ] **urlscore** — Offline heuristic URL risk scorer: length, entropy, IP host, punycode, suspicious TLD list, lookalike brands via edit distance. Done when: explains each score component.
- [ ] **hashset** — Build and diff hash baselines of a directory (sha256, size, mtime). Report added/removed/changed. Done when: JSON baseline format documented.
- [ ] **cvecalc** — CVSS v3.1 base score calculator from vector strings, with validation. Done when: matches 10 known published vectors in tests.
- [ ] **timeline** — Merge several log sources (CSV/JSON-lines with timestamps in mixed formats) into one sorted UTC timeline CSV. Done when: handles timezone offsets and epoch ms.
- [ ] **pcapsum** — Summarize a pcap using only the standard library (parse pcap headers, Ethernet/IPv4/TCP/UDP): top talkers, ports, DNS query names. Done when: you generate a small pcap fixture in tests by writing bytes.
- [ ] **dnsentropy** — Score domain names for DGA-likeness (entropy, consonant runs, digit ratio, n-gram rarity from a bundled English word list). Done when: separates a sample of normal vs random strings.
- [ ] **b64hunt** — Find and decode base64/hex/gzip blobs embedded in scripts or logs, recursively, and print the decoded preview safely (printable only). Done when: handles nested encodings 3 levels deep.
- [ ] **pslog** — Parse PowerShell script-block log exports and flag obfuscation traits (char joins, -enc, backticks, long base64). Done when: explains each flag; no execution of anything.

## Tier 2 — Hardening and audit

- [ ] **sshdaudit** — Audit an sshd_config file against a hardening checklist (root login, password auth, ciphers, MaxAuthTries). Done when: markdown report with pass/fail per check.
- [ ] **dockeraudit** — Lint a docker-compose.yml / Dockerfile for risky settings (privileged, host network, root user, latest tags, ADD from URL). Done when: severity per finding.
- [ ] **permscan** — Find world-writable files, SUID binaries and secrets-looking filenames in a given tree (read-only). Done when: tested against a fixture tree it creates in tmp.
- [ ] **secretscan** — Regex + entropy scanner for leaked keys/tokens in a repo, with an allowlist file. Done when: run on /projects itself and report is clean or explained.
- [ ] **cfgdiff** — Semantic diff for YAML/JSON/INI configs (ignore ordering, show path-level changes). Done when: CLI with colored and plain modes.
- [ ] **pwpolicy** — Password policy checker: given a policy JSON, evaluate candidate passwords and explain failures; estimate entropy. Done when: no passwords stored or logged.
- [ ] **certparse** — Parse PEM/DER certificates offline (cryptography or ssl module): subject, SANs, expiry, key size, weak signature algos. Done when: test certs generated in the tests.
- [ ] **openclaw-audit-diff** — Compare two JSON outputs of a security audit and report new/fixed findings. Done when: works on sample files you create.

## Tier 3 — Reverse engineering and IoT (offline, own files only)

- [ ] **elfinfo** — Summarize an ELF with pyelftools/lief: arch, sections, imports, entropy per section, strings of interest. Done when: tested on binaries compiled in the sandbox with gcc.
- [ ] **peinfo** — Same for PE files using lief: imports, sections, timestamps, entropy. Done when: tested on a minimal PE fixture if one can be built, otherwise documented sample.
- [ ] **fwinspect** — Wrap binwalk for firmware images: list signatures, carve to a folder, report filesystems found. Done when: tested on a synthetic image you build (concatenated gzip + squashfs-like header).
- [ ] **crackmes-own** — Write 5 small C crackme programs (password checks of increasing difficulty), build them, then write a solver notes file for each using radare2 output. Done when: each solution is verified by running the binary.
- [ ] **disasm-diff** — Disassemble two builds of the same C function (capstone) at -O0 and -O2 and produce a side-by-side markdown explanation. Done when: 3 example functions.
- [ ] **mqtt-sim** — Simulated IoT sensors as Python classes publishing to an in-process broker stub; a validator that enforces a topic allowlist. Done when: rejects topics outside the allowlist in tests.
- [ ] **serial-parse** — Parser for a made-up UART sensor protocol (framing, checksum, escaping) with a fuzz test (hypothesis). Done when: no crash on random bytes.

## Tier 4 — YOOLBOT itself

- [ ] **screenlint** — Validator for /screen/now.json and the .md files: schema, size caps, allowed moods, ttl ranges. Done when: CLI exit codes 0/1.
- [ ] **briefcheck** — Check that brief.md has every required section and no URLs with raw IPs. Done when: used as a pre-write check example in README.
- [ ] **backlog-tool** — CLI to list/add/complete items in BACKLOG.md and print progress stats. Done when: round-trips this file without changing formatting.
- [ ] **progress-report** — Generate a weekly markdown summary of git commits in /projects (projects done, lines added, test counts). Done when: writes /screen/builds.md format.
- [ ] **fantasy-math** — Given fantasy JSON exports (sample schema you define), compute positional scarcity and a waiver priority score. Done when: explains the formula.
- [ ] **fixtures-ics** — Turn a fixtures JSON (sample) into an .ics calendar file with correct UTC times. Done when: validates with the standard ics format rules.

## Tier 5 — Bigger builds (multi-session)

- [ ] **minisiem** — Tiny log pipeline: ingest JSON-lines into SQLite, run sigma-lite rules on a schedule, write alerts to a markdown file. Reuse iocx, sigma-lite, timeline. Done when: end-to-end test from raw logs to alert file.
- [ ] **casefile** — Incident case notebook CLI: create case, add evidence (with hashes), timeline entries, export a report via pandoc to HTML. Done when: export works offline.
- [ ] **ctf-toolkit** — One CLI that bundles b64hunt, elfinfo, hash utilities and common encodings (rot, xor brute over single byte, hex) for CTF triage of own challenge files. Done when: subcommands documented.
- [ ] **dashboard-lite** — FastAPI app serving read-only views of minisiem alerts and progress-report, bound to 127.0.0.1 only. Done when: tests use TestClient; no outbound calls.
- [ ] **go-port** — Port hashset to Go and compare speed with the Python version on a generated 10k-file tree. Done when: benchmark table in README.
- [ ] **rust-port** — Port defang to Rust with cargo tests. Done when: same test vectors as the Python version pass.
