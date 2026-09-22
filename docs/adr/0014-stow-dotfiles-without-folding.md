# tui-ide-ADR-0014: Stow dotfiles without folding

**Status:** Accepted
**Date:** 2026-09-22

## Context

For a package whose files all live under one directory (nvim, herdr), GNU Stow
defaults to folding: it links the whole directory as a single symlink. The
apps then write inside their config directory, so their writes land in the
repo working tree. nvim's `lazy-lock.json` and herdr's `session.json` and
`config.toml` were rewritten in place, and tracked nvim config files were
deleted outright, in the repository — the same "app rewrites config into the
tracked tree" failure [ADR-0010](0010-manage-iterm2-plist-in-repo.md) already
documented for iTerm2.

## Decision

`install.sh` will run `stow --no-folding`. Each tracked file gets its own
symlink, so an app's atomic in-place write replaces the `$HOME` symlink and
leaves the repository file untouched. herdr runtime state (`session.json`,
`.plugins.lock`, `*.sock`, `*.log`) is git-ignored because herdr rewrites it
on every run.

## Consequences

### Positive

- Live config writes land in `$HOME`, never in the repo tree.
- A broken link is local and reparable with `./install.sh`; tracked files stay
  authoritative.

### Negative

- `$HOME/.config/<pkg>` becomes a directory of symlinks instead of one link,
  which is easy to confuse with a real config directory.

### Neutral

- `--no-folding` is safe and supported by Stow; a Nvim or herdr restart after
  `./install.sh` is enough if a fold already exists.

## See Also

- [Architecture](../architecture.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [ADR-0010](0010-manage-iterm2-plist-in-repo.md)
- [ADR-0013](0013-apply-color-scheme-on-fresh-machine.md)