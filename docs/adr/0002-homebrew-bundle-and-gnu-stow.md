# tui-ide-ADR-0002: Homebrew Bundle plus GNU Stow for provisioning

**Status:** Accepted
**Date:** 2026-09-16

## Context

The environment must come up the same way on macOS and Linux. Candidate mechanisms: a shell installer with per-OS branches, Ansible, chezmoi, Nix, or Homebrew Bundle with GNU Stow. Ansible already exists in `automations`, but it targets a host, not a laptop. Nix is powerful but heavy for a two-platform dotfiles set.

## Decision

We will use Homebrew Bundle for packages and GNU Stow for dotfiles. One shared `Brewfile` covers macOS and Linuxbrew. macOS-only casks live in `Brewfile.macos`. `install.sh` detects the OS, runs `brew bundle`, backs up conflicts, and stows packages. Linux without Homebrew falls back to apt for core packages.

## Consequences

### Positive

- Homebrew runs on both target platforms, so one package list serves both.
- Stow is simple and reversible: removing a symlink uninstalls the dotfile.
- Adding a package is adding a directory under `dotfiles/`.
- Cask isolation keeps the shared Brewfile Linux-safe.

### Negative

- Linuxbrew on Linux adds a Homebrew install step before anything else.
- Stow's tree-folding can symlink a whole directory, which surprises anyone expecting per-file links.
- apt fallback duplicates a small part of the package list.

### Neutral

- Ansible could still provision the host from `automations`; this repo stays client-only.

## See Also

- [Architecture](../architecture.md)
- [ADR-0001](0001-separate-tui-ide-repo.md)
