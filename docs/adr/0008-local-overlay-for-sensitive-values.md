# tui-ide-ADR-0008: Overlay files for machine-specific values

**Status:** Accepted
**Date:** 2026-09-16

## Context

Dotfiles are shared, but some values are machine-specific or sensitive: git identity, signing key, the 1Password SSH agent path, and local paths. Committing them leaks secrets and creates conflicts between machines. Options: template rendering, host-specific branches, environment variables, or git-ignored overlay files.

## Decision

We will keep shared config in git and put machine-specific values in git-ignored overlay files. The shared config includes the overlay. `dotfiles/git/.gitconfig` includes `~/.gitconfig.local`, and `.gitconfig.local.example` documents the fields.

## Consequences

### Positive

- No secrets or machine-specific paths in git.
- One shared config works on every machine.
- The overlay pattern extends to any future dotfile.

### Negative

- Each new machine needs a one-time copy of the example to the real overlay.
- A missing overlay can silently drop identity or signing.

### Neutral

- Template rendering remains an option if the number of overlays grows.

## See Also

- [Architecture](../architecture.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
