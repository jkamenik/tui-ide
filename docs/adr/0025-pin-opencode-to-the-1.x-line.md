# tui-ide-ADR-0025: Pin opencode to the 1.x line

**Status:** Accepted
**Date:** 2026-10-02

## Context

opencode 2 does not work against the LLM gateway in use here. It is a corporate
gateway, and only the v1 client completes a request against it: under v2 the
same provider fails with `Unsupported package for <provider>/<model>`, because
v2 requires a custom provider to name its runtime package where v1 defaulted to
the OpenAI-compatible SDK. The projects worked on here depend on that gateway,
so v2 is not a usable toolchain today and this repo has to keep provisioning
v1.

The channels all move, which is what makes pinning necessary rather than merely
preferable:

- `anomalyco/tap` ships both lines as separate, mutually conflicting formulae,
  `opencode` (1.18.34) and `opencode-v2` (2.0.22), so a stale v2 tap formula can
  be swapped for the v1 one without uninstalling first.
- homebrew-core's `opencode` moved to 2.0.20, so core is no longer a v1 channel.
- npm's `opencode-ai@latest` is still 1.18.34, but that would split the
  toolchain across two package managers.
- `brew bundle` upgrades unpinned formulae on every run, and
  `install.sh` runs it, so an unpinned 1.x would be replaced on the next
  provision even without anyone asking.

A v1 install also self-updates: v1's client upgrades its own binary by default
(`autoupdate`, `boolean | "notify"` in the v1 config schema).

## Decision

The `Brewfile` takes `brew "anomalyco/tap/opencode"` instead of the unqualified
`brew "opencode"`, and taps `anomalyco/tap`. `install.sh` trusts that one
formula for Homebrew 7, then runs `brew pin anomalyco/tap/opencode` after
`brew bundle`. The pin is what holds the line: `brew bundle` builds its upgrade
list as outdated formulae minus pinned ones, so a pinned formula is installed
and left alone while the 1.x line keeps advancing.

Machines leave v2 by uninstalling the tap's `opencode-v2` and running
`install.sh`; the tap's v1 formula installs over the name and the pin lands in
the same run.

## Consequences

### Positive

- Provisioning is repeatable: a fresh machine and a re-run both land on the
  working line, without remembering a manual pin.
- The pin follows 1.x, so security and bug fixes on the v1 line still arrive.
- `brew unpin anomalyco/tap/opencode` plus a `Brewfile` edit is the whole exit,
  and no other part of the repo assumes a version.

### Negative

- The toolchain is deliberately behind. Anything fixed only in 2.x stays
  unreachable, including the v2 client-config spelling ADR-0026 keeps working.
- A machine holding the v2 tap formula must uninstall it before `install.sh`
  can install the v1 one; `conflicts_with` makes that an explicit step rather
  than an in-place upgrade.
- The pin is local Homebrew state, not repo state. A machine provisioned
  outside `install.sh`, or one whose pinned state is lost to a Homebrew prefix
  reset, needs `brew pin` again; nothing else in the repo would notice.

### Neutral

- `brew pin` warns instead of failing when the formula is already pinned, so the
  call is idempotent, and it fails on a formula that is not installed, so it
  must stay after `brew bundle`.
- ADR-0024's premise stands but is deferred: v2's client config is the right
  target once this pin is lifted.
- The agent config stays machine-local either way; ADR-0024's provider note
  becomes irrelevant while the pin holds, since v1 reads the v1 spelling.

## See Also

- [ADR-0024](0024-seed-the-opencode-client-config.md)
- [ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [Architecture](../architecture.md)
