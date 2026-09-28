# tui-ide-ADR-0017: LazyGit as the git client, from Brewfile or GitHub releases

**Status:** Accepted
**Date:** 2026-09-27
**Supersedes:** [ADR-0011](0011-lazygit-as-git-client.md)

## Context

[ADR-0011](0011-lazygit-as-git-client.md) chose LazyGit as the git client and
recorded that it installs from `Brewfile`, "also in the apt fallback". That
second claim does not hold. The always-on host runs Ubuntu 24.04 ("noble"),
which has no `lazygit` package in any enabled component — `universe` is on and
`apt-cache search lazygit` returns only the Go library
`golang-github-jesseduffield-lazycore-dev`. Because `install.sh` runs under
`set -euo pipefail` and lists every package in one `apt-get install`, the
unavailable package aborted the whole bootstrap, taking the rest of the
toolchain and the stow step with it.

The apt fallback already has a precedent for tools apt cannot supply: herdr
installs from `herdr.dev` when the binary is absent. LazyGit needs the same
treatment. It is also a single static binary with upstream release tarballs, so
there is nothing an apt package adds.

## Decision

LazyGit remains the git client, launched from Neovim with `<leader>gg` via
`kdheepak/lazygit.nvim`. It is no longer requested from apt. It installs from
`Brewfile` under Homebrew, and on the apt fallback from the upstream GitHub
release tarball into `$HOME/.local/bin` when the binary is missing, resolved to
the latest tag and skipped when already present. `$HOME/.local/bin` is on
`PATH` via the zsh dotfiles, the same location herdr uses.

## Consequences

### Positive

- The apt fallback no longer aborts on a package the distribution does not
  carry, so a stale package list cannot take down the whole bootstrap.
- LazyGit tracks upstream releases, so Linux without Homebrew gets the same
  version Homebrew users get instead of a distribution-pinned one.
- Installation stays idempotent: a present binary is left alone.

### Negative

- The apt path now depends on GitHub release asset names, which have changed
  before (GoReleaser moved these to lowercase `linux_<arch>`); a rename breaks
  the bootstrap until the mapping is updated here.
- The version is resolved at install time rather than pinned, so two machines
  provisioning on different days can differ.

### Neutral

- The release tarball is unverified by signature; `install.sh` already trusts
  `herdr.dev` and the Homebrew formula, so this adds no new trust category.

## See Also

- [ADR-0011](0011-lazygit-as-git-client.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [ADR-0004](0004-herdr-as-multiplexer.md)
- [Architecture](../architecture.md)
