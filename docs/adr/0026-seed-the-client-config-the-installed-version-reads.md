# tui-ide-ADR-0026: Seed the client config the installed version reads

**Status:** Accepted
**Date:** 2026-10-02
**Supersedes:** [ADR-0024](0024-seed-the-opencode-client-config.md)

## Context

ADR-0024 made `install.sh` seed `cli.json`, opencode 2's global client config,
and retired the v1 `tui.jsonc.example`. That is right for v2 and wrong for v1:
v1 reads `tui.json(c)` and ignores `cli.json`, so on the pinned 1.x line
(ADR-0025) a machine provisioned by `install.sh` got no client config at all and
fell back to opencode's default theme. Nothing failed, so the drift from the
tracked iTerm2 palette that ADR-0013 exists to prevent was silent again.

Neither filename is wrong on its own. The repo does not know which line a
machine will be on, and with ADR-0025 in place both are live possibilities: the
pin is expected to be lifted eventually, not to be permanent.

## Decision

Both examples are tracked again,
`dotfiles/opencode/.config/opencode/tui.jsonc.example` for v1 and `cli.json.example`
for v2, and `install.sh` seeds the one the installed major version reads. It
takes the major from `opencode --version` and picks:

- major 2 or higher: `cli.json`, the v2 spelling, theme
  `{ "name": "system", "mode": "system" }`
- major 1: `tui.jsonc`, the v1 spelling, theme `"system"`

When opencode is not installed at all, `install.sh` seeds nothing and says so,
rather than guessing a line. The apt path does not install opencode, and a
machine that adds it later is told to re-run `install.sh`.

Everything else from ADR-0024 is unchanged: the copy is one-shot, an existing
file is never touched, a symlink is left alone and reported, and the tracked
`*.example` suffix keeps the template out of the live config path. The note for
an upgraded machine now names whichever stale file is present, whichever line is
installed.

## Consequences

### Positive

- Correct on either line, so the pin in ADR-0025 costs nothing in theme
  fidelity and lifting it later needs no repo change.
- Both examples stay tracked and readable, so the version-specific spellings
  are documented in one place instead of split across commits.
- A machine that moved lines and kept the other filename is told which file is
  inert, which is the failure the note exists for.

### Negative

- Two examples to keep in step with opencode's schema, and a version bump on
  either side now means checking which one is current.
- `install.sh` parses a version string, which is the kind of thing that breaks
  silently if the output format changes; the failure mode is a wrong filename,
  which the stale-file note then surfaces.
- A machine that installs opencode after provisioning must re-run `install.sh`,
  one step the pure v1 or pure v2 versions did not ask for.

### Neutral

- The tracked files keep their `.example` suffix and `dotfiles/opencode/` stays
  a template directory rather than a stow package, so ADR-0023's reasoning about
  `~/.config/opencode` still applies unchanged.
- The agent config (`opencode.json`) stays machine-local and untracked, as
  ADR-0024 described.
- Theme drift between the two spellings would be invisible to
  `brew bundle` and `install.sh`; both are static copies by design.

## See Also

- [ADR-0024](0024-seed-the-opencode-client-config.md)
- [ADR-0025](0025-pin-opencode-to-the-1.x-line.md)
- [ADR-0013](0013-apply-color-scheme-on-fresh-machine.md)
- [Architecture](../architecture.md)
