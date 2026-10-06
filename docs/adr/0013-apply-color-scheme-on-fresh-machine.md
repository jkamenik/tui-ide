# tui-ide-ADR-0013: Apply the tracked color scheme on a fresh machine

**Status:** Accepted
**Date:** 2026-09-22
**Partially superseded:** the opencode TUI config clause, by
[ADR-0023](0023-seed-the-opencode-tui-config.md). The iTerm2 and herdr clauses
stand.

## Context

[ADR-0010](0010-manage-iterm2-plist-in-repo.md) kept the iTerm2 plist in the
repo but left enabling the custom preferences folder as a manual GUI step, and
no herdr config was tracked. On a fresh machine iTerm2 ran with default colors:
the tracked "Warm Burnout Dark" preset never appeared in the Color Presets
list, and herdr fell back to its default `catppuccin` theme instead of
following the terminal.

## Decision

`install.sh` will point iTerm2 at the tracked preferences folder on macOS with
`defaults write`, only when the custom folder is not already enabled and iTerm2
is not running (a running instance overwrites the keys on quit). The plist
stays at `dotfiles/iterm2/.config/iterm2/AppSupport/` and is still not stowed.
herdr will track `dotfiles/herdr/.config/herdr/config.toml` with
`theme.name = "terminal"`, so it renders from the terminal's palette.
opencode instead names its own tracked theme, `"theme": "warm-burnout"`
(ADR-0026): `system` derives its grayscale from a terminal background and uses
ANSI 0-15, so it works in a TUI and silently degrades under `opencode serve`,
where the always-on host has no terminal to derive from. Naming the theme makes
both contexts render Warm Burnout. The cost is that the iTerm2 preset is no
longer the single source of color truth: opencode's palette now comes from
`themes/warm-burnout.json` and has to be kept in step by hand with the iTerm2
preset and the nvim colorscheme.
opencode's TUI config is machine-local
(`~/.config/opencode/tui.jsonc`, which also holds the herdr session plugin), so
the repo tracks a `.example` and `install.sh` documents the setup rather than
stowing it.

## Consequences

### Positive

- `./install.sh` plus an iTerm2 restart applies the tracked colors; no GUI step.
- herdr and opencode match the terminal palette on macOS, Linux, and iOS
  clients without a second theme to maintain.

### Negative

- The `defaults write` must run with iTerm2 quit, so `install.sh` prints a
  reminder instead of applying while it runs.
- herdr and opencode give up their built-in themes unless someone edits the
  tracked configs.

### Neutral

- Replaces the one-time GUI toggle left by ADR-0010. The plist location and
  sync model are unchanged.

## See Also

- [Architecture](../architecture.md)
- [ADR-0004](0004-herdr-as-multiplexer.md)
- [ADR-0010](0010-manage-iterm2-plist-in-repo.md)
