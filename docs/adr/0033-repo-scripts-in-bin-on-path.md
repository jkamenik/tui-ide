# tui-ide-ADR-0033: Repo helper scripts live in `bin/` and reach `$PATH` through a local overlay

**Status:** Accepted
**Date:** 2026-10-14

## Context

Work helper scripts need a home in this repo, starting with `git-cleanup`, which
syncs a checkout to a branch and deletes local branches whose upstream is gone.

Two placements were available. Stow a package into `~/bin`, the way every other
artifact in this repo is delivered; or keep the scripts in the repo at `bin/`
and put that directory on `$PATH`. `~/bin` is already on `$PATH`
(`dotfiles/zsh/.zshrc` line 2, alongside `~/.local/bin`), so the first needs no
path work at all. It was set aside anyway: `~/bin` is wanted for scripts that
exist on one machine only, and something tracked and shared does not belong
there.

Keeping the scripts in the repo at `bin/` makes them versioned and portable, but
the directory to put on `$PATH` is an absolute path that differs per machine.
Convention 4 forbids tracking machine-specific values, so the stowed `~/.zshrc`,
which is a single tracked file shared by every machine, cannot name it.

## Decision

Keep helper scripts at `bin/` in the repo root. They are tracked and portable,
are not a stow package, and do not claim `~/bin`.

`dotfiles/zsh/.zshrc` sources `~/.zshrc.local` when it exists, as the last step
so a local override can adjust everything above it.

`install.sh` seeds `~/.zshrc.local` with
`export PATH="<repo>/bin:$PATH"`, computed from the repo's real path at install
time. When the file already exists it appends the line only if the repo's `bin`
is not already referenced, and backs the file up first; the file is the user's
and is never overwritten. The machine-specific path therefore lives only in an
untracked file under `$HOME`.

The first script is `git-cleanup`. On `$PATH` it is both a standalone command
and, by Git's subcommand dispatch, `git cleanup [branch]`.

## Consequences

### Positive

- Helper scripts are versioned with history and reach every machine on the next
  `./install.sh`, instead of living on one.
- No machine-specific path is committed: the tracked `.zshrc` stays portable,
  and the overlay is generated with the repo's real location.
- `~/bin` stays free for machine-local scripts.

### Negative

- The environment gains a shell overlay, `~/.zshrc.local`, sourced by the
  tracked `.zshrc`; a machine that already uses that filename has to accept the
  appended line (it is backed up first).
- The scripts are unreachable until `install.sh` runs, or the user adds the
  `$PATH` line by hand; the repo no longer delivers everything through stow.

### Neutral

- `bin/` is not a stow package, so `DOTFILES` in `install.sh` is unchanged.
- The overlay is zsh-specific, which matches the repo's shell; a machine whose
  login shell is not zsh does not pick it up.

## See Also

- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- [ADR-0030](0030-stow-the-global-opencode-agents-md.md)
- [Architecture](../architecture.md)
- [Git Tips and Tricks — Cleanup to a given branch](https://kameniksolutions.com/resources/git-tips-and-tricks/#cleanup-to-a-given-branch)
