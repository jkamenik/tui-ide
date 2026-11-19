# tui-ide-ADR-0046: Add claudecode.nvim as the Claude Code IDE bridge

**Status:** Accepted
**Date:** 2026-11-19

## Context

Claude Code has an IDE integration (the VS Code extension's protocol): the IDE
serves a local WebSocket and a lock file under `~/.claude/ide/`, and `claude`
connects to it, learning the current selection and open files and showing its
diffs in the editor. Neovim had no part in this, so Claude Code in a pane
could not see what the editor was looking at.

[coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) implements
that protocol in Lua. It can also embed a terminal running `claude` in a
split, so the agent sits beside the buffer it is editing.

## Decision

1. Add `claudecode.nvim` as a lazy.nvim plugin
   (`dotfiles/nvim/.config/nvim/lua/plugins/claudecode.lua`) with
   `terminal.provider = "native"` (built-in terminal, no extra dependency) and
   a right-hand split at 35% width. The protocol server starts with Neovim;
   the split opens only on demand, not at startup, so quick `$EDITOR` edits do
   not spawn a session. A `claude` started in another pane from the same
   project still connects, via `/ide`.
2. Bind a `<leader>a` group: `ac` toggles the Claude pane, `af` focuses it,
   `as` (visual) sends the selection, `ab` adds the
   current buffer, `aa` / `ad` accept or deny a proposed diff. Register the
   group in which-key.

## Consequences

### Positive

- Claude Code sees the editor's selection and opens diffs in Neovim, and can
  be opened beside the buffer with `<leader>ac`.

### Negative

- One more plugin to keep updated; `lazy-lock.json` pins it after the first
  sync.

- A `claude` started from inside Neovim is the plain binary, not the macOS
  `caffeinate` wrapper of
  [ADR-0043](0043-ensure-herdr-integration-and-caffeinate-claude.md), so the
  Mac can sleep during a long run.

### Neutral

- Works on macOS and Linux; no machine-specific values.

## See Also

- [ADR-0018](0018-neovim-as-editor-variable.md) — Neovim as `$EDITOR`
- [ADR-0043](0043-ensure-herdr-integration-and-caffeinate-claude.md) — Claude
  Code in Herdr
