# tui-ide-ADR-0027: Pin the opencode nono pack to 0.2.0

**Status:** Accepted
**Date:** 2026-10-05

## Context

[ADR-0020](0020-sandbox-agent-clis-with-nono.md) sandboxes `opencode` and
`claude` with nono, using the `nolabs-ai/opencode` and `nolabs-ai/claude`
registry packs that `install.sh` pulls. Those pulls were unpinned, so
`install.sh` and `nono update` both follow the latest pack.

The `nolabs-ai/opencode` pack 0.3.0 (2026-10-02) added `--standalone` to its
profile's `command_args`. That is a v2 isolation flag, filed in the pack README
under "OpenCode v2 Sandbox Isolation": v2 normally runs tools in a shared
background server, and `--standalone` forces a private server inside the
sandbox. [ADR-0025](0025-pin-opencode-to-the-1.x-line.md) pinned opencode to
v1 (1.18.34) because v2 fails against the LLM gateway. v1 has no `--standalone`
option: it treats the flag as unknown, prints its help, and exits 1. So every
sandboxed `opencode` launch exits immediately.

`command opencode --standalone` exits 1, and under nono the TUI never starts.
The denied-path footer nono prints alongside it (`/Users`, `$HOME`, the
workdir's ancestors) is a separate, non-fatal diagnostic: it is opencode's
startup config walk, denied by design, and the wrapper already suppresses the
save prompt for it ([ADR-0021](0021-derive-nono-profile-from-observed-use.md)).
It is not the failure.

The registry serves versioned packs (`nono pull <pack>@<version>`) and
`nono pin` excludes an installed pack from `nono update`, mirroring the
Homebrew formula pin ADR-0025 already uses. Pack 0.2.0 predates the v2 flag, its
profile carries no `command_args`, and it supports the v1 plugin API.

## Decision

`install.sh` pulls `nolabs-ai/opencode@0.2.0` and then runs
`nono pin nolabs-ai/opencode`. The `nolabs-ai/claude` pack stays unpinned.

The pack pin and the opencode formula pin track each other: lifting one without
the other reintroduces the failure, so they move together when v2 becomes
usable against the gateway.

## Consequences

### Positive

- Sandboxed `opencode` starts again on the pinned v1 line, reproducibly on a
  fresh machine and on a re-provision.
- The pin is explicit in the repo, so a `nono update` cannot silently pull the
  v2 flag back.

### Negative

- The pack is deliberately behind; plugin, skill, and profile fixes that land
  only on 0.3.0 or later are unreachable until the pin is lifted.
- Two version pins now have to be lifted as one change, so a future move to v2
  touches the `Brewfile`, `install.sh`, and both ADRs together.

### Neutral

- `nono outdated` reports `nolabs-ai/opencode` as `outdated (pinned)`, which is
  the expected signal that the pin is doing its job.

## See Also

- [ADR-0020](0020-sandbox-agent-clis-with-nono.md)
- [ADR-0021](0021-derive-nono-profile-from-observed-use.md)
- [ADR-0025](0025-pin-opencode-to-the-1.x-line.md)
