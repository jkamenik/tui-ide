# tui-ide-ADR-0034: Let the machine own `~/.zshrc` and source a tracked shell config

**Status:** Accepted
**Date:** 2026-10-15

## Context

`dotfiles/zsh/.zshrc` was stowed as a symlink at `~/.zshrc`, so the tracked file
*was* the live rc. Many installers rewrite `~/.zshrc` in place — brew, goenv,
pyenv, nvm, gcloud, OrbStack, the Censys onboarding script, and (newly) Aikido
endpoint protection. Writing through the stow symlink, each of them lands in the
tracked file, so a machine-local tool dirties the working tree and tempts a
commit of host-specific values (convention 4).

The `.zprofile` case was solved by dropping it from the package entirely, because
nothing in the repo referenced it. `.zshrc` cannot be dropped: it carries the
shared config (oh-my-zsh, `EDITOR`/`VISUAL`, `vi`, bun, nvm, `~/bin` on
`$PATH`), and `~/.zshrc.local` is sourced from it (ADR-0033).

## Decision

Reverse the direction of the link. `~/.zshrc` is machine-owned; the tracked file
is something the machine sources.

- The shared config moves to `dotfiles/zsh/.config/zsh/tui-ide.zsh`, stowed to
  `~/.config/zsh/tui-ide.zsh`. It keeps sourcing `~/.zshrc.local` last
  (ADR-0033).
- `install.sh` makes `~/.zshrc` a short machine-owned file that sources
  `~/.config/zsh/tui-ide.zsh`. A fresh machine gets it seeded; a stale stow link
  (the one this change leaves behind) is moved to the backup directory and
  replaced; a real file gains the source line only when it is absent, and is
  backed up first. An existing `~/.zshrc` is never overwritten.

## Consequences

### Positive

- A tool that rewrites `~/.zshrc` in place — Aikido rewriting its cert block, an
  installer appending to `~/.zshrc` — touches an untracked file, so the working
  tree stays clean and machine-specific values cannot reach a commit.
- The shared config is still tracked and reaches every machine on the next
  `./install.sh`, through stow as before.

### Negative

- `~/.zshrc` is no longer a link to a readable file; a reader there sees a
  six-line indirection. The one-time migration backs the old link up, so nothing
  is lost.
- The shared config loads through two hops (`~/.zshrc` → the stowed
  `~/.config/zsh/tui-ide.zsh`), which is one more place to look when debugging
  shell startup.

### Neutral

- `dotfiles/zsh` stays a stow package, so `DOTFILES` in `install.sh` is
  unchanged; only the path inside it the package maps to changes.
- The tracked file's `dotfiles/zsh/.zshrc` path in older ADRs (0018, 0033) is
  historical; this record is the current location.

## See Also

- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- [ADR-0033](0033-repo-scripts-in-bin-on-path.md)
- [Architecture](../architecture.md)
