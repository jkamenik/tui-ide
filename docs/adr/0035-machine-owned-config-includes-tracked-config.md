# tui-ide-ADR-0035: Device-local config files are machine-owned and include a tracked config

**Status:** Accepted
**Date:** 2026-10-15

## Context

A tool's config file that the tool, an installer, or an endpoint agent rewrites
in place cannot be delivered as a stow symlink: the rewrite follows the link into
the repository and dirties the tracked file with host-specific values. This has
happened twice now — `~/.zprofile` (dropped from the package), then `~/.zshrc`
(ADR-0034) — and Aikido endpoint protection also writes an `[http] sslCAInfo`
line into `~/.gitconfig`.

ADR-0034 solved `~/.zshrc` by inverting the link: the machine owns the file at
the tool's expected path, and the tracked config is a separate file the machine
file `source`s. Git offers the same shape with `[include]`. The pattern is worth
stating once and applying to every file this class of tool touches.

## Decision

For a device-local config file that a tool rewrites in place, **invert the link
when the tool can include or source another file**: the machine owns the file at
the tool's expected path, and the repository tracks a separate config that the
machine file includes or sources.

`install.sh` maintains the machine file the same way for each case:

- seed it when it is missing;
- migrate a stale stow link (or any link) by moving it to the backup directory
  and replacing it;
- append the include/source line to an existing real file only when it is
  absent, backing the file up first.

An existing machine file is never overwritten.

Apply it to git now, as the second instance of the ADR-0034 pattern:

- the tracked config moves to `dotfiles/git/.config/git/tui-ide.gitconfig`,
  stowed to `~/.config/git/tui-ide.gitconfig`;
- the machine-owned `~/.gitconfig` includes that file, and the tracked file
  keeps including `~/.gitconfig.local` for identity and signing;
- `install.sh` seeds or migrates `~/.gitconfig` exactly as it does `~/.zshrc`.

When a tool has no include/source mechanism, do not symlink a file it rewrites.
Fall back to the established alternatives: the copy-once tracked template
(ADR-0023, ADR-0026) or the merge-from-template contract (ADR-0019).

## Consequences

### Positive

- One rule covers the recurring case, so the next in-place rewriter (endpoint
  agent, installer) does not require a fresh design or a fresh incident.
- Machine-local values that these tools write live in an untracked file by
  construction, so they cannot reach a commit (convention 4).

### Negative

- Each inverted file adds a layer of indirection: the tool's real file is a
  short include/source stub, one more place to look when debugging config.
- The migration touches a live, machine-owned file; it is guarded to back up
  first and to never overwrite, but it is a one-time edit of the user's file.

### Neutral

- Only files a tool rewrites in place are affected. Stow remains the delivery
  mechanism for everything else, and the tracked config is still stowed, just at
  a path the machine file points to.
- Whether a given tool qualifies is a judgment call ("if possible"); the
  fallbacks above cover the rest.

## See Also

- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- [ADR-0019](0019-merge-claude-user-settings.md)
- [ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md)
- [ADR-0034](0034-machine-owned-zshrc-sources-tracked-config.md)
- [Architecture](../architecture.md)
