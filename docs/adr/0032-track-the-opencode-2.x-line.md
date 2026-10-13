# tui-ide-ADR-0032: Track the opencode 2.x line

**Status:** Accepted
**Date:** 2026-10-13
**Supersedes:** [ADR-0025](0025-pin-opencode-to-the-1.x-line.md)

## Context

ADR-0025 pinned opencode to 1.x because the corporate LLM gateway in use here
(the `bifrost` provider) failed v2 with `Unsupported package for
<provider>/<model>`. That is a configuration gap, not a gateway gap. opencode v2
requires a custom provider to name its runtime package where v1 defaulted to the
OpenAI-compatible SDK. The gateway's config here never named it, so v2 resolved
the package to the empty string and failed every model.

With the package named — `"npm": "@ai-sdk/openai-compatible"` on the existing
v1-shaped provider entry — v2 resolves that provider to
`@opencode/ai/providers/openai-compatible`, discovers the gateway's models, and
serves a request end to end. Verified against the `bifrost` provider: 782 models
discovered and a cheap-lane request returned `V2-GATEWAY-OK`.

The pin was also a moving-target cost: homebrew-core's `opencode` moved to 2.x,
and the tap's 1.x formula keeps advancing separately. Holding 1.x meant carrying
local pin state (ADR-0025's own Negative list).

## Decision

The `Brewfile` takes `brew "anomalyco/tap/opencode-v2"` instead of
`brew "anomalyco/tap/opencode"`, keeping `tap "anomalyco/tap"`. `install.sh`
trusts that one tap formula for Homebrew 7 and no longer runs `brew pin`: with
the toolchain on the line we want, there is nothing to hold back.

A machine whose agent config names no provider package must add
`"npm": "@ai-sdk/openai-compatible"` to its custom provider, or the first request
fails with `Unsupported package`. This is machine-local config
(`~/.config/opencode/opencode.json(c)`), not repo state; the `README` documents
the value and both provider spellings.

ADR-0026 is unchanged and now matters in the other direction: both client-config
examples stay tracked, and `install.sh` seeds `cli.json` on v2 and `tui.jsonc`
on v1, so a machine that rolls back to 1.x is still seeded correctly.

## Consequences

### Positive

- The toolchain tracks the maintained line, so 2.x fixes are reachable without
  local pin state to lose.
- The exit from 1.x is a one-line provider config addition, not a new client.
- Rollback stays cheap: `brew uninstall opencode-v2`, restore the `Brewfile`
  line, and add the pin back (or run `brew pin`), as ADR-0025 recorded.

### Negative

- v1 plugin implementations do not run on v2. The herdr TUI session plugin and
  any files under `~/.config/opencode/plugins/` must be v2 versions or dropped
  until upstream ships them; herdr already installs a v2 entrypoint.
- A machine that upgraded must move values from the inert `tui.jsonc` into
  `cli.json` by hand; v2 migrates `tui.json` but never `tui.jsonc`.

### Neutral

- The pin's absence changes nothing else: `brew bundle` upgrades the v2 formula
  on later runs, which is the point.
- The models-discovery plugin's documented v2 spelling
  (`providers`/`plugins`/`package: "aisdk:@ai-sdk/openai-compatible"`) and the
  v1 spelling with `npm` both work against the installed 2.0.28; the README keeps
  the v1 spelling, which stays valid on both lines.
- The agent config stays machine-local and untracked, as ADR-0024 described.

## See Also

- [ADR-0025](0025-pin-opencode-to-the-1.x-line.md)
- [ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [Architecture](../architecture.md)
