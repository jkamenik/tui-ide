# tui-ide-ADR-0019: Merge Claude Code user settings instead of stowing them

**Status:** Accepted
**Date:** 2026-09-28

## Context

Every other tool here is provisioned by Homebrew and linked by GNU Stow, so
turning on a preference means adding a line to the repo. Claude Code does not
fit that shape.

`~/.claude/settings.json` is the only user-level settings file, and the
`settings.local.json` overlay that would normally hold machine-specific values
is project-scoped — `acme-app/.claude/settings.local.json` — not a sibling of
the user file. A single user-level file therefore holds both the portable
preferences worth sharing (the theme) and the values that must not be tracked:
the `hooks` block that iTerm2's `cc-status` and herdr's
`herdr-agent-state.sh` install, which are absolute `/Users/<name>/...` paths.

Stowing it fails both ways. Linking the tracked file puts those absolute paths
in the repository, which convention 4 forbids. Replacing it drops the hooks,
and they are not reinstalled by anything in this repo — iTerm2 and herdr wrote
them, so they silently stop running.

Settings files are also strict JSON: a `//` comment or a trailing comma is a
syntax error, so the tracked copy cannot carry a note explaining itself.

## Decision

`dotfiles/claude/.claude/settings.defaults.json` is a template, not a stow
package entry, and `install.sh` reconciles it into `~/.claude/settings.json`:

- No user file: copy the template.
- A user file and `jq` available: back the user file up, then deep-merge the
  template into it with tracked keys winning.
- A user file but no `jq`: leave the user file alone and say so.
- The user file is a symlink (a previous stow, or another tool): leave it
  alone and say so.

`jq`'s `*` merges objects key by key, so keys only the local file holds survive
untouched; a tracked value replaces the same key, which is the precedence a
stow link would give. The name is not one Claude Code reads, so the file
cannot be mistaken for live configuration.

## Consequences

### Positive

- The iTerm2 and herdr hooks stay in the user's file across every `install.sh`
  run, and the repo never sees a machine-specific path.
- Changing `theme` in the repo reaches every machine on the next run.
- The merge is idempotent and the previous user file is backed up first, so a
  wrong tracked value is recoverable.

### Negative

- `install.sh` now writes a file instead of linking it, which is the one place
  in the repo that is not pure Stow.
- The precedence is tracked-wins, so a preference a user sets locally and then
  edits in the repo is overwritten on the next run rather than sticking. Stow
  behaves the same way, so this is not a new surprise.
- `jq` becomes a hard dependency of the install. It is already in `Brewfile`
  and the apt fallback.
- There is no local escape hatch the way `.gitconfig.local` provides. A user
  who wants a value this repo does not set can add it freely; one that this
  repo does set is the repo's to change.

### Neutral

- Claude Code reloads settings files on change, so a merge during an active
  session applies without a restart.
- A tracked `hooks` block would replace the local one wholesale, since `jq`
  replaces arrays rather than merging them. The template sets no `hooks`, so
  this only matters if that changes.

## See Also

- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [ADR-0010](0010-manage-iterm2-plist-in-repo.md)
- [Architecture](../architecture.md)
