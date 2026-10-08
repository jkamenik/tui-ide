# tui-ide-ADR-0030: Stow the global opencode AGENTS.md

**Status:** Accepted
**Date:** 2026-10-08

## Context

opencode reads a global instruction file at `~/.config/opencode/AGENTS.md` for
every session, in every project, independent of any repo's own `AGENTS.md`. In
this environment it carries the AI attribution trailer rule for git commits —
portable prose with no machine-local values.

It was authored as a live file only. Nothing under `dotfiles/` referenced it, so
it existed on exactly one machine, with no history and no way to reach a second
one.

[ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md) keeps
`dotfiles/opencode/` a template directory rather than a stow package, because
the opencode client config carries a machine-local value (the herdr session
plugin path) that convention 4 forbids tracking and a link would copy into the
repo. That reasoning is specific to the client config; it does not hold for
`AGENTS.md`, which is portable. Stowing the whole `opencode` package is not an
option regardless: it would also link the tracked `*.example` files into the
live config path.

## Decision

Track the file at
`dotfiles/opencode-agents/.config/opencode/AGENTS.md` and stow it, by adding
`opencode-agents` to `DOTFILES` in `install.sh`. It is a dedicated package, so
`dotfiles/opencode/` stays the template directory ADR-0026 describes.

The tracked file keeps its real name — no `.example` suffix — and `install.sh`
links it rather than copying it. A link is the point: the repo is the one source
of truth, so an edit lands in the working tree and applies everywhere, with no
copy-once drift to report. `stow --no-folding` puts a single file symlink at
`~/.config/opencode/AGENTS.md`; the surrounding directory is a real directory
owned by opencode, and no other stow package claims it.

A machine that already has a real `AGENTS.md` is handled by the existing stow
loop: the file is backed up to `~/.dotfiles-backup/<timestamp>/` and replaced by
the link
([ADR-0014](0014-stow-dotfiles-without-folding.md), convention 3).

## Consequences

### Positive

- The global rules have history and reach every machine on the next
  `./install.sh`, instead of living on one.
- A link means no drift: what the repo holds is what opencode reads, with none
  of the copy-once diff reporting the client config and theme still need.

### Negative

- If the file ever gains a machine-local value, it must move to a copy-once or
  overlay shape the way ADR-0026's config did; a link would otherwise put that
  value in the repo.
- `DOTFILES` gains a package that is one file, so the list no longer maps
  one-to-one onto a tool.

### Neutral

- `dotfiles/opencode/` is unchanged and remains a template directory;
  ADR-0026's reasoning about it still applies.
- The agent config (`opencode.json`) stays machine-local and untracked, as
  ADR-0024 established.

## See Also

- [ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [Architecture](../architecture.md)
