# tui-ide-ADR-0044: Seed a Warm Burnout custom theme for Claude Code

**Status:** Accepted
**Date:** 2026-11-13

## Context

The terminal, herdr, nvim, and opencode all render the Warm Burnout palette.
Claude Code's settings template selected `"theme": "auto"`, which picks
Claude Code's own dark or light palette, so it was the one surface that did
not match. Its ANSI themes (`dark-ansi`) draw from the terminal's 16 colours
and so inherit the iTerm2 preset, but they lose the shaded backgrounds (diffs,
user messages, selection) and read noticeably flatter than the real palette.

Claude Code loads custom themes from `~/.claude/themes/<slug>.json`: a `name`,
a `base` (`dark` or `light`), and `overrides` keyed by its theme tokens, with
unknown tokens silently dropped. A setting of `"custom:<slug>"` selects one.
The `/theme` editor saves changes by atomically replacing that file.

## Decision

1. Track `dotfiles/claude/.claude/themes/warm-burnout-dark.json`, with colours
   taken from the opencode `themes/warm-burnout.json` defs (and the iTerm2
   preset's ANSI cyan for plan mode and background tasks).
2. `install.sh` seeds it copy-once into `~/.claude/themes/`, and prints a
   `diff -u` hint when the file already exists — the same contract as the
   opencode theme. It is not stowed, because a `/theme` save would replace the
   link with a real file.
3. The settings template sets `"theme": "custom:warm-burnout-dark"`, which the
   [ADR-0019](0019-merge-claude-user-settings.md) merge applies to every
   machine.

## Consequences

### Positive

- Claude Code matches the rest of the stack.

### Negative

- A custom theme has a fixed base, so Claude Code no longer follows the
  system light/dark switch the way `auto` did. Only the dark variant is
  tracked.
- Copy-once means a tracked palette change does not reach machines that
  already have the file; the install output names the diff to merge by hand.
- The palette is now kept in step by hand in a third place, beside the iTerm2
  preset and the opencode theme.

### Neutral

- Re-running `install.sh` resets a locally chosen `/theme` back to Warm
  Burnout, as with any tracked key in the template.

## See Also

- [ADR-0019](0019-merge-claude-user-settings.md) — merged Claude Code settings
- [ADR-0026](0026-seed-the-client-config-the-installed-version-reads.md) —
  the copy-once seeding contract
