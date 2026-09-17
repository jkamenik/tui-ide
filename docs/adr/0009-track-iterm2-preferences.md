# tui-ide-ADR-0009: Track iTerm2 preferences from a synced plist

**Status:** Accepted
**Date:** 2026-09-16

## Context

iTerm2 settings (font, colors, key bindings, profiles) live in a binary
property list at `~/Library/Preferences/com.googlecode.iterm2.plist`. They are
machine-local and lost on a fresh machine. Stow is not a fit: iTerm2 rewrites
the plist atomically (temp file plus rename), which replaces a stow symlink and
leaves the tracked source stale. Options: a stow package, a committed snapshot
seeded by `install.sh`, or a Dynamic Profile fragment.

## Decision

We will keep a snapshot of `com.googlecode.iterm2.plist` in the repo at
`iterm2/`. The user enables iTerm2's "Load preferences from a custom folder"
pointing at `~/.config/iterm2/AppSupport`. `install.sh` seeds that folder from
the snapshot on macOS only when the plist is absent. After GUI changes, the user
copies the plist back into the repo to sync.

## Consequences

### Positive

- iTerm2 settings travel with the repo and survive a fresh machine.
- Seeding only when absent never clobbers live preferences.
- Avoids the symlink-vs-atomic-write failure of a stow package.

### Negative

- Syncing GUI changes back into the repo is a manual step.
- The tracked file is a binary plist; diffs are not human-readable.

### Neutral

- The custom-folder toggle is a one-time GUI step, like the other manual macOS
  setup.

## See Also

- [Architecture](../architecture.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [ADR-0003](0003-terminal-clients-iterm2-and-moshi.md)
