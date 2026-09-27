# tui-ide-ADR-0016: Never back up files that resolve into the repo

**Status:** Accepted
**Date:** 2026-09-27

## Context

`install.sh` backs up any real file in `$HOME` that stow would refuse to
replace, then stows over it. The guard was `-e && ! -L`, which tests only the
final path component.

[ADR-0014](0014-stow-dotfiles-without-folding.md) made `install.sh` stow with
`--no-folding`, but a fold created before that change survived: `~/.config/nvim`
was still a single symlink to `dotfiles/nvim/.config/nvim`. For such a target,
`~/.config/nvim/init.lua` resolves through the *parent* symlink to the tracked
file itself. `-L` reports false, the guard passes, and `mv` moves the
repository's own file into the backup directory.

The result was that a single `./install.sh` run deleted all eleven tracked nvim
config files from the working tree. nvim's plugin directory was untouched, but
with no config lazy.nvim loaded no plugin specs, so every plugin appeared to be
gone.

## Decision

The backup step will resolve each target with `realpath` and skip anything that
lands inside the repository. `REPO_DIR` is resolved with `pwd -P` so the
comparison is physical on both sides; this matters on macOS, where `/var` is a
symlink to `/private/var` and a logical path would never match `realpath`
output. The symlink test is kept as a second condition.

## Consequences

### Positive

- `./install.sh` can no longer delete tracked files, whatever `$HOME` contains.
- A genuine pre-existing local file is still backed up and relinked, so the
  original purpose of the step is unchanged.
- An existing fold degrades safely: stow reports the conflict and aborts
  instead of destroying the source of truth.

### Negative

- The guard is only as good as `realpath`; a target that reaches the repo by a
  path `realpath` cannot resolve is still not detected.

### Neutral

- Removing a leftover fold is still a manual one-time step. `install.sh`
  reports the stow conflict rather than repairing it.
- A fold predating ADR-0014 is the trigger, so the fix matters most for
  long-lived checkouts.

## See Also

- [Architecture](../architecture.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
