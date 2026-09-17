# tui-ide-ADR-0010: Manage the iTerm2 plist in the repo directory

**Status:** Accepted
**Date:** 2026-09-16

## Context

[ADR-0009](0009-track-iterm2-preferences.md) kept a committed snapshot of
`com.googlecode.iterm2.plist` and seeded a copy into the custom preferences
folder. That leaves two copies and a manual sync. iTerm2 rewrites its plist
atomically, so a stow symlink is replaced on the first GUI change. The custom
preferences folder supports any directory, including a git working tree.

## Decision

We will keep `com.googlecode.iterm2.plist` directly in the repo at
`dotfiles/iterm2/.config/iterm2/AppSupport/` and point iTerm2's custom
preferences folder at that directory. iTerm2 writes the tracked file in place,
so there is a single source of truth and no symlink or copy step. The package is
not stowed; `install.sh` does not touch iTerm2.

## Consequences

### Positive

- One source of truth; GUI changes appear as a working-tree diff.
- No symlink to break and no copy-back sync.
- A fresh machine clones the repo and points iTerm2 at it.

### Negative

- The custom folder is an absolute path, so it assumes the documented clone
  location (`~/github.com/jkamenik/tui-ide`).
- The tracked file is a plist; diffs are coarse compared with plain text.

### Neutral

- Enabling the custom folder is a one-time step, like the other manual macOS
  setup. It can be scripted with `defaults write`.

## See Also

- [Architecture](../architecture.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [ADR-0003](0003-terminal-clients-iterm2-and-moshi.md)
- [ADR-0009](0009-track-iterm2-preferences.md)
