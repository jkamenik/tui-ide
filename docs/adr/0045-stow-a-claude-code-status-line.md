# tui-ide-ADR-0045: Stow a Claude Code status line for model, context, and usage limits

**Status:** Accepted
**Date:** 2026-11-13

## Context

opencode and the claude.ai web app both show the active model, how full the
context window is, and how much of the plan's usage limits are spent. Claude
Code shows none of this by default, so a long session can hit auto-compaction
or a usage limit without warning.

Claude Code runs a `statusLine` command after each turn and pipes the session
state to it as JSON: `model.display_name`, `effort.level`,
`context_window.used_percentage` / `total_input_tokens` /
`context_window_size`, and, for subscription logins once the API reports them,
`rate_limits.five_hour` and `rate_limits.seven_day` (each `used_percentage`
and `resets_at`). Whatever the command prints becomes the status line.

## Decision

1. Track `dotfiles/claude-statusline/.claude/statusline.sh`, a bash + `jq`
   script that prints
   `Opus 5.5 · high │ ctx 42% 84k/200k │ 5h 23% ↻3:10pm · 7d 61% ↻Tue`, coloured
   in the Warm Burnout palette
   ([ADR-0044](0044-seed-a-warm-burnout-claude-code-theme.md)), with
   percentages shaded green under 50%, amber under 80%, and rose above. Any
   field the JSON lacks drops its segment.
2. Stow it as its own package. Claude Code only reads the script and nothing
   in it is machine-specific, so a link keeps every machine on the tracked
   version — unlike `settings.json` and the theme, which Claude Code rewrites.
3. The settings template points `statusLine` at `~/.claude/statusline.sh`,
   which the [ADR-0019](0019-merge-claude-user-settings.md) merge applies to
   every machine.

## Consequences

### Positive

- Model, context use, and usage limits are visible in every Claude Code
  session, matching opencode and claude.ai.

### Negative

- Usage limits appear only for claude.ai subscription logins, and only after
  the first reply of a session; API-key and gateway logins show model and
  context only.
- The palette is hard-coded in the script, a fourth place to keep in step by
  hand.

### Neutral

- Re-running `install.sh` restores the tracked `statusLine`, replacing any
  local one, as with any tracked key in the template.
- Reset times use BSD `date -r` on macOS and fall back to GNU `date -d @` on
  Linux.

## See Also

- [ADR-0019](0019-merge-claude-user-settings.md) — merged Claude Code settings
- [ADR-0044](0044-seed-a-warm-burnout-claude-code-theme.md) — the Warm Burnout
  Claude Code theme
