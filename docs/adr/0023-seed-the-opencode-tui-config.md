# tui-ide-ADR-0023: Seed the opencode TUI config from a tracked example

**Status:** Accepted
**Date:** 2026-09-28
**Supersedes:** the opencode clause of
[ADR-0013](0013-apply-color-scheme-on-fresh-machine.md) (the rest of ADR-0013
remains in force)

## Context

ADR-0013 tracked `dotfiles/opencode/.config/opencode/tui.jsonc.example` and
left the real file to a manual `cp`, printed by `install.sh` and documented in
the README. The config is machine-local — it holds the herdr session plugin
path — so it cannot be tracked or linked, which is why the example exists at
all. But the manual step is the only setup left in the repo that is not
automatic, and it is the kind that gets skipped: without `tui.jsonc` opencode
falls back to its own theme, so nothing breaks and the mismatch with the
tracked iTerm2 palette goes unnoticed.

`~/.config/opencode` cannot be a stow package directory either. opencode
writes its own state there — `node_modules/`, `package.json`,
`package-lock.json`, `themes/`, `plugins/`, `skills/`, `opencode.jsonc` — and
folding would make the directory a link into the repo for tools that write
there. Per-file linking avoids the fold but puts the machine-specific plugin
path in a tracked file, which convention 4 forbids. Keeping the live file in
the repo as a git-ignored file that a symlink points at is worse: `git clean
-xdf` deletes it and leaves a dangling link, an editor that writes atomically
replaces the link and silently strands the repo copy, and a fresh clone never
has the file at all, so the copy step it replaces still has to exist.

Unlike `~/.claude/settings.json` (ADR-0019), this file cannot be reconciled
repeatedly. It is JSONC, and the comment lines that let the example document
itself are a parse error for `jq`, so there is no safe merge. And there is no
overlay sibling to split machine values into: `tui.jsonc` is the only TUI
settings file, and it is user-scoped with no `.local` variant.

## Decision

`install.sh` copies `dotfiles/opencode/.config/opencode/tui.jsonc.example` to
`~/.config/opencode/tui.jsonc` when the destination does not exist, and says
where to edit it. The copy is one-shot by construction: a file that is already
there is left alone, so a local theme choice or plugin survives every
re-run, and a file the user has since deleted is re-seeded. A `tui.jsonc` that
is a symlink is left alone and reported, the same guard ADR-0019 uses for
`~/.claude/settings.json`. The example keeps its `.example` suffix so it is
never read as live configuration, and `dotfiles/opencode/` stays a template
directory rather than a stow package.

## Consequences

### Positive

- A fresh machine gets the tracked `"theme": "system"` with no manual step, so
  opencode matches the terminal palette like herdr does.
- The repo never holds a machine-specific path, and nothing machine-local
  lives inside the repo tree where `git clean` or an editor can reach it.
- Idempotent and safe: nothing overwrites a file, so no backup is needed and
  there is no precedence to explain.

### Negative

- Changes to the example do not reach machines that already have a
  `tui.jsonc`. The same drift the `.gitconfig.local` overlay has, accepted in
  ADR-0008; a new machine is the only place a new default lands.
- A user who deletes `tui.jsonc` to go back to opencode's built-in theme gets
  it back on the next `install.sh` run.
- `install.sh` now writes two files instead of linking them.

### Neutral

- Replaces the last manual setup step in the README apart from the opt-in
  nvim vault overlay, which stays manual because the vault lives in a repo
  this one does not own.
- The example's trailing comment points at the herdr session plugin. That
  plugin is not tracked here, so the comment documents an opt-in rather than a
  step the repo performs.

## See Also

- [ADR-0013](0013-apply-color-scheme-on-fresh-machine.md)
- [ADR-0019](0019-merge-claude-user-settings.md)
- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- [Architecture](../architecture.md)
