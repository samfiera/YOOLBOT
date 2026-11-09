# Projects

`~/.openclaw/workspace/projects` is a git repo that is mounted read-write into the sandbox as `/projects`. The [build loop](../automations/build-loop.md) works through `BACKLOG.md` on its own, and a nightly Claude Code review ([ops](../ops/)) checks its commits.

[`BACKLOG.example.md`](BACKLOG.example.md) is the current bank of 40+ project ideas. All of them are offline and defensive, and the RE work only touches files the agent creates itself. Pushing to GitHub is done by hand after review, never by an agent.
