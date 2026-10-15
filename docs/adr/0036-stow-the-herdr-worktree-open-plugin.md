# tui-ide-ADR-0036: Stow the herdr worktree-open opencode plugin

**Status:** Accepted
**Date:** 2026-10-15

## Context

opencode can create its own Git worktrees (under its state directory) for a
session. herdr already enumerates every worktree of a repository, but keeps a
linked worktree out of its sidebar until it is opened, so an opencode-created
worktree stayed invisible until the user ran `herdr worktree open` by hand.

A custom opencode plugin was written to close that gap: on opencode's
`worktree.updated` event it reconciles herdr's inventory for the changed
repository and opens the linked worktrees that are not open yet, without
focusing them. opencode auto-loads it from the global plugins directory,
`~/.config/opencode/plugins/`.

It was authored as a live file only, in a session against another repository
(`pipeline`). Nothing under `dotfiles/` referenced it, so it existed on exactly
one machine, with no history and no way to reach a second one.

The plugin is portable: it resolves the herdr binary at runtime, falls back to
the usual install locations, and fails closed (skips work) when herdr or a
repository is absent. It carries no machine-local values.

[ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md) keeps
`dotfiles/opencode/` a template directory rather than a stow package, because
the opencode client config carries a machine-local value (the herdr session
plugin path). That reasoning is specific to the client config; it does not hold
for the plugin, which is portable like the `AGENTS.md` of
[ADR-0030](0030-stow-the-global-opencode-agents-md.md). Stowing the whole
`opencode` package is not an option regardless: it would also link the tracked
`*.example` files into the live config path. The plugin is not a file a tool
rewrites in place, so [ADR-0035](0035-machine-owned-config-includes-tracked-config.md)
does not apply either.

## Decision

Track the plugin at
`dotfiles/opencode-plugins/.config/opencode/plugins/herdr-worktree-open.js` and
stow it, by adding `opencode-plugins` to `DOTFILES` in `install.sh`. It is a
dedicated package, so `dotfiles/opencode/` stays the template directory ADR-0026
describes.

The file keeps its real name — no `.example` suffix — and `install.sh` links it
rather than copying it. A link is the point: the repo is the one source of
truth, so an edit lands in the working tree and applies everywhere, with no
copy-once drift to report. `stow --no-folding` puts a single file symlink at
`~/.config/opencode/plugins/herdr-worktree-open.js`. The `plugins/` directory is
a real directory opencode and herdr own — herdr installs its own
`herdr-agent-state.js` beside this file — and no other stow package claims it.

The one portability change made while adopting it: the fallback list of herdr
locations gains `$HOME/.local/bin/herdr`, the target of the herdr.dev installer
that `install.sh`'s apt path uses on Linux. The original list held only the two
Homebrew/`/usr/local` locations, which is correct on macOS and misses Linux.

A machine that already has a real `herdr-worktree-open.js` is handled by the
existing stow loop: the file is backed up to `~/.dotfiles-backup/<timestamp>/`
and replaced by the link
([ADR-0014](0014-stow-dotfiles-without-folding.md), convention 3).

## Consequences

### Positive

- opencode-created worktrees show up in herdr's sidebar on every machine, not
  just the one the plugin was written on.
- A link means no drift: what the repo holds is what opencode loads, and a fix
  to the reconciliation reaches every machine on the next `./install.sh`.

### Negative

- The plugin targets opencode's 2.x plugin API
  ([ADR-0032](0032-track-the-opencode-2.x-line.md)); if that API moves, a link
  propagates the break to every machine at once rather than letting them drift
  independently.
- If the file ever gains a machine-local value, it must move to a copy-once or
  overlay shape the way ADR-0026's config did; a link would otherwise put that
  value in the repo.

### Neutral

- `DOTFILES` gains a second one-file package for opencode, so the list no
  longer maps one-to-one onto a tool; ADR-0030 already accepted that.
- `dotfiles/opencode/` is unchanged and remains a template directory;
  ADR-0026's reasoning about it still applies.
- `~/.config/opencode/plugins/` stays otherwise machine-owned: herdr's own
  integration files there are untouched.

## See Also

- [ADR-0030](0030-stow-the-global-opencode-agents-md.md)
- [ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md)
- [ADR-0032](0032-track-the-opencode-2.x-line.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- [Architecture](../architecture.md)
